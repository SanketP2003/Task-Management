import ssl

from sqlalchemy import create_engine
from sqlalchemy.engine import make_url
from sqlalchemy.orm import sessionmaker

from app.core.config import get_database_url

DATABASE_URL = get_database_url()

# SQLite needs special connection args for single-threaded local development.
connect_args: dict[str, object] = {}
engine_url = DATABASE_URL
engine_kwargs: dict[str, object] = {}

if DATABASE_URL.startswith("sqlite"):
	connect_args = {"check_same_thread": False}
else:
	url = make_url(DATABASE_URL)
	engine_kwargs = {
		# Re-check pooled connections and reconnect if the server has dropped them.
		"pool_pre_ping": True,
		"pool_recycle": 300,
	}

	# pg8000 does not support the sslmode keyword directly.
	if url.drivername.startswith("postgresql+pg8000"):
		sslmode = url.query.get("sslmode")
		if sslmode is not None:
			query = dict(url.query)
			query.pop("sslmode", None)
			engine_url = url.set(query=query)

			if sslmode.lower() in {
				"require",
				"verify-ca",
				"verify-full",
				"prefer",
				"allow",
			}:
				connect_args["ssl_context"] = ssl.create_default_context()

engine = create_engine(engine_url, connect_args=connect_args, **engine_kwargs)

# Session factory used by dependencies and future repository/CRUD layers.
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
