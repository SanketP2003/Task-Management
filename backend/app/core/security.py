from datetime import datetime, timedelta, timezone
import hashlib
import hmac
from typing import Any

import bcrypt
from jose import JWTError, jwt

from app.core.config import (
    get_access_token_expire_minutes,
    get_refresh_token_expire_days,
    get_secret_key,
)

ALGORITHM = "HS256"


def _normalize_password(password: str) -> bytes:
    return hashlib.sha256(password.encode("utf-8")).digest()


def hash_password(password: str) -> str:
    normalized = _normalize_password(password)
    return bcrypt.hashpw(normalized, bcrypt.gensalt()).decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    normalized = _normalize_password(plain_password)
    try:
        computed = bcrypt.hashpw(normalized, hashed_password.encode("utf-8"))
        return hmac.compare_digest(computed.decode("utf-8"), hashed_password)
    except ValueError:
        return False


def _create_token(data: dict[str, Any], expires_delta: timedelta) -> str:
    payload = data.copy()
    payload["exp"] = datetime.now(timezone.utc) + expires_delta
    return jwt.encode(payload, get_secret_key(), algorithm=ALGORITHM)


def create_access_token(user_id: int) -> str:
    return _create_token(
        {"sub": str(user_id), "type": "access"},
        timedelta(minutes=get_access_token_expire_minutes()),
    )


def create_refresh_token(user_id: int) -> str:
    return _create_token(
        {"sub": str(user_id), "type": "refresh"},
        timedelta(days=get_refresh_token_expire_days()),
    )


def decode_token(token: str) -> dict[str, Any]:
    try:
        return jwt.decode(token, get_secret_key(), algorithms=[ALGORITHM])
    except JWTError as exc:
        raise ValueError("Invalid token") from exc
