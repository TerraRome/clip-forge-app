# PyTorch Usage (ClipForge)

## Current Usage: Minimal
Whisper uses PyTorch internally but ClipForge doesn't directly interact with it.

## Whisper's PyTorch Dependencies
- `openai-whisper` installs PyTorch as a dependency
- Model weights loaded via `torch.load()` → `model.eval()`
- Inference on CPU by default (no CUDA/MPS configured)
- `fp16=False` passed to `model.transcribe()` when word timestamps needed

## Potential Direct Usage
```python
import torch

# Check device availability
device = "cuda" if torch.cuda.is_available() else "mps" if torch.backends.mps.is_available() else "cpu"
```

## When to Use Directly
- ONNX export of MediaPipe model (not needed — TFLite already optimized)
- Custom PyTorch model fine-tuning (not planned)
- Batch inference optimization (not needed — single video pipeline)

## Current Limitations
- No GPU utilization for whisper (CPU-only)
- No model quantization
- No half-precision inference (`fp16=False` forced for word timestamps)
