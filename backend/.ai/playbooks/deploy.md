# Deploy to Production

## Context
Deploy ClipForge backend. Single-server deployment: uvicorn serves FastAPI, pipeline
runs synchronously in daemon threads. No Docker yet. No Celery yet.

## Prerequisites
- `main` branch, all changes committed
- `ruff check .` and `mypy app/ --ignore-missing-imports` pass
- FFmpeg installed: `ffmpeg -version` (needs h264_videotoolbox support on macOS)
- `downloads/` directory exists and writable
- `.env` file with correct settings (especially `llm_api_key`)

## Steps

1. **Pull and install**:
   ```bash
   git checkout main && git pull origin main
   python3 -m venv venv && source venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Lint and type check**:
   ```bash
   ruff check app/
   mypy app/ --ignore-missing-imports
   ```

3. **Run inline self-check** — test each service loads:
   ```bash
   python3 -c "
   from app.services.video_service import VideoService
   from app.services.transcript_service import TranscriptService
   from app.services.face_service import FaceService
   from app.services.smart_crop_service import SmartCropService
   from app.services.render_service import RenderService
   print('All services import OK')
   "
   ```

4. **Run schema migration** (if `Project` dataclass changed):
   ```bash
   python3 -c "
   from pathlib import Path
   from app.state import storage
   count = sum(1 for d in Path('./downloads').iterdir() if (d / 'project.json').exists() and storage.get(d.name))
   print(f'Migrated {count} projects')
   "
   ```

5. **Kill existing process**:
   ```bash
   pkill -f "uvicorn app.main:app" || true
   sleep 1
   ```

6. **Start server**:
   ```bash
   nohup uvicorn app.main:app --host 0.0.0.0 --port 9999 --workers 1 \
     --log-level info 2>&1 | tee -a clipforge.log &
   echo $! > clipforge.pid
   sleep 2
   ```

7. **Verify health**:
   ```bash
   curl -f http://localhost:9999/health
   ```

8. **Smoke test — full E2E**:
   ```bash
   python3 -c "
   import requests, time
   r = requests.post('http://localhost:9999/api/projects',
       json={'youtube_url': 'https://youtu.be/dQw4w9WgXcQ', 'num_clips': 1,
             'subtitle_preset': 'classic'})
   pid = r.json()['id']
   print(f'Project: {pid}')
   requests.post(f'http://localhost:9999/api/projects/{pid}/process')
   for _ in range(60):
       p = requests.get(f'http://localhost:9999/api/projects/{pid}').json()
       if p['status'] in ('done', 'error'):
           break
       time.sleep(5)
   else:
       raise RuntimeError('Timeout waiting for pipeline')
   assert p['status'] == 'done', f'Pipeline failed: {p.get(\"error_message\", \"unknown\")}'
   print(f'Deploy OK: {p[\"progress\"]}%')
   "
   ```

## Verification
- `curl -f http://localhost:9999/health` returns `{"status": "ok"}`
- E2E test creates project, processes, reaches DONE status
- Clips downloadable via GET `/api/download/{project_id}` as zip
- `clipforge.log` has no "pipeline_failed" events

## Rollback
```bash
kill $(cat clipforge.pid) 2>/dev/null
git checkout <previous-tag-or-commit>
nohup uvicorn app.main:app --host 0.0.0.0 --port 9999 &
```
