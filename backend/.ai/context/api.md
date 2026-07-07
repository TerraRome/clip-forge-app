# API Endpoints

## POST `/api/projects` — Create Project
- **Body**: `CreateProjectRequest { youtube_url, num_clips (1/3/5/10), subtitle_preset (classic/tiktok_3words/word_pop/karaoke) }`
- **Validation**: YouTube URL regex (youtube.com/watch, youtu.be, shorts), num_clips must be in {1,3,5,10}
- **Returns**: `201` with `ProjectResponse { id, youtube_url, num_clips, subtitle_preset, status, error_message, progress }`
- **Side effect**: Saves project JSON to disk via FileStorage

## POST `/api/projects/{project_id}/process` — Start Processing
- **Guard**: 404 if not found, 409 if not PENDING
- **Action**: Sets status → PROCESSING, spawns daemon thread `run_pipeline(project_id)`, returns immediately
- **Returns**: `ProjectResponse` with status=processing

## GET `/api/projects/{project_id}` — Poll Status
- **Returns**: Current `ProjectResponse` (client polls this)
- Progress goes: 5 (download) → 20 (audio) → 30 → 50 (transcribe) → 65 (highlights) → 65-100 (render clips)

## GET `/api/download/{project_id}` — Download Clips ZIP
- **Guard**: 404 if not found, 400 if not DONE
- **Returns**: `StreamingResponse` — ZIP file containing all `clip_*.mp4` files
- Content-Disposition: `attachment; filename="{project_id}.zip"`
