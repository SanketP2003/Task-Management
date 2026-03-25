from __future__ import annotations

from datetime import datetime
from enum import Enum

from sqlalchemy import DateTime, Enum as SQLAlchemyEnum, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class TaskStatus(str, Enum):
    TODO = "To-Do"
    IN_PROGRESS = "In Progress"
    DONE = "Done"


class Task(Base):
    __tablename__ = "tasks"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str] = mapped_column(String, nullable=False)
    due_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    status: Mapped[TaskStatus] = mapped_column(
        SQLAlchemyEnum(TaskStatus, name="task_status_enum"),
        default=TaskStatus.TODO,
        nullable=False,
    )
    blocked_by: Mapped[int | None] = mapped_column(ForeignKey("tasks.id"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    blocked_by_task: Mapped[Task | None] = relationship(
        "Task",
        remote_side="Task.id",
        back_populates="dependent_tasks",
        foreign_keys=[blocked_by],
    )
    dependent_tasks: Mapped[list[Task]] = relationship(
        "Task",
        back_populates="blocked_by_task",
        foreign_keys=[blocked_by],
    )