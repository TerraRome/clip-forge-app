# Debug Pipeline Issues

## Description
Debug common failures across the ClipForge pipeline systematically: FFmpeg crashes, Whisper transcription errors, face detection misses, rendering artifacts, and subtitle sync issues. Use project JSON state, service logs, and standalone service invocation to isolate problems.

## When to Use
- Pipeline crashes at a specific step (status=ERROR)
- Rendered clips have visual artifacts (wrong crop, missing subtitles, green frames, wrong duration)
- Face detection returns None when faces clearly visible in source
- Subtitles are out of sync or garbled characters
- FFmpeg returns non-zero exit code

## Inputs
- Project ID (to retrieve state JSON, logs, and output paths)
- Pipeline step where failure occurs
- Error message from project JSON or stderr
- FFmpeg command that failed

## Steps

### 1. Check project state
Open `downloads/_projects/<id>.json`. The `error_message` field contains the root cause. The `progress` field tells which step failed: 5%=download, 20%=audio extract, 50%=transcribe, 65%=highlights, 70-100%=rendering.

### 2. Reproduce the service standalone
Run the failing service outside the pipeline context. Example: `python -c "from app.services.video_service import VideoService; VideoService().download('https://youtube.com/...', '/tmp/test.mp4')"`. This isolates whether the issue is in the service or the pipeline orchestration.

### 3. Fix FFmpeg failures
Check stderr for: `No such file or directory` (bad path), `Invalid argument` (bad filter params), `Codec not supported` (missing hw encoder). Test the filter chain standalone: `ffmpeg -i input -vf "filter" -t 10 -f null -`. Remove ASS filter first, add it back. Verify encoder availability: `ffmpeg -encoders | grep videotoolbox`.

### 4. Fix Whisper failures
Verify audio exists and is valid 16kHz mono: `ffprobe -show_streams audio.wav`. Check audio has content (not silence): `ffmpeg -i audio.wav -af "volumedetect" -f null -`. If OOM, reduce `whisper_model` in config or force CPU: `device="cpu"`. If transcription empty, confirm language param is correct.

### 5. Fix face detection issues
Check `cv2.VideoCapture` can decode frames at the target timestamps. Lower `min_detection_confidence` from 0.5 to 0.3. Increase `max_frames` from 30 to 60 for short clips. Ensure `blaze_face_short_range.tflite` exists at the expected path. Test with a known face image directly via MediaPipe.

### 6. Fix subtitle timing drift
Check whether `-ss` is before (fast seek, keyframe accuracy) or after (frame-accurate) `-i`. Current code uses input seeking, which can drift ~2s. Fix: add `-ss` after `-i` for frame-accurate seek. Verify ASS timestamps are relative to clip start. Re-transcribe with `word_timestamps=True` and check per-word alignment.

## Example

```bash
# Test FFmpeg filter chain standalone
ffmpeg -y -ss 30 -i source.mp4 -t 10 \
  -vf "scale=1920:1920,crop=1080:1920:420:0,ass=subs.ass" \
  -c:v libx264 -preset ultrafast test_output.mp4

# Check audio validity
ffprobe -show_streams audio.wav | grep -E "sample_rate|channels"

# Run face detection test
python -c "
from app.services.face_service import FaceService
f = FaceService().detect_dominant_face('video.mp4', 30, 60, 1920, 1080)
print(f)
"
```

## Notes
- Enable FFmpeg debug: add `-loglevel debug` to see filter graph details and frame timestamps.
- For timing issues, log `time.perf_counter()` before/after each pipeline step to identify slow operations.
- Common issues table: yt-dlp 403 (update yt-dlp, add cookies), Whisper OOM (use smaller model), LLM timeout (check API key + Groq status), ASS errors (validate file independently with `ffmpeg -f ass -i file.ass`), pipeline never completes (check `storage._lock` deadlock).
- When debugging, add temporary `logger.info("debug_var", value=variable)` rather than using pdb — structlog output is easier to review from threaded/Celery context.
