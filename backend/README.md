# AI YouTube Clipper — Backend

FastAPI backend that downloads YouTube videos, transcribes with Whisper, detects highlights via speech-density heuristics, and renders vertical 9:16 clips with burned-in subtitles via FFmpeg.

## Quick Start

```bash
cp .env.example .env
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## API

| Method | Path                 | Description           |
| ------ | -------------------- | --------------------- |
| POST   | `/api/projects`      | Create a new project  |
| POST   | `/api/process`       | Start processing      |
| GET    | `/api/projects/{id}` | Poll project status   |
| GET    | `/api/download/{id}` | Download clip archive |
| GET    | `/health`            | Health check          |

## Architecture

```
Flutter App → FastAPI → yt-dlp → Whisper → Heuristic Highlight → FFmpeg → Clip files
```

## Project Structure

```
backend/
├── app/
│   ├── api/
│   │   ├── router.py      # FastAPI routes
│   │   └── schemas.py     # Pydantic request/response models
│   ├── models/
│   │   └── project.py     # Project domain model
│   ├── services/
│   │   ├── video_service.py      # yt-dlp download, audio extraction
│   │   ├── transcript_service.py # Whisper transcription
│   │   ├── highlight_service.py  # Speech-density highlight detection
│   │   └── render_service.py     # FFmpeg subtitle burning
│   ├── storage/
│   │   └── file_storage.py       # JSON file-based persistence
│   ├── worker/
│   │   └── pipeline.py    # Orchestrates the full pipeline
│   ├── state.py           # Global storage singleton
│   └── config.py          # Pydantic settings
├── downloads/             # Downloaded videos & rendered clips
├── requirements.txt
└── README.md
```

## Environment Variables

See `.env.example`. Key ones:

- `WHISPER_MODEL` — `base` (default), `small`, `medium`, `large`
- `YT_DLP_COOKIES_FILE` — path to browser cookies for private videos

## Notes

- In-memory storage only for MVP. State resets on restart.
- No Celery/Redis. Pipeline runs as a blocking background thread.
- Highlight detection uses words-per-second heuristic. Upgrade to ML-based when needed.
