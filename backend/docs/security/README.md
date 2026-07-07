# Security Model

## Current State (MVP)
- No authentication. All endpoints are public.
- Single-user tool: the developer/creator running the server locally.
- API key stored in `.env`, not in code.

## Authentication Flow (Planned)
```
Client                     Server
  |                          |
  |-- POST /auth/login ----->|  Validate credentials
  |<--- { access_token,     |  Return JWT (RS256)
  |       refresh_token }   |  access: 15 min, refresh: 7 days
  |                          |
  |-- GET /projects -------->|  Verify JWT in Authorization header
  |   Authorization: Bearer  |  Extract user_id from `sub` claim
  |<--- 200 OK, data -------|  Return user's projects only
```

## Data Protection
- **In transit**: HTTPS (TLS 1.2+) in production. HTTP localhost in dev.
- **At rest**: No sensitive user data stored. Video files are raw media, no PII.
- **API keys**: Environment variables only, never logged.
- **File storage**: Restricted to `settings.downloads_dir` — path traversal prevented via `Path()` joins.

## Pipeline Security
- Subprocess: no `shell=True`. Argument lists only. Timeout enforced.
- YouTube URL: validated via regex before passing to yt-dlp.
- File paths: constructed with `Path()`, restricted to downloads directory.
- Temp files: cleaned up after processing (`NamedTemporaryFile`, explicit `unlink()`).

## Threat Surface
| Threat | Mitigation |
|--------|------------|
| Malicious YouTube URL | Regex validation + yt-dlp sandbox |
| Subprocess injection | No shell=True, fixed command lists |
| Path traversal | Path() object + directory restriction |
| Denial of service (long render) | Subprocess timeout (600s) |
| Dependency vulnerability | pip-audit in CI, pinned deps |
