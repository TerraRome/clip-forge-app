# FastAPI Patterns (ClipForge)

## App Setup
```python
app = FastAPI(title="AI YouTube Clipper", version="0.1.0", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], ...)
app.include_router(router, prefix="/api")
```
- Lifespan for startup/shutdown (structlog config)
- Router prefix `/api`

## Pydantic v2 Validation
```python
class CreateProjectRequest(BaseModel):
    num_clips: int = Field(..., ge=1, le=10)

    @field_validator("num_clips")
    @classmethod
    def validate_num_clips(cls, v: int) -> int:
        if v not in {1, 3, 5, 10}:
            raise ValueError("num_clips must be 1, 3, 5, or 10")
        return v
```
- Use `field_validator` (not `@validator`) — Pydantic v2
- `@classmethod` required for field_validator
- Regex validation for YouTube URLs

## Exception Handling
- HTTPException with status codes (404, 409, 400)
- ErrorResponse schema for 4xx responses in `responses={}`

## Streaming Response
```python
return StreamingResponse(zip_buffer, media_type="application/zip",
    headers={"Content-Disposition": f'attachment; filename="{project_id}.zip"'})
```

## No DI framework
- Module-level singletons (`storage = FileStorage()`) instead of `Depends()`
- Services instantiated directly per pipeline run
