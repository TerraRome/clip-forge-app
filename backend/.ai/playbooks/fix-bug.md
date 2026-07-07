# Fix Production Bug

## Context
Debug and fix a bug in ClipForge. The pipeline runs in a daemon thread with 6 steps: download (yt-dlp), extract audio (FFmpeg), transcribe (Whisper), detect highlights (LLM/Groq), face detect (MediaPipe), render (FFmpeg h264_videotoolbox). Each step updates progress on the Project model.

## Prerequisites
- Project ID(s) affected
- `error_message` from `downloads/{project_id}/project.json`
- Structlog JSON lines (grep by project_id or "ERROR")
- Reproducer YouTube URL if possible

## Steps

1. **Reproduce** — run pipeline directly on the same input:
   ```bash
   python3 -c "
   from app.worker.pipeline import run_pipeline
   run_pipeline('$PROJECT_ID')
   "
   # Check error:
   python3 -c "
   from app.state import storage
   p = storage.get('$PROJECT_ID')
   print(f'Status: {p.status}, Error: {p.error_message}, Progress: {p.progress}')
   "
   ```

2. **Isolate step by progress value**:
   | Progress | Step | Failure pattern |
   |----------|------|----------------|
   | 5-20% | Download | yt-dlp rate limit, 403, video gone |
   | 20-30% | Extract audio | FFmpeg codec not found, corrupt source |
   | 30-50% | Transcribe | Whisper OOM (`base` model ~1GB RAM) |
   | 50-65% | Highlights | Groq API key expired, rate limit, malformed response |
   | 65-100% | Render | FFmpeg crop filter OOB, ASS syntax error, codec missing |

3. **Check partial artifacts**:
   ```bash
   ls -la downloads/$PROJECT_ID/
   # source.mp4 exists? → download succeeded
   # audio.wav exists? → extract succeeded
   # clips/ exists with .ass files? → partial render
   ```

4. **Common fixes by layer**:

   - **yt-dlp fails**: add cookies via `yt_dlp_cookies_file` in `.env`, or add `--extractor-args youtube:player_client=android` (already in codebase)
   - **FFmpeg crop crash**: Face box normalized coords produce negative crop. Fix in `SmartCropService.compute_filter()` — clamp `crop_x`/`crop_y` to valid range with `max(0, min(...))` (already done, check for edge case)
   - **Whisper OOM**: downgrade model to `tiny` in `settings.whisper_model = "tiny"`
   - **Groq API error**: check `settings.llm_api_key` expiry, check rate limits at `https://console.groq.com`
   - **ASS subtitle overflow**: special characters `{`, `}`, `,` in transcript text not escaped. Ensure `_esc()` called in all preset builders

5. **Write regression guard**:
   ```python
   # Add to the service or as an inline test
   assert crop_x >= 0 and crop_y >= 0, f"Invalid crop: {crop_x}x{crop_y}"
   ```

6. **Verify full pipeline**:
   ```bash
   python3 -c "
   from app.state import storage
   p = storage.get('$PROJECT_ID')
   assert p.status.name == 'DONE', f'Pipeline failed: {p.error_message}'
   # Check clips exist
   from pathlib import Path
   clips = list(Path(f'downloads/{p.id}/clips').glob('*.mp4'))
   assert len(clips) == p.num_clips, f'Expected {p.num_clips} clips, got {len(clips)}'
   # Check each clip is playable
   import subprocess, json
   for clip in clips:
       r = subprocess.run(['ffprobe', '-v', 'quiet', '-print_format', 'json', '-show_format', str(clip)],
                         capture_output=True, text=True, timeout=15)
       info = json.loads(r.stdout)
       assert float(info['format']['duration']) > 0, f'{clip} has zero duration'
   print('All clips verified')
   "
   ```

## Verification
- Pipeline reaches `DONE` status
- All `num_clips` clips generated, playable, correct resolution (1080x1920)
- Original error case no longer reproduces
- `ruff check .` passes

## Rollback
```bash
git revert HEAD --no-edit
```
