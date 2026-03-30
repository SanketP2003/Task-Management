from fastapi import APIRouter

from app.api.v1.endpoints import auth, category, health, task

api_router = APIRouter()
api_router.include_router(health.router, tags=["Health"])
api_router.include_router(auth.router)
api_router.include_router(category.router)
api_router.include_router(task.router)
