from fastapi import FastAPI

from app.db.session import engine

app = FastAPI(title="Task Manager API", version="0.1.0")


@app.get("/health", tags=["Health"])
async def health_check() -> dict[str, str]:
    return {"status": "ok"}


@app.on_event("startup")
def on_startup() -> None:
    # Touch engine to ensure DB configuration is initialized.
    _ = engine
