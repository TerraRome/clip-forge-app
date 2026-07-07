# Redis Usage (Future)

## Not Currently Used
No Redis dependency in current codebase.

## Planned Usage

### Celery Broker
- `redis://localhost:6379/0` — task queue for pipeline jobs
- `redis://localhost:6379/0` — result backend for progress/status

### Rate Limiting
```python
import redis.asyncio as aioredis

r = aioredis.from_url("redis://localhost:6379/1")
# Leaky bucket per-user: max 3 concurrent projects
await r.incr(f"user:{user_id}:active_projects")
```

### Cache
- Whisper model cache (already handled by library)
- FFmpeg filter graph results (not needed yet)
- LLM highlight cache (TTL-based dedup for identical transcripts)

### Key Naming Convention
```
project:{id}:status    → string (pending/processing/done/error)
project:{id}:progress  → float (0-100)
user:{id}:queue        → list (FIFO project queue)
```

## Current Equivalent
- FileStorage replaces Redis for status/progress
- Thread replaces Celery worker
- Thread lock replaces Redis atomic operations
