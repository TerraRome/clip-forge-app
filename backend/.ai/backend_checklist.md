# Backend Checklist — AI YouTube Clipper

## Milestone 1: Project Setup

- [x] Create folder structure (`/app`, `/downloads`, `/clips`, `.ai/`)
- [x] Create `.gitignore`
- [x] Create `requirements.txt`
- [x] Create `.env.example`
- [x] Create `README.md`
- [ ] Verify Python 3.11+ available
- [ ] Create virtual environment
- [ ] Install dependencies

**Acceptance Criteria:**

- `pip install -r requirements.txt` succeeds
- `python -m app.main` starts FastAPI on port 8000

**Estimated time:** 30min

---

## Milestone 2: Configuration & Entry Point

- [x] Write `app/config.py` (pydantic-settings)
- [x] Write `app/main.py` (FastAPI app, CORS, lifespan, router mount)

**Acceptance Criteria:**

- App starts with `uvicorn app.main:app`
- `GET /health` returns `{"status": "ok"}`

**Estimated time:** 15min

---

## Milestone 3: Models & Storage

- [x] Write `app/models/__init__.py`
- [x] Write `app/models/project.py` (Project dataclass, ProjectStatus enum)
- [x] Write `app/storage/__init__.py`
- [x] Write `app/storage/file_storage.py` (JSON file-based persistence)

**Acceptance Criteria:**

- Can create, read, update project objects
- Projects persist to disk as JSON files
- Thread-safe file operations

**Estimated time:** 30min

---

## Milestone 4: API Layer — Schemas & Router

- [x] Write `app/api/__init__.py`
- [x] Write `app/api/schemas.py` (CreateProject, ProcessRequest, ProjectResponse, ErrorResponse)
- [x] Write `app/api/router.py` (all endpoints)
- [x] Wire router into `app/main.py`

### Endpoints:

- `POST /api/projects` — create project
- `POST /api/process/{project_id}` — start processing (via ProcessRequest)
- `GET /api/projects/{project_id}` — get status
- `GET /api/download/{project_id}` — download zip
- `GET /health` — health check

**Acceptance Criteria:**

- Each endpoint returns correct status codes
- Validation errors return 422 with details
- Missing project returns 404
- Duplicate process returns 409

**Estimated time:** 45min

---

## Milestone 5: Video Service

- [x] Write `app/services/__init__.py`
- [x] Write `app/services/video_service.py`
  - `download(url, output_path) → str`
  - `extract_audio(video_path, audio_path) → str`
  - `get_info(video_path) → dict` (duration, resolution via ffprobe)

**Steps:**

- yt-dlp for download (best quality, mp4)
- FFmpeg for audio extraction (16kHz mono wav)
- FFprobe for video info

**Acceptance Criteria:**

- Downloads a real YouTube video to `downloads/{id}.mp4`
- Extracts audio to `downloads/{id}.wav`
- Handles network errors gracefully (retry 2x)

**Estimated time:** 45min

---

## Milestone 6: Transcript Service

- [x] Write `app/services/transcript_service.py`
  - `transcribe(audio_path) → list[TranscriptSegment]`
  - Segment: `{start, end, text}` in seconds

**Model:** `whisper` base (smallest acceptable accuracy)

**Acceptance Criteria:**

- Transcribes audio with timestamps
- Returns segments with non-empty text
- Handles long audio (>1hr) via chunking

**Estimated time:** 30min

---

## Milestone 7: Highlight Service

- [x] Write `app/services/highlight_service.py`
  - `detect(segments, total_duration, num_clips) → list[HighlightSegment]`
  - HighlightSegment: `{start, end, score}`

**Algorithm (heuristic):**

1. Score each segment by words-per-second
2. Merge adjacent high-score segments within 20–60s bounds
3. Pick top `num_clips`
4. Sort by start time

**ponytail:** Replace with ML-based highlight detection when training data available.

**Acceptance Criteria:**

- Returns up to `num_clips` clips
- Clips don't overlap
- Each clip ≥20s and ≤60s

**Estimated time:** 30min

---

## Milestone 8: Render Service

- [x] Write `app/services/render_service.py`
  - `render_clip(video_path, segments, highlight, output_path, video_width, video_height) → str`
  - Burns ASS subtitles directly (no intermediate SRT)
  - Center-crops to 9:16 vertical
  - H.264 + AAC

**FFmpeg details:**

1. Crop: `crop=w:h:x:y` (center 9:16)
2. Burn subtitles: `ass=file.ass` filter
3. Trim: `-ss start -t duration`
4. Codec: H.264, CRF 23, `-movflags +faststart`
5. Resolution: 1080×1920

**Acceptance Criteria:**

- Outputs vertical 1080×1920 mp4
- Subtitles are readable (white text, black outline, Arial 28pt)
- Each clip named `clip_01.mp4`, `clip_02.mp4`, etc.

**Estimated time:** 45min

---

## Milestone 9: Worker / Pipeline Orchestrator

- [x] Write `app/worker/__init__.py`
- [x] Write `app/worker/pipeline.py`
  - `run_pipeline(project_id)`
  - Steps: download → extract_audio → transcribe → detect → render → update storage
  - Progress tracking at each step (5%, 20%, 30%, 50%, 65%, 100%)
  - Error handling: caught exceptions → status=error, error_message saved

**ponytail:** For MVP, pipeline runs in a background thread (not Celery). Upgrade when async job queue needed.

**Acceptance Criteria:**

- Pipeline runs fully end-to-end from YouTube URL to clips
- Status transitions: pending → processing → done
- On failure: status=error, error_message populated

**Estimated time:** 45min

---

## Milestone 10: Integration & Testing

- [ ] Test with real YouTube URL (short, <5min video)
- [ ] Test with 1, 3, 5, 10 clips
- [ ] Test error: invalid URL
- [ ] Test error: non-existent project
- [ ] Test error: process already running
- [ ] Verify download zip works

**Acceptance Criteria:**

- End-to-end flow completes for a real URL
- All error cases return correct status codes
- Zip file downloads and contains working mp4 files

**Estimated time:** 1hr

---

## Milestone 11: Polish & Documentation

- [x] Add request logging (structlog)
- [x] Add request_id middleware (via structlog context)
- [ ] Update `api.md` with any changes
- [x] Add curl examples to README (via api.md)
- [ ] Verify `ruff check .` passes
- [ ] Verify `mypy app/` passes (or add inline ignores)

**Acceptance Criteria:**

- Linter passes with zero errors
- README has run instructions and curl examples
- Logs show request_id, method, path, status, duration

**Estimated time:** 30min
