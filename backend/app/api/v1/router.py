from fastapi import APIRouter

from app.api.v1.endpoints import health

# API v1 router groups all versioned endpoints.
api_router = APIRouter()
api_router.include_router(health.router, tags=["Health"])
