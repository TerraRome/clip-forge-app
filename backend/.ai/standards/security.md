# Security Standards — ClipForge

## Secrets Management
- All secrets in `.env` file. Never committed.
- `.env` values accessed via `pydantic_settings.BaseSettings`.
- Committed `.env.example` with placeholder values only.
- Production secrets via environment variables in Docker/deployment platform.
- API keys never logged or exposed in responses.

## Authentication (Future)
- **JWT Bearer tokens** — Auth0 or self-issued RS256.
- Access token: 15 min TTL. Refresh token: 7 day TTL (rotated on use).
- Token validation at FastAPI middleware via `Depends()`.
- Payload: `sub` (user_id), `aud`, `iat`, `exp`, `scope`.

## Authorization (Future)
- Role-based: `user`, `admin`.
- Resource-based: ownership check on every mutation.
- FastAPI dependency `get_current_user()` -> `require_ownership(resource_id)`.

## Input Validation
- **All inputs validated by Pydantic** at API boundary — length limits, regex, allowed values.
- YouTube URL regex validation before passing to yt-dlp.
- `num_clips` constrained to `{1, 3, 5, 10}` — whitelist, not arbitrary.
- `subtitle_preset` constrained to known enum set.
- File uploads: validate MIME type via magic bytes, max size 100 MB.

## File System Safety
- All file operations use `Path()` objects. No raw string path construction.
- Download and clip output restricted to `settings.downloads_dir`.
- No symlink following. Temp files cleaned up after use.

## Subprocess Safety
- All subprocess commands use argument lists, never `shell=True`.
- Commands are fixed lists: `["ffmpeg", "-y", ...]` — user input is positional arg.
- Timeout on all subprocess calls (`timeout=600`).
- `stdin=subprocess.DEVNULL` on all calls.

## CORS
- Current: `allow_origins=["*"]` — acceptable for local/MVP only.
- Production: restrict to known frontend origins.
- Methods: `GET, POST, PUT, PATCH, DELETE, OPTIONS`.
- Never use `allow_origins=["*"]` in production.

## Rate Limiting
- Per-user token bucket: 100 req/min standard, 10 req/s burst.
- Per-IP fallback for unauthenticated endpoints.
- Return 429 with `Retry-After` header + structured error body.

## Dependencies
- `pip-audit` in CI for known-vulnerability scanning.
- Dependabot monthly for patch bumps.
- Pinned versions in `requirements.txt`/`pyproject.toml`.

## Forbidden
- Hardcoded secrets in source code.
- `shell=True` in any subprocess call.
- User input as command-line argument without validation.
- Disabling SSL verification (`verify=False`).
- `eval()` on any user-provided content.
- Storing plaintext secrets in the database.
