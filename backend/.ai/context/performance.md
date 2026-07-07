# Performance Characteristics

## GPU Acceleration
- **VideoToolbox** (`h264_videotoolbox`): macOS hardware encoder for H.264
- Flag: `-hwaccel videotoolbox` for decode, `-c:v h264_videotoolbox` for encode
- 5 Mbps target bitrate — good quality for 1080p@30 vertical video
- No NVENC/VAAPI currently (macOS only)

## Bottlenecks
1. **Whisper transcription**: CPU-bound, O(n) on audio length. `base` model ~2x realtime on M1.
2. **FFmpeg rendering**: GPU-bound for encode, CPU for subtitle burn-in + scaling. ~1 clip/minute per core.
3. **Face detection**: MediaPipe on CPU. 30 frames sampled per clip, ~50ms/frame.

## Current Optimizations

### Smart Crop
- Face detection only runs once per clip (not per-frame)
- Samples up to 30 frames evenly across highlight duration
- Crop stays fixed for whole clip (no dynamic tracking)

### Rendering
- Single-pass ffmpeg: crop, scale, subtitle burn-in, encode in one filter graph
- No intermediate file writes between processing stages

### Concurrency
- Pipeline runs sequentially per project (single-threaded)
- No parallel clip rendering (simplicity over throughput)

## Future Optimizations
- **faster-whisper**: 4x speedup over openai-whisper via CTranslate2 + INT8
- **Model quantization**: ONNX Runtime + INT8 for MediaPipe
- **Parallel clip rendering**: ProcessPoolExecutor for independent clips
- **GPU whisper**: Whisper on MPS (Metal Performance Shaders) — experimental
