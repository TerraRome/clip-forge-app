# AI Pipeline

## Purpose

ClipForge's AI pipeline transforms a raw YouTube video into editorial highlight clips. It chains four AI models — Whisper, LLM, MediaPipe BlazeFace, and heuristic scene analysis — to select engaging moments, compose vertical shots, and render subtitled shorts.

## Pipeline Stages

```
YouTube URL
    │
    ▼
┌──────────────────────┐
│  1. Speech-to-Text   │  ← Whisper (base/small/medium)
│  (TranscriptService) │     16kHz mono PCM → text segments
└──────────┬───────────┘
           ▼
┌──────────────────────┐
│  2. Highlight Detect │  ← LLM (Groq) with heuristic fallback
│  (LLMHighlightService│     Transcript → timestamped clips
│   + HighlightService)│
└──────────┬───────────┘
           ▼
┌──────────────────────┐
│  3. Face Detection   │  ← MediaPipe BlazeFace
│  (FaceService)       │     Keyframe sampling → dominant face
└──────────┬───────────┘
           ▼
┌──────────────────────┐
│  4. Smart Crop       │  ← Geometric computation
│  (SmartCropService)  │     Face center → FFmpeg crop filter
└──────────┬───────────┘
           ▼
    Finished 9:16 Clip
```

## Stage 1: Whisper Transcription

`TranscriptService` loads OpenAI Whisper model at startup (default: `base`, 74M params). Audio must be 16kHz mono PCM — converted by FFmpeg before transcription.

**Configuration:**
- Model size: `settings.whisper_model` (base | small | medium | large)
- Language: Indonesian (`language="id"`). Hardcoded for the target market.

**Output:** `list[TranscriptSegment]` — each with `start_sec`, `end_sec`, `text`.

**Performance:** Base model transcribes at ~5x realtime on CPU. GPU (CUDA) accelerates to ~20x realtime. Large model is ~10x slower — only used for high-accuracy requirements.

**Future:** Segments will include per-word timestamps for all presets (currently re-transcribed in `subtitle_service.py` for word_pop/karaoke via a separate Whisper call with `word_timestamps=True`).

## Stage 2: LLM Highlight Detection

`LLMHighlightService` sends the full transcript to a Groq-hosted LLM (`llama-3.3-70b-versatile`) with a system prompt defining rules for highlight selection.

**System Prompt Rules:**
- Each clip must be 20-60 seconds.
- Prioritize: emotional peaks, surprising revelations, strong opinions, punchlines, hooks.
- Return JSON array: `[{"start": float, "end": float, "reason": string}]`
- No overlapping clips.
- Sorted ascending by start time.

**LLM Call:**
- Temperature: 0.3 (low creativity, consistent selection).
- Max tokens: 1024.
- Timeout: 60 seconds.
- Model: `settings.llm_model` (configurable for different providers).

**Fallback Chain:**
1. Parse LLM JSON response. Filter clips <10s or >120s. Clamp to 60s max.
2. Deduplicate overlaps (keep higher-priority earlier in response).
3. On any failure (JSON parse error, empty response, API timeout): fall back to heuristic `HighlightService`.

**Heuristic Fallback** (`HighlightService`):
- Builds a per-second word-density timeline from transcript segments.
- Slides a 60-second window across the timeline, scoring each position by words-per-second density.
- Selects top N non-overlapping windows by score.
- If no highlights found: evenly-spaced fallback segments as a last resort.

**Future:** Rerank LLM candidates with a secondary model (e.g., audience engagement prediction). Add user-provided topics/keywords for personalized highlights.

## Stage 3: Face Detection

`FaceService` uses MediaPipe's BlazeFace model (`blaze_face_short_range.tflite`) to detect faces in video keyframes.

**Sampling Strategy:**
- Samples 5-30 evenly-spaced frames within each highlight window. Coverage heuristic: `max(5, min(highlight_duration, 30))`.
- Skips frames where `cap.read()` fails (corrupt frames at seek boundaries).

**Selection:**
- Collects all detected faces across all sampled frames.
- Picks the largest face by bounding box area (`w * h`) — assumes the dominant speaker is closest to camera.
- Returns normalized coordinates (0-1 range) as `FaceBox` or `None` if no face.

**Performance:** ~5ms per frame on GPU, ~20ms on CPU. 30 frames = ~150ms per highlight window. Negligible compared to transcription/render.

**Model:** BlazeFace short-range (TFLite, ~200KB). Optimized for frontal faces within 2 meters. Long-range model available for distant faces.

## Stage 4: Smart Crop

`SmartCropService` is a pure geometric computation — no ML. It computes an FFmpeg filter string that:
1. Scales the source to fill 1080x1920 canvas while preserving aspect ratio.
2. Crops a 9:16 region centered on the detected face, or center-of-frame if no face.

**Algorithm:**
- If source aspect ratio > 9:16 (landscape): scale height to 1920, width overflows. Center crop horizontally on face X.
- If source aspect ratio < 9:16 (portrait): scale width to 1080, height overflows. Center crop vertically on face Y.
- Face X/Y are denormalized from relative (0-1) to scaled coordinates, then crop position is clamped to valid range.

## Integration Notes

- Face detection and smart crop run **per highlight clip** (not once for the whole video). This accounts for speaker changes between clips.
- Each clip gets its own ASS subtitle file generated from the transcript segments that overlap the highlight window.
- The crop filter and ASS file path are passed to FFmpeg in a single `-vf` chain.
