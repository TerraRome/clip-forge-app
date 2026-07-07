# API Standards — ClipForge

## RESTful Naming
- Base path: `/api/v1/` (currently implicit v1 at `/api/`).
- **Nouns only** — never verbs in URL path.
- Plural: `/projects`, `/jobs`.
- Sub-resources: `/projects/{project_id}/clips`.
- Actions not mapping to CRUD: POST with action verb or `/resource/{id}/action`.

## Endpoints
| Method | Path                            | Status | Description             |
|--------|----------------------------------|--------|-------------------------|
| POST   | /api/projects                    | 201    | Create project          |
| POST   | /api/projects/{id}/process       | 200    | Start processing        |
| GET    | /api/projects/{id}               | 200    | Get project status      |
| GET    | /api/download/{project_id}       | 200    | Download clips (zip)    |
| GET    | /health                          | 200    | Health check            |

## Request/Response Models
- Every endpoint has Pydantic `RequestModel` for body and `ResponseModel` for response.
- Query params use Pydantic `Query(...)` with description, example, constraints.
- `response_model_exclude_unset=True` for PATCH endpoints (partial update).
- Validate at boundary (Pydantic), trust inside.

## Pagination
```python
class PaginatedResponse(BaseModel):
    items: list[T]
    total: int
    page: int          # 1-indexed
    page_size: int     # default 20, max 100
    total_pages: int
```
- Cursor-based for large/time-series resources (jobs, logs).

## Error Response Format
```json
{
  "error": "VALIDATION_ERROR",
  "detail": {"field": ["must be a valid URL"]},
  "correlation_id": "uuid"
}
```
- `error`: machine-readable SCREAMING_SNAKE_CASE code.
- `detail`: string or dict with field-level messages.

## Status Code Usage
| Code | When                                         |
|------|----------------------------------------------|
| 200  | Success, resource exists                     |
| 201  | Resource created                             |
| 400  | Invalid input (validation error)             |
| 404  | Resource not found                           |
| 409  | State conflict (e.g., already processing)    |
| 422  | Pydantic validation error (FastAPI default)  |
| 429  | Rate limit exceeded                          |
| 500  | Internal error (no stack trace leaked)       |

## OpenAPI
- Auto-generated via FastAPI. Tags: `Projects`, `Jobs`, `Auth`, `Webhooks`.
- `operation_id` matches function name for generation tooling.
- Every response documented with `responses=` including 422 and 500.

## Rate Limiting
- Per-user: 100 req/min standard, 10 req/s burst.
- Per-IP fallback for unauthenticated endpoints (health, login).
- Stricter: login (5/min), video upload (10/min).
- Headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.
- Return 429 with `Retry-After` header.

## Forbidden
- Returning `dict` from handlers — always use Pydantic models.
- Status 200 for resource creation (use 201).
- Endpoints without `response_model`.
- Nested response wrappers unless needed for pagination.
