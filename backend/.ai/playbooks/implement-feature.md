# Implement Feature End-to-End

## Context
Implement a new feature in ClipForge. Stack: FastAPI, structlog, threading-based pipeline, yt-dlp, Whisper, LLM (Groq), MediaPipe BlazeFace, FFmpeg (h264_videotoolbox), JSON file storage. Layers: model -> storage -> service -> pipeline -> API schema -> API route.

## Prerequisites
- Feature spec with API contract changes (if any)
- `venv` activated, all deps installed (`pip install -r requirements.txt`)
- `ruff check .` and `mypy app/ --ignore-missing-imports` passing on `main`

## Steps

1. **Analyze** — which layers change? Check:
   - `app/models/project.py` — new fields on `Project` dataclass?
   - `app/storage/file_storage.py` — new CRUD methods? Schema migration needed?
   - `app/services/` — new service file or modify existing?
   - `app/worker/pipeline.py` — new pipeline step? Progress % rebalance?
   - `app/api/schemas.py` — new Pydantic request/response?
   - `app/api/router.py` — new endpoint?

2. **Plan** — write a comment block at the feature entry point:
   ```python
   # Feature: Speaker Diarization
   # Entry: app/services/diarize_service.py::DiarizeService.diarize()
   # Depends on: transcript_service (needs segments + audio)
   # Output: speaker labels per segment, stored on Project.clip_paths metadata
   ```

3. **Implement service** — stateless class, structlog, lazy-load heavy models:
   ```python
   # app/services/diarize_service.py
   import structlog
   from typing import Optional
   logger = structlog.get_logger()

   _model = None
   def _get_model():
       global _model
       if _model is None:
           from pyannote.audio import Pipeline
           _model = Pipeline.from_pretrained("pyannote/speaker-diarization-3.1")
       return _model

   class DiarizeService:
       def diarize(self, audio_path: str) -> list[dict]:
           model = _get_model()
           diarization = model(audio_path)
           segments = []
           for turn, _, speaker in diarization.itertracks(yield_label=True):
               segments.append({"start": turn.start, "end": turn.end, "speaker": speaker})
           return segments
   ```

4. **Wire into pipeline** — `app/worker/pipeline.py`:
   ```python
   # After audio extraction (step 2), before transcribe (step 3)
   log.info("step_diarize")
   diarize_svc = DiarizeService()
   speaker_segments = diarize_svc.diarize(audio_path)
   # Pass to transcript service or attach to project
   storage.update(project_id, progress=40.0)
   ```

5. **Add API endpoint** (if exposing) — `app/api/router.py`:
   ```python
   @router.get("/projects/{project_id}/speakers", responses={404: {"model": ErrorResponse}})
   async def get_speakers(project_id: str):
       project = storage.get(project_id)
       if project is None:
           raise HTTPException(404, detail="Project not found")
       return {"speakers": project.speaker_segments}
   ```

6. **Update Pydantic schema** — `app/api/schemas.py`:
   ```python
   class SpeakerSegment(BaseModel):
       start: float
       end: float
       speaker: str
   ```

7. **Self-check** — inline smoke test:
   ```python
   python3 -c "
   from app.services.diarize_service import DiarizeService
   svc = DiarizeService()
   segs = svc.diarize('tests/fixtures/sample.wav')
   assert len(segs) > 0, 'No segments detected'
   assert 'speaker' in segs[0]
   print('DiarizeService OK')
   "
   ```

8. **Lint + type check**:
   ```bash
   ruff check app/
   mypy app/ --ignore-missing-imports
   ```

9. **Manual E2E**:
   ```bash
   curl -X POST http://localhost:9999/api/projects \
     -H 'Content-Type: application/json' \
     -d '{"youtube_url": "https://youtu.be/dQw4w9WgXcQ", "num_clips": 2}'
   # Process, poll until done, verify output
   ```

## Verification
- `ruff check .` — zero warnings
- `mypy app/ --ignore-missing-imports` — no type errors
- Pipeline produces clips in `downloads/{project_id}/clips/`
- New field populated in project.json

## Rollback
```bash
git checkout main && git branch -D feature/x
# If storage schema changed, run downgrade migration
```
