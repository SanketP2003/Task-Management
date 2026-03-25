from fastapi import FastAPI

from app.api.v1.router import api_router
from app.db.session import engine

app = FastAPI(title="Task Manager API", version="0.1.0")

# Register versioned API routes.
app.include_router(api_router, prefix="/api/v1")


@app.on_event("startup")
def on_startup() -> None:
    # Touch engine to ensure DB configuration is initialized at app startup.
    _ = engine
