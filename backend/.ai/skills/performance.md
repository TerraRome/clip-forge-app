# Performance Optimization: GPU Encoding, Parallel Processing, Caching

## Description
Optimize the ClipForge rendering pipeline for speed and resource efficiency. The pipeline has three major cost centers: Whisper transcription (CPU), face detection (CPU), and FFmpeg rendering (GPU or CPU encoding). Each can be optimized independently for 2-4x throughput improvement.

## When to Use
- Pipeline takes too long (>10 minutes for a 30-minute video)
- GPU is underutilized during rendering
- CPU is maxed out during transcription, starving other processes
- Multiple clips rendered sequentially when they could be parallel
- Out of memory (GPU or RAM) during Whisper + MediaPipe overlap

## Inputs
- Current pipeline execution times per step (from timing logs)
- Available hardware (GPU model, CPU cores, RAM, disk type)
- Pipeline configuration (model sizes, encoder settings, parallelism config)

## Outputs
- Configuration changes (model sizes, batch sizes, encoder selection)
- Code changes (parallel clip rendering, caching intermediate results, lazy model loading)

## Steps

### 1. Profile before optimizing
Wrap each pipeline step with `time.perf_counter()`. Log step durations at INFO level. Typical breakdown: Whisper 40-60%, FFmpeg rendering 30-40%, face detection 5-10%, I/O 5%. Focus on the biggest bottleneck.

### 2. Optimize Whisper transcription
Use the smallest model that meets accuracy needs. `base` (142MB) for Indonesian podcasts. `tiny` (75MB) for testing/iteration. Enable `fp16=True` on GPU for 2x speedup. On CPU, force `fp16=False`. For videos >30min, split audio into 10min chunks and transcribe in parallel with `ThreadPoolExecutor`. Consider `faster-whisper` as a drop-in replacement for 3-4x speedup.

### 3. Reduce face detection overhead
Decrease `max_frames` from 30 to 10-15 for static talking-head content. Skip face detection entirely if video is solo talking head (detect once per video, reuse for all clips). Enable MediaPipe GPU delegate: `BaseOptions(..., delegate=Delegate.GPU)` for ~5x speedup.

### 4. Parallelize clip rendering
Render clips concurrently with `ThreadPoolExecutor(max_workers=min(num_clips, os.cpu_count()//2))`. Each FFmpeg process is independent (separate `-ss -t` on the same input file) and doesn't GIL-contend. Use `as_completed()` to update progress as each finishes. Hardware encoders (`h264_videotoolbox`) on Apple Silicon can run 4+ parallel encodes without contention.

### 5. Optimize FFmpeg encoding
Hardware encoders: macOS `h264_videotoolbox`, Linux NVIDIA `h264_nvenc`, Linux Intel `h264_qsv`. Software `libx264` is 5-10x slower. Increase `-b:v` to 8000-10000k when using hardware encoders (they produce lower quality per bitrate). Add `-tag:v avc1 -profile:v high -level:v 4.2` for broad device compatibility.

### 6. Cache intermediate results
Cache transcription: save segments JSON alongside video file, reuse on re-runs. Cache face detection: save per-clip face boxes, invalidate only when highlight boundaries change. Use simple file-based cache: `Path(cache_path).write_text(json.dumps(result))`. Clean up audio temp files after transcription.

## Example

```python
from concurrent.futures import ThreadPoolExecutor, as_completed
import os

def render_all_clips(render_svc, video_path, segments, highlights, crop_filters, output_dir):
    clip_paths = []
    with ThreadPoolExecutor(max_workers=min(len(highlights), max(2, os.cpu_count() // 2))) as pool:
        futures = {}
        for i, hl in enumerate(highlights):
            out = str(Path(output_dir) / f"clip_{i+1:02d}.mp4")
            f = pool.submit(render_svc.render_clip, video_path, segments, hl, out, ...)
            futures[f] = i
        for f in as_completed(futures):
            clip_paths.append(f.result())
    return clip_paths
```

## Notes
- The current pipeline is single-threaded. Parallel rendering is the highest-impact optimization (~3x speedup for 3 clips).
- GPU VRAM is the critical bottleneck. Whisper + MediaPipe both use GPU by default. Unload Whisper model (`del model`) before face detection or render steps.
- `h264_videotoolbox` on Apple Silicon uses the Media Engine (separate from GPU cores), so it doesn't contend with other GPU tasks.
- For very high throughput, split into Celery queues: one `transcription` worker (CPU-optimized), one `rendering` worker (GPU-optimized).
- Monitor with: `nvidia-smi` (GPU), `htop` (CPU), `iostat` (disk), `vmmap` (macOS memory).
