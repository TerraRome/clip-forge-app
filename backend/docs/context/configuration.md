# Configuration

## Purpose

ClipForge uses Pydantic Settings (`pydantic-settings`) for all configuration. Every configurable value is defined as a typed field with a default, loaded from environment variables or an `.env` file. This provides type validation, IDE autocompletion, and documentation in a single source of truth.

## Settings Model

Defined in `app/config.py`:

```python
class Settings(BaseSettings):
    # Server
    host: str = "0.0.0.0"
    port: int = 9999

    # Storage
    downloads_dir: str = "./downloads"
    clips_dir: str = "./clips"

    # Whisper
    whisper_model: str = "base"

    # yt-dlp
    yt_dlp_cookies_file: str = ""
    ffmpeg_path: str = "./ffmpeg_bin"
    ffprobe_path: str = "./ffprobe_bin"

    # LLM
    llm_api_base: str = "https://api.groq.com/openai/v1"
    llm_api_key: str = ""
    llm_model: str = "llama-3.3-70b-versatile"

    model_config = {"env_prefix": "", "env_file": ".env"}

settings = Settings()
```

The module-level `settings` singleton is imported project-wide: `from app.config import settings`.

## Environment Variables

### Complete Variable Reference

| Variable | Type | Default | Secret | Purpose |
|---|---|---|---|---|
| `HOST` | string | `"0.0.0.0"` | No | Uvicorn bind address |
| `PORT` | int | `9999` | No | Uvicorn bind port |
| `DOWNLOADS_DIR` | string | `"./downloads"` | No | Video/clip storage root |
| `CLIPS_DIR` | string | `"./clips"` | No | Clip output directory |
| `WHISPER_MODEL` | string | `"base"` | No | Model size: base/small/medium/large |
| `YT_DLP_COOKIES_FILE` | string | `""` | No | Path to YouTube cookies file |
| `FFMPEG_PATH` | string | `"./ffmpeg_bin"` | No | FFmpeg binary path |
| `FFPROBE_PATH` | string | `"./ffprobe_bin"` | No | ffprobe binary path |
| `LLM_API_BASE` | string | `"https://api.groq.com/openai/v1"` | No | OpenAI-compatible API base URL |
| `LLM_API_KEY` | string | `""` | **Yes** | API key for LLM provider |
| `LLM_MODEL` | string | `"llama-3.3-70b-versatile"` | No | Model identifier |

### Environment File

`.env.example` (committed to repo):
```bash
# Server
HOST=0.0.0.0
PORT=8000

# Storage
DOWNLOADS_DIR=./downloads
CLIPS_DIR=./clips

# Whisper
WHISPER_MODEL=base

# yt-dlp
FFMPEG_PATH=./ffmpeg_bin
YT_DLP_COOKIES_FILE=

# LLM (Groq)
# LLM_API_KEY=your_key_here
```

`.env` (never committed, in `.gitignore`):
```bash
# Local overrides
PORT=9999
LLM_API_KEY=gsk_your_actual_key
```

The `.env.example` serves as documentation. Developers copy it to `.env` and fill in secrets.

## Configuration Loading Precedence

1. Environment variables (highest priority - used in Docker/production)
2. `.env` file (development convenience)
3. Hardcoded defaults (fallback)

Pydantic Settings evaluates in this order automatically. This means Docker Compose can override everything via `environment:` keys without needing `.env` files inside containers.

## Secrets Management

### Current State

`LLM_API_KEY` is passed via `.env` file. The production key in source control was a placeholder/debug key. Production keys are never committed.

### Production Strategy

**Method: Docker Secrets**

```yaml
# docker-compose.yml
services:
  api:
    secrets:
      - llm_api_key
    environment:
      - LLM_API_KEY_FILE=/run/secrets/llm_api_key

secrets:
  llm_api_key:
    file: ./secrets/llm_api_key.txt
```

Settings would load from file if `_FILE` suffix present:

```python
@property
def llm_api_key(self) -> str:
    if key_file := os.environ.get("LLM_API_KEY_FILE"):
        return Path(key_file).read_text().strip()
    return self._llm_api_key
```

**Method: Vault (Future)**

Hashicorp Vault or AWS Secrets Manager for production secrets. The app fetches secrets at startup via a `SecretsManager` class, caching them in memory. No secrets in environment variables.

## Environment-Based Configuration

### Development

- `.env` file in project root.
- `WHISPER_MODEL=base` (fast startup, ~1GB RAM).
- In-memory/FileStorage (no external DB).
- `ffmpeg_path=./ffmpeg_bin` (bundled binary for macOS).
- `LLM_API_KEY` is a development/test key.

### Staging

- Environment variables injected by CI/CD pipeline.
- `WHISPER_MODEL=small` (balance speed/accuracy).
- PostgreSQL via Docker Compose.
- MinIO for file storage (S3-compatible).
- Celery with Redis broker (single worker).
- Real LLM API key from vault.

### Production

- Environment variables from secrets manager.
- `WHISPER_MODEL=medium` (quality focus).
- Managed PostgreSQL (RDS) with read replicas.
- S3 for file storage with lifecycle policies.
- Celery with Redis Sentinel.
- GPU workers for rendering.
- LLM API key rotated monthly, injected at deploy.

## Runtime Configuration

### Whisper Model Caching

The Whisper model is loaded once at `TranscriptService` construction. Different model sizes have different memory footprints:

| Model | Parameters | RAM | VRAM | Disk |
|---|---|---|---|---|
| `base` | 74M | ~1GB | ~0.5GB | 142MB |
| `small` | 244M | ~2GB | ~1GB | 466MB |
| `medium` | 769M | ~5GB | ~2.5GB | 1.5GB |
| `large` | 1550M | ~10GB | ~5GB | 2.9GB |

Server memory must accommodate the model plus FFmpeg processes. A production server with `medium` needs at least 8GB RAM.

## Best Practices

1. **Never hardcode environment-specific values**. Everything goes in `Settings`.
2. **Use env_prefix sparingly**. Current config has no prefix (`""`), so env vars are simple (`WHISPER_MODEL` not `CLIPFORGE_WHISPER_MODEL`). A prefix may be needed if other services share the environment.
3. **Type everything**. No raw strings that should be `int` or `bool`. Pydantic coerces and validates.
4. **Document defaults in the field definition**. The `description` kwarg on Pydantic fields documents the purpose.
5. **One `.env` per environment**. Never share `.env` files between dev/staging/prod.
6. **Load at import time**. The module-level `settings = Settings()` ensures config is available at import, not at request time. Tests can override via `monkeypatch.setattr(settings, "key", value)`.
