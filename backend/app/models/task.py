from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Optional

from sqlalchemy import JSON, DateTime, Enum as SQLAlchemyEnum, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class TaskStatus(str, Enum):
    TODO = "To-Do"
    IN_PROGRESS = "In Progress"
    DONE = "Done"


class TaskPriority(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class TaskRecurrence(str, Enum):
    NONE = "none"
    DAILY = "daily"
    WEEKLY = "weekly"


class Task(Base):
    __tablename__ = "tasks"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str] = mapped_column(String, nullable=False)
    due_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    status: Mapped[TaskStatus] = mapped_column(
        SQLAlchemyEnum(TaskStatus, name="task_status_enum"),
        default=TaskStatus.TODO,
        nullable=False,
    )
    priority: Mapped[TaskPriority] = mapped_column(
        SQLAlchemyEnum(TaskPriority, name="task_priority_enum"),
        default=TaskPriority.MEDIUM,
        nullable=False,
    )
    tags: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    reminder_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    recurrence: Mapped[TaskRecurrence] = mapped_column(
        SQLAlchemyEnum(TaskRecurrence, name="task_recurrence_enum"),
        default=TaskRecurrence.NONE,
        nullable=False,
    )
    notes: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    blocked_by: Mapped[Optional[int]] = mapped_column(ForeignKey("tasks.id"), nullable=True)
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

    blocked_by_task: Mapped[Optional['Task']] = relationship(
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
    user = relationship("User", back_populates="tasks")