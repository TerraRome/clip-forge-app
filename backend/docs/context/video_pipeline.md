# Video Processing Pipeline

## Purpose

The video processing pipeline handles raw video acquisition, inspection, and preparation. It is the first stage of the ClipForge workflow, converting a YouTube URL into a local MP4 file with known dimensions, duration, and an extracted 16kHz audio track for downstream AI processing.

## Pipeline Steps

### 1. Download — `VideoService.download()`

Uses yt-dlp (command-line via `subprocess.run`) to download the best available stream.

**Command:**
```python
cmd = [
    "python3", "-m", "yt_dlp",
    "-f", "bestvideo[height<=1080]+bestaudio/best[height<=1080]",
    "--merge-output-format", "mp4",
    "--ffmpeg-location", settings.ffmpeg_path,
    "--no-warnings",
    "--extractor-args", "youtube:player_client=android",
    "-o", str(path),
    url,
]
```

**Format Selection:** `bestvideo[height<=1080]+bestaudio/best[height<=1080]`

- Downloads best video stream at 1080p or below (prevents massive 4K downloads for vertical shorts).
- Merges best audio stream into output via ffmpeg.
- Falls back to best combined format if no separate streams available.

**Extractor Args:** `youtube:player_client=android` — uses Android client which has fewer restrictions and is less likely to be rate-limited. Avoids the heavy `--extractor-args youtube:player_client=web` which often triggers bot detection.

**Timeout:** 600 seconds (10 minutes). YouTube downloads of 20-30 minute podcasts at 1080p typically complete in 2-5 minutes.

**Error Handling:**
- Filters out benign warnings (`NotOpenSSLWarning`, `Deprecated Feature`, `urllib3` warnings) from stderr.
- Returns stderr only on non-zero exit codes with actual errors.
- Raises `RuntimeError` with extracted error text.

**Output:** MP4 file at `{project_dir}/source.mp4`.

### 2. Audio Extraction — `VideoService.extract_audio()`

Uses FFmpeg to extract audio from the downloaded video, converting to the format required by Whisper.

**Command:**
```python
cmd = [
    settings.ffmpeg_path, "-y",
    "-i", video_path,
    "-vn",                          # No video
    "-acodec", "pcm_s16le",         # 16-bit PCM
    "-ar", "16000",                 # 16kHz sample rate
    "-ac", "1",                     # Mono
    str(audio_path),
]
```

**Why 16kHz mono PCM?**
- Whisper models are trained on 16kHz audio. Higher sample rates waste compute.
- Mono reduces data by 50% vs stereo with no accuracy loss for single-speaker podcasts.
- PCM (uncompressed WAV) avoids transcoding artifacts and is fastest to read.
- FFmpeg flag `-y` overwrites without prompt (idempotent).

**Output:** `{project_dir}/audio.wav` — 16-bit, 16kHz, mono WAV.

### 3. Video Inspection — `VideoService.get_info()`

Uses ffprobe to extract video metadata needed for downstream processing.

**Command:**
```python
cmd = [
    settings.ffprobe_path, "-v", "quiet",
    "-print_format", "json",
    "-show_format",
    "-show_streams",
    video_path,
]
```

**Output:** Parsed JSON dict containing:
- `streams`: List of audio/video/subtitle streams. Pipeline selects video stream via `codec_type == "video"`.
- `stream.width`, `stream.height`: Source video dimensions. Used by SmartCropService to compute crop region.
- `format.duration`: Total video duration in seconds. Used to validate highlight boundaries.

**Stream Selection** (`_find_video_stream()` in pipeline.py):
```python
def _find_video_stream(info: dict) -> Optional[dict]:
    for stream in info.get("streams", []):
        if stream.get("codec_type") == "video":
            return stream
    return None
```

Fails with `RuntimeError("No video stream found")` if absent — catches corrupt downloads or non-video URLs.

## Error Handling

| Failure Mode | Detection | Recovery |
|---|---|---|
| Network timeout | `subprocess.TimeoutExpired` (600s) | Retry with backoff (Celery) |
| Video unavailable (private/deleted) | yt-dlp non-zero exit + error stderr | Fail to ERROR. No retry. |
| Corrupt download | ffprobe returns empty JSON or zero streams | Fail to ERROR. Re-download. |
| Audio extraction failure | FFmpeg non-zero exit | Retry once. |
| File system full | FFmpeg/yt-dlp I/O error | Fail to ERROR. Alert ops. |

## Performance

| Step | Typical Duration | Bottleneck |
|---|---|---|
| Download (10-min 1080p) | 2-5 min | Network bandwidth |
| Audio Extraction | 10-30s | Disk I/O |
| Video Inspection | <1s | Fast (metadata only) |

## Future Improvements

- **Resumable downloads**: yt-dlp supports `--continue` for partial downloads. Enable for large files.
- **Adaptive quality**: Check video duration first, then select format. Shorts (<60s) can use lower quality.
- **Playlist support**: Download specific index via yt-dlp playlist syntax. Requires UI changes.
- **Non-YouTube sources**: Abstract downloader interface for TikTok, Instagram, Twitch. Each source implements `download(url, path) -> str`.
