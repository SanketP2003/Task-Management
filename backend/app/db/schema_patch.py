from __future__ import annotations

from sqlalchemy import inspect, text
from sqlalchemy.engine import Engine


def ensure_schema_compatibility(engine: Engine) -> None:
    inspector = inspect(engine)

    if not inspector.has_table("tasks"):
        return

    dialect = engine.dialect.name
    with engine.begin() as conn:
        if dialect == "postgresql":
            conn.execute(
                text(
                    """
                    DO $$
                    BEGIN
                        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_status_enum') THEN
                            CREATE TYPE task_status_enum AS ENUM ('TODO', 'IN_PROGRESS', 'DONE');
                        END IF;
                    END
                    $$;
                    """
                )
            )
            conn.execute(
                text(
                    """
                    DO $$
                    BEGIN
                        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_priority_enum') THEN
                            CREATE TYPE task_priority_enum AS ENUM ('LOW', 'MEDIUM', 'HIGH');
                        END IF;
                    END
                    $$;
                    """
                )
            )
            conn.execute(
                text(
                    """
                    DO $$
                    BEGIN
                        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_recurrence_enum') THEN
                            CREATE TYPE task_recurrence_enum AS ENUM ('NONE', 'DAILY', 'WEEKLY');
                        END IF;
                    END
                    $$;
                    """
                )
            )

            conn.execute(text("ALTER TABLE tasks ADD COLUMN IF NOT EXISTS user_id INTEGER"))
            conn.execute(text("ALTER TABLE tasks ADD COLUMN IF NOT EXISTS description TEXT NOT NULL DEFAULT ''"))
            conn.execute(text("ALTER TABLE tasks ADD COLUMN IF NOT EXISTS due_date TIMESTAMPTZ"))
            conn.execute(text("ALTER TABLE tasks ADD COLUMN IF NOT EXISTS status task_status_enum"))
            conn.execute(text("ALTER TABLE tasks ADD COLUMN IF NOT EXISTS priority task_priority_enum"))
            conn.execute(
                text(
                    "ALTER TABLE tasks ADD COLUMN IF NOT EXISTS tags JSONB "
                    "NOT NULL DEFAULT '[]'::jsonb"
                )
            )
            conn.execute(text("ALTER TABLE tasks ADD COLUMN IF NOT EXISTS reminder_at TIMESTAMPTZ"))
            conn.execute(text("ALTER TABLE tasks ADD COLUMN IF NOT EXISTS recurrence task_recurrence_enum"))
            conn.execute(text("ALTER TABLE tasks ADD COLUMN IF NOT EXISTS notes TEXT"))
            conn.execute(text("ALTER TABLE tasks ADD COLUMN IF NOT EXISTS blocked_by INTEGER"))
            conn.execute(
                text(
                    "ALTER TABLE tasks ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ "
                    "NOT NULL DEFAULT NOW()"
                )
            )
            conn.execute(
                text(
                    "ALTER TABLE tasks ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ "
                    "NOT NULL DEFAULT NOW()"
                )
            )

            conn.execute(text("CREATE INDEX IF NOT EXISTS ix_tasks_user_id ON tasks (user_id)"))

            if inspector.has_table("users"):
                conn.execute(
                    text(
                        """
                        UPDATE tasks
                        SET user_id = u.id
                        FROM (
                            SELECT id
                            FROM users
                            ORDER BY id ASC
                            LIMIT 1
                        ) AS u
                        WHERE tasks.user_id IS NULL
                        """
                    )
                )

            conn.execute(
                text(
                    """
                    UPDATE tasks
                    SET status = (
                        SELECT COALESCE(
                            (SELECT enumlabel FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid
                             WHERE t.typname = 'task_status_enum' AND enumlabel = 'TODO' LIMIT 1),
                            (SELECT enumlabel FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid
                             WHERE t.typname = 'task_status_enum' ORDER BY enumsortorder LIMIT 1)
                        )::task_status_enum
                    )
                    WHERE status IS NULL
                    """
                )
            )
            conn.execute(
                text(
                    """
                    UPDATE tasks
                    SET priority = (
                        SELECT COALESCE(
                            (SELECT enumlabel FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid
                             WHERE t.typname = 'task_priority_enum' AND enumlabel = 'MEDIUM' LIMIT 1),
                            (SELECT enumlabel FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid
                             WHERE t.typname = 'task_priority_enum' ORDER BY enumsortorder LIMIT 1)
                        )::task_priority_enum
                    )
                    WHERE priority IS NULL
                    """
                )
            )
            conn.execute(
                text(
                    """
                    UPDATE tasks
                    SET recurrence = (
                        SELECT COALESCE(
                            (SELECT enumlabel FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid
                             WHERE t.typname = 'task_recurrence_enum' AND enumlabel = 'NONE' LIMIT 1),
                            (SELECT enumlabel FROM pg_enum e JOIN pg_type t ON e.enumtypid = t.oid
                             WHERE t.typname = 'task_recurrence_enum' ORDER BY enumsortorder LIMIT 1)
                        )::task_recurrence_enum
                    )
                    WHERE recurrence IS NULL
                    """
                )
            )
        elif dialect == "sqlite":
            task_columns = {column["name"] for column in inspector.get_columns("tasks")}

            if "user_id" not in task_columns:
                conn.execute(text("ALTER TABLE tasks ADD COLUMN user_id INTEGER"))
            if "description" not in task_columns:
                conn.execute(text("ALTER TABLE tasks ADD COLUMN description TEXT NOT NULL DEFAULT ''"))
            if "due_date" not in task_columns:
                conn.execute(text("ALTER TABLE tasks ADD COLUMN due_date DATETIME"))
            if "status" not in task_columns:
                conn.execute(text("ALTER TABLE tasks ADD COLUMN status TEXT NOT NULL DEFAULT 'To-Do'"))
            if "priority" not in task_columns:
                conn.execute(text("ALTER TABLE tasks ADD COLUMN priority TEXT NOT NULL DEFAULT 'medium'"))
            if "tags" not in task_columns:
                conn.execute(text("ALTER TABLE tasks ADD COLUMN tags TEXT NOT NULL DEFAULT '[]'"))
            if "reminder_at" not in task_columns:
                conn.execute(text("ALTER TABLE tasks ADD COLUMN reminder_at DATETIME"))
            if "recurrence" not in task_columns:
                conn.execute(text("ALTER TABLE tasks ADD COLUMN recurrence TEXT NOT NULL DEFAULT 'none'"))
            if "notes" not in task_columns:
                conn.execute(text("ALTER TABLE tasks ADD COLUMN notes TEXT"))
            if "blocked_by" not in task_columns:
                conn.execute(text("ALTER TABLE tasks ADD COLUMN blocked_by INTEGER"))
            if "created_at" not in task_columns:
                conn.execute(text("ALTER TABLE tasks ADD COLUMN created_at DATETIME"))
            if "updated_at" not in task_columns:
                conn.execute(text("ALTER TABLE tasks ADD COLUMN updated_at DATETIME"))
