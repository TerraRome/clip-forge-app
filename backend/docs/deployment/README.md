# Deployment Guide

## Docker Setup
```dockerfile
FROM python:3.13-slim
RUN apt-get update && apt-get install -y ffmpeg
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Docker Compose (local dev)
```yaml
services:
  api:
    build: .
    ports: ["8000:8000"]
    volumes: ["./downloads:/app/downloads"]
    env_file: .env
```

## Environment Variables
| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `DOWNLOAD_DIR` | Base path for file storage | No | `./downloads` |
| `OPENAI_API_KEY` | Whisper/LLM API key | Yes | - |
| `LLM_API_KEY` | LLM provider key (same as OpenAI) | No | `OPENAI_API_KEY` |
| `LOG_LEVEL` | Logging level | No | `INFO` |
| `HOST` | Bind address | No | `0.0.0.0` |
| `PORT` | HTTP port | No | `8000` |

## Infrastructure Requirements
- **CPU**: 2+ cores (FFmpeg rendering is CPU-bound)
- **RAM**: 4 GB minimum (Whisper API calls, no local model)
- **Disk**: 10 GB+ for video processing temp files
- **Network**: Outbound to YouTube API + OpenAI API

## CI/CD Pipeline
1. `pip install -r requirements.txt`
2. `mypy --strict app/`
3. `ruff check app/`
4. `pytest --cov=app --cov-fail-under=80`
5. Build Docker image, push to registry
6. Deploy to target (fly.io, Railway, or manual Docker host)
