# AI/ML Pipeline Overview

## Models Used

| Model/Service | Task | Integration | Performance Notes |
|---------------|------|-------------|-------------------|
| **Whisper API** (OpenAI) | Speech-to-text | HTTP API (OpenAI client) | ~30s for 10min audio. Cost: ~$0.006/min. Fallback: none (critical). |
| **GPT-4o-mini** (OpenAI) | Highlight detection from transcript | HTTP API (OpenAI client) | ~2s response. Cost: negligible. Fallback: energy-based algorithm. |
| **MediaPipe Face Detection** | Face bounding boxes for smart crop | Python package (mediapipe) | ~50ms/frame. Lightweight. Fallback: center crop. |

## Pipeline Flow (AI-relevant steps)
```
                   ┌─────────────┐
                   │  Whisper    │
  video/audio ───> │  API        │ ──> TranscriptSegments[]
                   └─────────────┘
                          │
                          ▼
                   ┌─────────────┐
                   │  GPT-4o-mini│
  transcript ───>  │  (LLM)      │ ──> HighlightSegment[]
                   │  or energy  │
                   └─────────────┘
                          │
                          ▼
                   ┌─────────────┐
                   │  MediaPipe  │
  clip frames ───> │  Face       │ ──> FaceBox (center coords)
                   │  Detection  │
                   └─────────────┘
```

## Performance Characteristics
- **Total pipeline time**: ~2-5x video duration (dominated by FFmpeg render, not AI).
- **Whisper latency**: Network-bound. Batch not needed (single audio stream).
- **LLM latency**: < 2s. Prompt is ~2K tokens (transcript). Response is small JSON.
- **MediaPipe latency**: ~50ms per frame. Only processes keyframes or every Nth frame.

## Graceful Degradation Chain
1. LLM highlight detection fails -> fallback to energy-based (audio amplitude peaks).
2. Face detection fails -> center crop (no smart tracking).
3. Whisper fails -> pipeline cannot proceed (critical path).

## Prompt Engineering
- System prompt instructs GPT-4o-mini to return JSON array of highlight segments.
- Output schema: `[{"start": float, "end": float, "score": float, "reason": string}]`.
- Strict JSON parsing. Invalid response triggers fallback.
