# Investigate Production Incident

## Context
Investigate a production issue in ClipForge. Pipeline runs sequentially in a daemon thread: download (yt-dlp) -> extract audio (FFmpeg) -> transcribe (Whisper base) -> detect highlights (Groq LLM llama-3.3-70b) -> face detect (MediaPipe BlazeFace) -> render (FFmpeg h264_videotoolbox -> 1080x1920 mp4). Projects stored as JSON in `downloads/{id}/project.json`.

## Prerequisites
- Incident time window
- Affected project IDs (from user reports or `downloads/` directory scan)
- Server access: `downloads/` directory, structlog output (stdout), system resources

## Steps

1. **Check health**
   ```bash
   curl -f http://localhost:9999/health
   ```

2. **Scan project store for ERROR status**:
   ```python
   python3 -c "
   from pathlib import Path
   import json
   for d in Path('./downloads').iterdir():
       meta = d / 'project.json'
       if meta.exists():
           p = json.loads(meta.read_text())
           if p['status'] == 'error':
               print(f\"{p['id']}: {p['error_message']} (progress: {p['progress']})\")
   "
   ```

3. **Check system resources**:
   ```bash
   df -h downloads/     # disk full from clips?
   free -h              # OOM from Whisper?
   ps aux | grep ffmpeg # stuck subprocess?
   ```

4. **Review recent git changes** (last 24h):
   ```bash
   git log --since="24 hours ago" --oneline
   git diff HEAD~5 --stat
   ```

5. **Common failure patterns and diagnostics**:

   | Symptom | Cause | Diagnostic |
   |---------|-------|------------|
   | All projects fail at 5-20% | yt-dlp broken by YouTube change | `yt-dlp --verbose https://youtu.be/...` |
   | All projects fail at 30-50% | Whisper OOM after dep update | Check RSS before crash, try `tiny` model |
   | All projects fail at 50-65% | Groq API down or key expired | `curl https://api.groq.com/openai/v1/models -H "Authorization: Bearer $KEY"` |
   | All projects fail at render | FFmpeg codec issue | `ffmpeg -encoders \| grep h264_videotoolbox` |
   | Specific URLs fail | Geo-restricted, age-restricted, or removed | Try URL in browser |
   | Intermittent failures | Race condition in FileStorage | Check `self._lock` usage in `file_storage.py` |

6. **Examine one failing project's artifacts**:
   ```bash
   ls -la downloads/$PROJECT_ID/
   cat downloads/$PROJECT_ID/project.json | python3 -m json.tool
   # Check audio.wav duration if it exists:
   ffprobe -v quiet -show_entries format=duration -of csv=p=0 downloads/$PROJECT_ID/audio.wav
   ```

7. **Temp mitigation** — if urgent (Sev1):
   - OOM: `sed -i 's/whisper_model=.*/whisper_model=tiny/' .env` then restart
   - Groq down: switch LLM provider, or fall back to `HighlightService` (density-based)
   - yt-dlp: add `--cookies-from-browser firefox` or update yt-dlp: `pip install -U yt-dlp`

## Verification
- Root cause identified and documented
- Reproduced locally with same input
- Temporary mitigation applied if Sev1
- Post-mortem entry created

## Rollback (if caused by code change)
```bash
git revert HEAD --no-edit
pkill -f "uvicorn" && nohup uvicorn app.main:app --host 0.0.0.0 --port 9999 &
```
