# SQLAlchemy 2.0 Reference

## Not Currently Used
ClipForge uses FileStorage (JSON file persistence), not SQLAlchemy.

## Migration Pattern (When Needed)
```python
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

class Base(DeclarativeBase):
    pass

class ProjectModel(Base):
    __tablename__ = "projects"

    id: Mapped[str] = mapped_column(primary_key=True)
    youtube_url: Mapped[str]
    num_clips: Mapped[int]
    subtitle_preset: Mapped[str] = mapped_column(default="classic")
    status: Mapped[str] = mapped_column(default="pending")
    error_message: Mapped[str] = mapped_column(default="")
    progress: Mapped[float] = mapped_column(default=0.0)

# Async queries
async with async_session() as session:
    stmt = select(ProjectModel).where(ProjectModel.id == pid)
    result = await session.execute(stmt)
    project = result.scalar_one_or_none()
```

## Key Differences from FileStorage
- `async` everywhere (FileStorage is sync)
- Alembic for migrations (FileStorage: no schema management)
- PostgreSQL types vs JSON serialization
