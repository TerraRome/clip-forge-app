# Video Analysis Pipeline Step

## Description
Analyze a downloaded video to extract metadata, transcribe audio, detect faces, and select highlights. This is the core content understanding phase of the ClipForge pipeline, executed between download and rendering.

## When to Use
- Implementing or modifying the analysis phase of the pipeline
- Adding a new analysis step (scene detection, speaker diarization, sentiment analysis)
- Debugging why transcription, highlights, or face detection produces bad results
- Optimizing analysis step order or parallelism

## Inputs
- `video_path: str` — path to downloaded MP4
- `project_id: str` — for progress tracking context
- Optional: language code (default `"id"` for Indonesian, matching Whisper config)
- `num_clips: int` — how many highlights to select

## Outputs
- Video metadata (dimensions, duration, fps, codec)
- Transcribed segments: `list[TranscriptSegment]` with `start`, `end`, `text`
- Highlights: `list[HighlightSegment]` with `start`, `end`, `score`
- Dominant face position per highlight (or None for fallback center-crop)

## Steps

1. **Extract video info** via `VideoService.get_info()` (ffprobe). Get width, height, duration, rotation, FPS. Handle rotated videos (90/270 degree rotation metadata means swap width/height). Log dimensions for downstream crop computation.

2. **Extract audio** to 16kHz mono WAV: `ffmpeg -y -i video.mp4 -vn -acodec pcm_s16le -ar 16000 -ac 1 audio.wav`. This format is required by Whisper. Check output file exists and has non-zero size.

3. **Transcribe audio** with Whisper: `model.transcribe(audio_path, language="id")`. Returns segments with start/end/timestamp. If word-level subtitles (word_pop/karaoke) are needed, pass `word_timestamps=True`. Log segment count and audio duration coverage percentage.

4. **Select highlights** — primary path: `LLMHighlightService.detect(segments, total_duration, num_clips)`. Fallback path: `HighlightService.detect()` (word-density sliding window). Validate each highlight: within video duration, non-overlapping, 20-60s long (clamped). Log highlight count and total coverage.

5. **Detect faces per highlight** via `FaceService.detect_dominant_face()`. Sample up to 30 frames across each highlight window. Returns the largest-detected-face bounding box or None. Face result drives smart-crop positioning.

6. **Track progress** after each step via `storage.update(project_id, progress=N.n)`. Typical weights: extract audio 5%→20%, transcribe 20%→50%, highlights 50%→65%, face detection per clip 65%→70% (total varies with clip count).

## Example

```python
# In pipeline.py
info = video_svc.get_info(video_path)
video_stream = _find_video_stream(info)
video_width, video_height = video_stream["width"], video_stream["height"]
total_duration = float(info["format"]["duration"])
segments = transcript_svc.transcribe(audio_path)
highlights = highlight_svc.detect(segments, total_duration, num_clips)
for hl in highlights:
    face = face_svc.detect_dominant_face(video_path, hl.start, hl.end, video_width, video_height)
    crop_filter = crop_svc.compute_filter(face, video_width, video_height)
```

## Notes
- Analysis and rendering should be separate phases — analysis is CPU/GPU-light (inference), rendering is GPU-heavy. Running them together risks GPU OOM on resource-constrained systems.
- Whisper `base` model runs ~6x realtime. `large` runs ~0.5x realtime. Set `whisper_model` in config accordingly. Indonesian transcription accuracy is good with `base` due to simpler phonetics.
- LLM highlight detection requires network access to Groq API. If API is down or returns invalid results, the energy-based `HighlightService` fallback guarantees clips are always produced.
- Face detection is per-clip (not per-video) because the dominant speaker may change between highlight windows.
