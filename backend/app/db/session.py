from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import get_database_url

DATABASE_URL = get_database_url()

# SQLite needs special connection args for single-threaded local development.
connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(DATABASE_URL, connect_args=connect_args)

# Session factory used by dependencies and future repository/CRUD layers.
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
