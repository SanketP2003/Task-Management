from __future__ import annotations

import asyncio

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user, get_db
from app.crud import category as category_crud
from app.crud import subtask as subtask_crud
from app.crud import task as task_crud
from app.models.task import TaskStatus
from app.models.user import User
from app.schemas.subtask import SubtaskCreate, SubtaskUpdate
from app.schemas.task import TaskCreate, TaskResponse, TaskUpdate

router = APIRouter(prefix="/tasks", tags=["Tasks"])


def _validate_blocked_by(
    db: Session,
    user_id: int,
    task_id: int | None,
    blocked_by: int | None,
) -> None:
    if blocked_by is None:
        return

    if task_id is not None and blocked_by == task_id:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="blocked_by cannot reference the same task",
        )

    blocked_task = task_crud.get_task(db, blocked_by, user_id)
    if blocked_task is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="blocked_by task does not exist",
        )

    if task_id is not None:
        visited: set[int] = set()
        current_id: int | None = blocked_by

        while current_id is not None and current_id not in visited:
            if current_id == task_id:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail="blocked_by creates a circular dependency",
                )

            visited.add(current_id)
            current_task = task_crud.get_task(db, current_id, user_id)
            if current_task is None:
                break
            current_id = current_task.blocked_by


@router.post("", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
async def create_task(
    task_in: TaskCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TaskResponse:
    await asyncio.sleep(2)

    if task_in.category_id is not None:
        category = category_crud.get_category(db, category_id=task_in.category_id, user_id=current_user.id)
        if category is None:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="category_id does not exist",
            )

    _validate_blocked_by(db, current_user.id, task_id=None, blocked_by=task_in.blocked_by)

    created = task_crud.create_task(db, task_in.model_dump() | {"user_id": current_user.id})
    if created is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Duplicate task detected",
        )

    return created


@router.get("", response_model=list[TaskResponse])
async def list_tasks(
    status_filter: TaskStatus | None = Query(default=None, alias="status"),
    search: str | None = Query(default=None, min_length=1),
    category_id: int | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[TaskResponse]:
    filters: dict[str, object] = {}
    if status_filter is not None:
        filters["status"] = status_filter
    if search:
        filters["search"] = search
    if category_id is not None:
        filters["category_id"] = category_id

    return task_crud.get_tasks(db, user_id=current_user.id, filters=filters)


@router.get("/{task_id}", response_model=TaskResponse)
async def get_task(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TaskResponse:
    task = task_crud.get_task(db, task_id, current_user.id)
    if task is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")
    return task


@router.put("/{task_id}", response_model=TaskResponse)
async def update_task(
    task_id: int,
    task_in: TaskUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TaskResponse:
    existing_task = task_crud.get_task(db, task_id, current_user.id)
    if existing_task is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")

    await asyncio.sleep(2)

    incoming_data = task_in.model_dump(exclude_unset=True)
    if "category_id" in incoming_data and incoming_data["category_id"] is not None:
        category = category_crud.get_category(
            db,
            category_id=incoming_data["category_id"],
            user_id=current_user.id,
        )
        if category is None:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="category_id does not exist",
            )
    if "blocked_by" in incoming_data:
        _validate_blocked_by(
            db,
            current_user.id,
            task_id=task_id,
            blocked_by=incoming_data["blocked_by"],
        )

    updated = task_crud.update_task(db, task_id, current_user.id, incoming_data)
    if updated is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")
    return updated


@router.delete(
    "/{task_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
)
async def delete_task(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Response:
    try:
        deleted = task_crud.delete_task(db, task_id, current_user.id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Cannot delete task: other tasks depend on it",
        ) from None

    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")

    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/{task_id}/subtasks", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
async def create_subtask(
    task_id: int,
    subtask_in: SubtaskCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TaskResponse:
    task = task_crud.get_task(db, task_id, current_user.id)
    if task is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")

    if not subtask_in.title.strip():
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Subtask title cannot be empty",
        )

    subtask_crud.create_subtask(db, task_id=task_id, title=subtask_in.title)
    updated_task = task_crud.get_task(db, task_id, current_user.id)
    if updated_task is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")
    return updated_task


@router.put("/{task_id}/subtasks/{subtask_id}", response_model=TaskResponse)
async def update_subtask(
    task_id: int,
    subtask_id: int,
    subtask_in: SubtaskUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TaskResponse:
    task = task_crud.get_task(db, task_id, current_user.id)
    if task is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")

    payload = subtask_in.model_dump(exclude_unset=True)
    if "title" in payload and not payload["title"].strip():
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Subtask title cannot be empty",
        )

    updated = subtask_crud.update_subtask(
        db,
        subtask_id=subtask_id,
        task_id=task_id,
        data=payload,
    )
    if updated is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subtask not found")

    updated_task = task_crud.get_task(db, task_id, current_user.id)
    if updated_task is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")
    return updated_task


@router.delete("/{task_id}/subtasks/{subtask_id}", response_model=TaskResponse)
async def delete_subtask(
    task_id: int,
    subtask_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TaskResponse:
    task = task_crud.get_task(db, task_id, current_user.id)
    if task is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")

    deleted = subtask_crud.delete_subtask(db, subtask_id=subtask_id, task_id=task_id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subtask not found")

    updated_task = task_crud.get_task(db, task_id, current_user.id)
    if updated_task is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")
    return updated_task