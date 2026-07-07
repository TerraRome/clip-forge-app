# Create SQLAlchemy Repository

## Description
Create a repository class wrapping data access for a domain entity with CRUD, pagination, and filtering. Repositories abstract the persistence mechanism behind a clean interface. ClipForge currently uses `FileStorage` (JSON file-backed); use this skill when migrating to SQLAlchemy or adding a new entity.

## When to Use
- Migrating from FileStorage to a real database
- Adding a new entity that needs persistence (users, templates, settings)
- Adding complex queries with filtering, sorting, and pagination

## Inputs
- Model class (SQLAlchemy `DeclarativeBase` subclass or dataclass)
- Filterable fields (status, created_at, youtube_url)
- Default sort order
- Page size for paginated queries

## Outputs
- Repository class in `app/repositories/<entity>_repository.py`
- Methods: `get`, `list`, `create`, `update`, `delete`, `paginate`
- Optional: `BaseRepository` for shared CRUD boilerplate

## Steps

1. **Create file** at `app/repositories/<name>_repository.py`. Repository receives a SQLAlchemy `Session` via constructor: `def __init__(self, session: Session)`. Use `from sqlalchemy.orm import Session` and `from app.models.<name> import <Model>`.

2. **Implement `get(id)`** — `session.get(Model, id)`. Return `Optional[Model]`. Raise `NotFoundError` or return None consistent with project convention. Never expose raw session to callers.

3. **Implement `list(**filters)`** — build query with `session.query(Model).filter_by(**filters)`. Apply default ordering (e.g., `order_by(Model.created_at.desc())`). Return `list[Model]`.

4. **Implement `paginate(page, page_size, **filters)`** — return `Page[Model]` dataclass with `items`, `total`, `page`, `pages`, `page_size`. Use `.count()` for total, `.offset((page-1)*page_size).limit(page_size)` for items.

5. **Implement `create(data)`** — accept dict or model instance. `session.add(instance)`, `session.flush()`, return instance with generated fields (id, timestamps). Do NOT call `session.commit()` — caller controls transaction boundary.

6. **Implement `update(id, data)`** — get instance, set attributes from `data` dict, `session.flush()`, return updated instance. Handle partial updates — only set keys present in `data`.

7. **Implement `delete(id)`** — get instance, `session.delete(instance)`, `session.flush()`. Return `True` if existed, `False` if not.

## Example

```python
from sqlalchemy.orm import Session
from app.models.project import ProjectModel
from dataclasses import dataclass

@dataclass
class Page:
    items: list
    total: int
    page: int
    pages: int
    page_size: int

class ProjectRepository:
    def __init__(self, session: Session):
        self._session = session

    def get(self, project_id: str) -> ProjectModel | None:
        return self._session.get(ProjectModel, project_id)

    def paginate(self, page: int = 1, page_size: int = 20, **filters) -> Page:
        q = self._session.query(ProjectModel).filter_by(**filters)
        total = q.count()
        pages = (total + page_size - 1) // page_size
        items = q.offset((page - 1) * page_size).limit(page_size).all()
        return Page(items=items, total=total, page=page, pages=pages, page_size=page_size)
```

## Notes
- Use `session.flush()` (not `commit()`) so the caller controls the transaction. The use case calls `session.commit()` after all repository operations succeed.
- Complex queries (joins, aggregations, subqueries) get dedicated named methods, not dynamic filter builders.
- For the current FileStorage interface, see `app/storage/file_storage.py` — its methods `save/get/update/delete` are the interface that SQLAlchemy repositories should match for drop-in replacement.
- A `BaseRepository[T]` generic class can reduce boilerplate for standard CRUD, but avoid it if the entity has unique query patterns.
