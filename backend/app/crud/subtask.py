from typing import Any

from sqlalchemy.orm import Session

from app.models.subtask import Subtask


def create_subtask(db: Session, *, task_id: int, title: str) -> Subtask:
    subtask = Subtask(title=title.strip(), task_id=task_id)
    db.add(subtask)
    db.commit()
    db.refresh(subtask)
    return subtask


def get_subtask(db: Session, *, subtask_id: int, task_id: int) -> Subtask | None:
    return (
        db.query(Subtask)
        .filter(Subtask.id == subtask_id, Subtask.task_id == task_id)
        .first()
    )


def update_subtask(
    db: Session,
    *,
    subtask_id: int,
    task_id: int,
    data: dict[str, Any],
) -> Subtask | None:
    subtask = get_subtask(db, subtask_id=subtask_id, task_id=task_id)
    if subtask is None:
        return None

    for field, value in data.items():
        setattr(subtask, field, value)

    db.commit()
    db.refresh(subtask)
    return subtask


def delete_subtask(db: Session, *, subtask_id: int, task_id: int) -> bool:
    subtask = get_subtask(db, subtask_id=subtask_id, task_id=task_id)
    if subtask is None:
        return False

    db.delete(subtask)
    db.commit()
    return True
