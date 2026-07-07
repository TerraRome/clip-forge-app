# Performance

## Purpose

ClipForge processes video on a per-request SaaS model. Users expect clips ready within 3-5 minutes for a 20-minute source video. This document covers performance targets, GPU acceleration strategy, caching decisions, and batch processing patterns to meet those targets.

## Performance Targets

| Metric | Current (MVP) | Target (Production) | Measurement |
|---|---|---|---|
| Pipeline completion (20-min video, 3 clips) | ~5-8 min | <3 min | Wall clock, project creation to DONE |
| Whisper transcription (20-min audio) | ~2-4 min (base CPU) | <30s (medium GPU) | `time` CLI |
| FFmpeg render per clip (60s, 1080p) | ~15-30s (VT) | <10s (NVENC) | Render subprocess duration |
| API response (poll) | <10ms | <5ms | 95th percentile |
| Peak concurrent projects | 1 (single thread) | 20 (Celery worker pool) | Worker queue depth |
| GPU utilization | N/A (macOS) | >70% | `nvidia-smi` |

## GPU Acceleration Strategy

### Current: macOS Videotoolbox

```bash
-hwaccel videotoolbox
-c:v h264_videotoolbox
```

Performance is sufficient for development but not horizontally scalable. The VideoToolbox encoder is limited to 1-2 concurrent encodes on Apple Silicon.

### Target: NVIDIA NVENC

```bash
-hwaccel cuda -hwaccel_output_format cuda
-c:v h264_nvenc -preset p4 -b:v 5000k
```

**NVENC Benefits:**
- Dedicated hardware encoder chip — does not compete with CUDA cores used by Whisper.
- Up to 8 concurrent 1080p encodes on RTX 4090.
- ~5x faster than software `libx264`.
- `preset p4` balances quality (PSNR ~46dB) and speed.

### GPU Memory Budget

| Component | VRAM Estimate |
|---|---|
| Whisper `medium` (FP16) | ~2.5GB |
| FFmpeg NVENC encode (per stream) | ~0.3GB |
| FFmpeg decode buffer (per stream) | ~0.5GB |
| MediaPipe BlazeFace | ~0.1GB |
| OS + overhead | ~1GB |
| **Total per GPU worker** | **~5GB** |

A 16GB GPU (RTX 4060 Ti) can run one Whisper instance + 2 concurrent renders. An 80GB GPU (A100) can run 4 Whisper instances + 12 renders.

## Whisper Model Optimization

### Model Size Selection

| Model | Speed (relative) | WER (Indonesian) | RAM | Use Case |
|---|---|---|---|---|
| `base` | 1x (baseline) | ~15% | 1GB | Dev, short clips |
| `small` | 0.6x | ~10% | 2GB | Staging |
| `medium` | 0.25x | ~7% | 5GB | Production quality |
| `large-v3` | 0.1x | ~5% | 10GB | High-accuracy only |

### FP16 Inference

Whisper on GPU with FP16 (half precision) is ~2x faster than FP32 with negligible accuracy loss:

```python
import whisper
model = whisper.load_model("medium")
# whisper automatically uses FP16 on CUDA devices
result = model.transcribe(audio, fp16=True)
```

The `fp16` flag defaults to `True` on CUDA. Disabled explicitly (`fp16=False`) only in `_get_word_timestamps()` for re-transcription where CPU-only execution is expected.

### Batch Processing

Whisper's native batch size is 1 (sequential segments). Future: Pad audio to fixed windows and use `model.transcribe(batch_size=4)` for ~3x throughput on GPU.

## Caching Strategy

### Whisper Model Cache

Whisper downloads models to `~/.cache/whisper/` on first use. Subsequent loads are instant. The model stays in memory once loaded — `TranscriptService` keeps a reference.

```python
class TranscriptService:
    def __init__(self, model_name: str = "base"):
        self._model = whisper.load_model(model_name)  # cached by whisper internally
```

### FFmpeg Binary Cache

The bundled `./ffmpeg_bin` is a static binary. No cache needed.

### Result Cache (Future)

For repeated processing of the same YouTube URL (common during development), cache:
- Download path: `downloads/{video_id}/source.mp4`. Check existence before re-download.
- Transcript segments: Store in PostgreSQL `transcript_segments` table. Reuse if cached.
- Highlight selections: Cache LLM response for identical transcript + num_clips.

```python
@celery_app.task
def download_video(project_id, url):
    video_id = extract_video_id(url)
    cached_path = Path(settings.downloads_dir) / "cache" / f"{video_id}.mp4"
    if cached_path.exists():
        return str(cached_path)  # skip re-download
    # ... download to cached_path
```

## Concurrency Model

### Current (MVP)

- Single pipeline thread per project.
- Sequential processing: download → transcribe → render (one clip at a time).
- No parallelism within a project.
- Total throughput: ~2-3 projects/hour.

### Target (Production)

- Celery worker pool: GPU workers (2), CPU workers (4), IO workers (8).
- Video download: runs on IO worker, frees CPU/GPU for active projects.
- Per-project parallelism: Render all clips in parallel via Celery chord.
- Total throughput: ~20-30 projects/hour on a single GPU host.

**Clip-level parallelism**
```
Current:  render_clip_1 → render_clip_2 → render_clip_3  (sequential)
Target:   render_clip_1, render_clip_2, render_clip_3      (parallel, 3x speedup)
```

Parallel render requires sufficient GPU memory for concurrent FFmpeg processes.

## Bottleneck Analysis

| Stage | % of Total Time (MVP) | Bottleneck Type | Mitigation |
|---|---|---|---|
| Download | 40% | Network I/O | Resumable downloads, CDN caching |
| Audio Extract | 5% | Disk I/O | Fast NVMe storage |
| Transcription | 30% | CPU/GPU compute | GPU + FP16 + larger batch |
| Highlight LLM | 5% | Network I/O (API) | Local model (future) |
| Face Detect | 2% | CPU compute | Minimal impact |
| Render (per clip) | 18% | GPU encode | Parallelize across clips |

## Monitoring

Key performance metrics to monitor in production:

- **Pipeline duration**: 95th percentile per project. Alert if >10 min.
- **Whisper transcription ratio**: Real-time factor (RTF). Target <0.1 (10x realtime).
- **Render FPS**: FFmpeg output FPS. Target >60 for 30fps source (2x realtime).
- **GPU utilization**: `nvidia-smi` query. Alert if <30%.
- **Queue depth**: Celery queue backlog. Scale workers when >50 pending.

## Best Practices

1. **Profile before optimizing**: Use `cProfile` on Python code, `ffmpeg -benchmark` on renders. The download step is usually the bottleneck — adding GPU workers won't help.
2. **FFmpeg thread tuning**: `-threads auto` or pinned to `-threads N` where N = CPU cores / concurrent encodes.
3. **I/O isolation**: Download directory on separate SSD from OS. Avoids I/O contention.
4. **Garbage collection**: Whisper and MediaPipe hold significant Python objects. Call `gc.collect()` between pipeline projects in long-running workers.
5. **Connection reuse**: OpenAI SDK reuses HTTP connections for LLM calls. No reconnection overhead.
