import os

from dotenv import load_dotenv

load_dotenv()

DEFAULT_SQLITE_URL = "sqlite:///./task_manager.db"
DEFAULT_SECRET_KEY = "change-me-local-dev-secret"
DEFAULT_ACCESS_TOKEN_EXPIRE_MINUTES = "30"
DEFAULT_REFRESH_TOKEN_EXPIRE_DAYS = "7"


def get_database_url() -> str:
    return os.getenv("DATABASE_URL", DEFAULT_SQLITE_URL)


def get_secret_key() -> str:
    return os.getenv("SECRET_KEY", DEFAULT_SECRET_KEY)


def get_access_token_expire_minutes() -> int:
    return int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", DEFAULT_ACCESS_TOKEN_EXPIRE_MINUTES))


def get_refresh_token_expire_days() -> int:
    return int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", DEFAULT_REFRESH_TOKEN_EXPIRE_DAYS))
