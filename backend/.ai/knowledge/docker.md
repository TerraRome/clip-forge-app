# Docker Setup (Future)

## Not Currently Used
ClipForge runs natively on macOS. No containers.

## Planned Multi-Stage Build
```dockerfile
# Builder stage
FROM python:3.11-slim AS builder
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.11-slim
COPY --from=builder /root/.local /root/.local
COPY backend/ /app/
COPY blaze_face_short_range.tflite /app/
WORKDIR /app
CMD ["python", "-m", "app", "--no-reload"]
```

## Planned Docker Compose
```yaml
services:
  api:
    build: .
    ports: ["9999:9999"]
    volumes: ["./downloads:/app/downloads"]
    environment:
      - LLM_API_KEY=${LLM_API_KEY}

  celery-worker:
    build: .
    command: celery -A app.worker worker --concurrency 1
    volumes: ["./downloads:/app/downloads"]
    deploy:
      resources:
        reservations:
          devices: [{driver: nvidia, count: 1, capabilities: [gpu]}]

  redis:
    image: redis:7-alpine

  postgres:
    image: postgres:16-alpine
    volumes: ["pgdata:/var/lib/postgresql/data"]
```

## Volume Mounts
- `./downloads` — persistent media storage (shared between api + worker)
- `blaze_face_short_range.tflite` — ML model file
- No bind mounts for code (production)
