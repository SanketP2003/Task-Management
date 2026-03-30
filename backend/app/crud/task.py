from __future__ import annotations

from collections.abc import Mapping
from typing import Any

from sqlalchemy import func
from sqlalchemy.orm import Session, selectinload

from app.models.task import Task, TaskStatus


def _to_payload(data: Any) -> dict[str, Any]:
    if hasattr(data, "model_dump"):
        return data.model_dump(exclude_unset=True)
    if isinstance(data, Mapping):
        return dict(data)
    raise TypeError("Unsupported payload type")


def create_task(db: Session, task_data: Any) -> Task | None:
    payload = _to_payload(task_data)

    duplicate = (
        db.query(Task)
        .filter(
            Task.user_id == payload["user_id"],
            func.lower(Task.title) == payload["title"].strip().lower(),
            Task.description == payload["description"],
            Task.due_date == payload["due_date"],
        )
        .first()
    )
    if duplicate:
        return None

    task = Task(**payload)
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


def get_tasks(db: Session, user_id: int, filters: Mapping[str, Any] | None = None) -> list[Task]:
    query = (
        db.query(Task)
        .options(selectinload(Task.subtasks), selectinload(Task.category))
        .filter(Task.user_id == user_id)
    )

    if filters:
        status = filters.get("status")
        if status is not None:
            if isinstance(status, str):
                status = TaskStatus(status)
            query = query.filter(Task.status == status)

        search = filters.get("search")
        if search:
            query = query.filter(Task.title.ilike(f"%{search}%"))

        category_id = filters.get("category_id")
        if category_id is not None:
            query = query.filter(Task.category_id == int(category_id))

    return query.order_by(Task.created_at.desc()).all()


def get_task(db: Session, task_id: int, user_id: int) -> Task | None:
    return (
        db.query(Task)
        .options(selectinload(Task.subtasks), selectinload(Task.category))
        .filter(Task.id == task_id, Task.user_id == user_id)
        .first()
    )


def update_task(db: Session, task_id: int, user_id: int, data: Any) -> Task | None:
    task = get_task(db, task_id, user_id)
    if not task:
        return None

    payload = _to_payload(data)
    for field, value in payload.items():
        setattr(task, field, value)

    db.commit()
    db.refresh(task)
    return task


def delete_task(db: Session, task_id: int, user_id: int) -> bool:
    task = get_task(db, task_id, user_id)
    if not task:
        return False

    has_dependents = (
        db.query(Task.id)
        .filter(Task.blocked_by == task_id, Task.user_id == user_id)
        .first()
        is not None
    )
    if has_dependents:
        raise ValueError("Task has dependent tasks")

    db.delete(task)
    db.commit()
    return True