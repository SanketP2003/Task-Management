from __future__ import annotations

import asyncio

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_db
from app.crud import task as task_crud
from app.models.task import TaskStatus
from app.schemas.task import TaskCreate, TaskResponse, TaskUpdate

router = APIRouter(prefix="/tasks", tags=["Tasks"])


def _validate_blocked_by(db: Session, task_id: int | None, blocked_by: int | None) -> None:
    if blocked_by is None:
        return

    if task_id is not None and blocked_by == task_id:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="blocked_by cannot reference the same task",
        )

    blocked_task = task_crud.get_task(db, blocked_by)
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
            current_task = task_crud.get_task(db, current_id)
            if current_task is None:
                break
            current_id = current_task.blocked_by


@router.post("", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
async def create_task(task_in: TaskCreate, db: Session = Depends(get_db)) -> TaskResponse:
    await asyncio.sleep(2)

    _validate_blocked_by(db, task_id=None, blocked_by=task_in.blocked_by)

    created = task_crud.create_task(db, task_in)
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
    db: Session = Depends(get_db),
) -> list[TaskResponse]:
    filters: dict[str, object] = {}
    if status_filter is not None:
        filters["status"] = status_filter
    if search:
        filters["search"] = search

    return task_crud.get_tasks(db, filters=filters)


@router.get("/{task_id}", response_model=TaskResponse)
async def get_task(task_id: int, db: Session = Depends(get_db)) -> TaskResponse:
    task = task_crud.get_task(db, task_id)
    if task is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")
    return task


@router.put("/{task_id}", response_model=TaskResponse)
async def update_task(task_id: int, task_in: TaskUpdate, db: Session = Depends(get_db)) -> TaskResponse:
    existing_task = task_crud.get_task(db, task_id)
    if existing_task is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")

    await asyncio.sleep(2)

    incoming_data = task_in.model_dump(exclude_unset=True)
    if "blocked_by" in incoming_data:
        _validate_blocked_by(db, task_id=task_id, blocked_by=incoming_data["blocked_by"])

    updated = task_crud.update_task(db, task_id, incoming_data)
    if updated is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")
    return updated


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_task(task_id: int, db: Session = Depends(get_db)) -> None:
    try:
        deleted = task_crud.delete_task(db, task_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Cannot delete task: other tasks depend on it",
        ) from None

    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")