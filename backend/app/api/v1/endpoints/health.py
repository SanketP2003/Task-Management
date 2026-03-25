from fastapi import APIRouter

# Endpoint module for service health and readiness checks.
router = APIRouter()


@router.get("/health")
async def health_check() -> dict[str, str]:
    return {"status": "ok"}
