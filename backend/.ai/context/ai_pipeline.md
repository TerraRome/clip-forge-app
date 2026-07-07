# AI Pipeline: End-to-End Flow

## Stage 1: Download (`VideoService.download`)
- yt-dlp: `bestvideo[height<=1080]+bestaudio/best[height<=1080]`
- Android client for age-restricted content
- Cookie file support (optional)

## Stage 2: Audio Extraction (`VideoService.extract_audio`)
- ffmpeg: PCM s16le, 16kHz, mono (whisper input format)
- Output: `audio.wav` in project directory

## Stage 3: Transcription (`TranscriptService.transcribe`)
- `openai-whisper` (not faster-whisper)
- Language forced to `id` (Indonesian)
- Model size from `settings.whisper_model` (default: `base`)
- Produces `list[TranscriptSegment]` with start/end/text

## Stage 4: Highlight Detection (`LLMHighlightService.detect`)
- Primary: LLM (Groq Llama 3.3 70B) — structured JSON output
- Fallback: word-density sliding window algorithm
- LLM prompt: find 20-60s engaging moments (emotional peaks, hooks, punchlines)
- Response parsed from JSON, overlap deduplicated, sorted by start time

## Stage 5: Smart Crop (`FaceService` + `SmartCropService`)
- MediaPipe BlazeFace short-range: samples up to 30 frames per clip
- Picks largest face bounding box (= closest to camera)
- Centers 1080x1920 output crop on detected face
- Falls back to center-fill if no face found

## Stage 6: Render (`RenderService.render_clip`)
- ffmpeg with `h264_videotoolbox` GPU encoding
- ASS subtitle burn-in (4 presets: classic, tiktok_3words, word_pop, karaoke)
- Output: 1080x1920 @ 5Mbps, AAC 128k, yuv420p, faststart
