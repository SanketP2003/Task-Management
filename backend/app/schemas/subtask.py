from pydantic import BaseModel, ConfigDict


class SubtaskBase(BaseModel):
    title: str


class SubtaskCreate(SubtaskBase):
    pass


class SubtaskUpdate(BaseModel):
    title: str | None = None
    is_completed: bool | None = None


class SubtaskResponse(BaseModel):
    id: int
    title: str
    is_completed: bool
    task_id: int

    model_config = ConfigDict(from_attributes=True)
