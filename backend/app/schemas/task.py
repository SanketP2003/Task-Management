from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.task import TaskPriority, TaskRecurrence, TaskStatus
from app.schemas.category import CategoryResponse
from app.schemas.subtask import SubtaskResponse


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
    category_id: int | None = None


class TaskCreate(TaskBase):
    pass


class TaskUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    due_date: datetime | None = None
    status: TaskStatus | None = None
    blocked_by: int | None = None
    category_id: int | None = None


class TaskResponse(TaskBase):
    id: int
    created_at: datetime
    updated_at: datetime
    subtasks: list[SubtaskResponse] = Field(default_factory=list)
    category: CategoryResponse | None = None

    model_config = ConfigDict(from_attributes=True)