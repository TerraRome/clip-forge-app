# Worker Architecture

## Current (MVP)
Single daemon thread runs pipeline synchronously. Triggered by POST `/projects/{id}/process`.

## Pipeline Steps (in order)
```
1. download_video      yt-dlp -> local MP4
2. extract_audio       ffmpeg -> WAV
3. transcribe           Whisper API -> list[TranscriptSegment]
4. detect_highlights    LLM or energy-based -> list[HighlightSegment]
5. render_clips         ffmpeg trim + concat -> per-clip MP4s
6. generate_subtitles   ASS subtitle file per clip
7. smart_crop           MediaPipe face detect + ffmpeg crop
8. update_status        Persistent as DONE
```

Each step logs start/complete, updates progress (0.0-1.0), and handles errors:
- Non-critical failures (face detection, LLM) trigger fallback, continue.
- Critical failures (download, render) mark project as ERROR.

## Error Boundary
```python
try:
    # pipeline steps
except PipelineError as e:
    storage.update(project_id, status=ERROR, error_message=str(e))
except Exception as e:
    storage.update(project_id, status=ERROR, error_message="Internal error")
```

## Queue Topology (Future Celery)
```
Queue: clipforge-default
  - process_project (single task per project)

Queue: clipforge-render  (separate for CPU-bound FFmpeg)
  - render_clip_segment

Queue: clipforge-webhook (low priority)
  - deliver_webhook
```

## Retry Policy
- Transient failures (network): retry 3x with exponential backoff.
- Permanent failures (invalid URL, corrupt file): immediate fail, no retry.
- Celery: `max_retries=3, default_retry_delay=60`.
