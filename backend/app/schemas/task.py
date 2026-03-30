from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.task import TaskPriority, TaskRecurrence, TaskStatus


class TaskBase(BaseModel):
    title: str
    description: str
    due_date: datetime
    status: TaskStatus = TaskStatus.TODO
    priority: TaskPriority = TaskPriority.MEDIUM
    tags: list[str] = Field(default_factory=list)
    reminder_at: datetime | None = None
    recurrence: TaskRecurrence = TaskRecurrence.NONE
    notes: str | None = None
    blocked_by: int | None = None


class TaskCreate(TaskBase):
    pass


class TaskUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    due_date: datetime | None = None
    status: TaskStatus | None = None
    blocked_by: int | None = None


class TaskResponse(TaskBase):
    id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)