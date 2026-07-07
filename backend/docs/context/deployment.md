# Deployment

## Purpose

ClipForge deploys via Docker Compose for both development and production. Multi-stage builds minimize image size. GPU passthrough enables hardware-accelerated encoding. Environment-based configuration separates dev, staging, and prod.

## Docker Compose Architecture

```yaml
# docker-compose.yml
services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    ports: ["${API_PORT:-9999}:9999"]
    environment:
      - REDIS_URL=redis://redis:6379/0
      - DATABASE_URL=postgresql+asyncpg://clipforge:...@db:5432/clipforge
      - LLM_API_KEY=${LLM_API_KEY}
    depends_on: [redis, db]
    volumes:
      - downloads:/app/downloads
      - ffmpeg_bin:/app/ffmpeg_bin:ro
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

  worker:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    command: celery -A app.worker.tasks worker -Q gpu,cpu,io --concurrency=4
    environment:
      - REDIS_URL=redis://redis:6379/0
      - LLM_API_KEY=${LLM_API_KEY}
    depends_on: [redis]
    volumes:
      - downloads:/app/downloads
      - ffmpeg_bin:/app/ffmpeg_bin:ro
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]

  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]
    volumes:
      - redis_data:/data
    command: redis-server --maxmemory 2gb --maxmemory-policy allkeys-lru

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: clipforge
      POSTGRES_USER: clipforge
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports: ["5432:5432"]
```

## Multi-Stage Dockerfile

```dockerfile
# Dockerfile
FROM python:3.11-slim AS base
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

FROM base AS dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM dependencies AS development
COPY . .
CMD ["uvicorn", "app.main:app", "--reload", "--host", "0.0.0.0", "--port", "9999"]

FROM base AS production
# Copy only installed packages from dependencies
COPY --from=dependencies /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=dependencies /usr/local/bin/uvicorn /usr/local/bin/
COPY app/ app/
COPY blaze_face_short_range.tflite .
COPY ffmpeg_bin/ ffmpeg_bin/
RUN useradd -m -u 1000 clipforge && chown -R clipforge:clipforge /app
USER clipforge
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "9999"]
```

Layer strategy:
1. **base**: Python image + ffmpeg system package.
2. **dependencies**: Pure pip layer (cached unless requirements.txt changes).
3. **development**: Full source mount, hot reload.
4. **production**: Minimal image — only app code, models, and compiled deps. No build tools.

## Environment Configuration

### Per-Environment Files

| Environment | File | Used By |
|---|---|---|
| Development | `.env` | Docker Compose (default) |
| Staging | `.env.staging` | CI/CD deploy to staging |
| Production | `.env.production` | CI/CD deploy to prod (secrets vault) |

### Required Variables

| Variable | Dev Default | Production | Secret |
|---|---|---|---|
| `LLM_API_KEY` | (Groq test key) | Vault | Yes |
| `DB_PASSWORD` | clipforge | Vault | Yes |
| `REDIS_URL` | redis://redis:6379/0 | ElastiCache TLS URL | No (internal) |
| `SECRET_KEY` | dev-only | Generated 256-bit | Yes |
| `WHISPER_MODEL` | base | medium | No |

## GPU Passthrough

### NVIDIA Docker Runtime

```yaml
# docker-compose.override.yml (production GPU host)
services:
  worker:
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=video,compute
```

The `video` capability is required for NVIDIA's hardware encoder `h264_nvenc`. Without it, FFmpeg falls back to software encoding (slow).

### Verification

```bash
# Confirm GPU visible inside container
docker compose exec worker ffmpeg -encoders | grep nvenc
# Should show: h264_nvenc, hevc_nvenc
```

## Health Checks

```yaml
services:
  api:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9999/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  redis:
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
```

## Production Concerns

- **Secrets**: Never commit `.env` files. Use Docker secrets or a vault (Vault/AWS Secrets Manager) mounted at runtime.
- **Resource limits**: `docker compose up --scale worker-gpu=2` to add more GPU workers. Each worker needs ~4GB VRAM.
- **Logging**: Container logs shipped via `docker compose logs --tail=100 -f` or structured logging driver (json-file → Datadog/CloudWatch).
- **Backup**: PostgreSQL data volume backed up daily via `pg_dump`. MinIO/S3 provides its own replication.
