# ONNX Runtime Reference

## Not Currently Used
No ONNX models in the pipeline. MediaPipe uses TFLite directly.

## Future Optimization Pattern
```python
import onnxruntime as ort

# CPU provider (default)
session = ort.InferenceSession("model.onnx")

# GPU provider (CUDA)
session = ort.InferenceSession("model.onnx", providers=["CUDAExecutionProvider", "CPUExecutionProvider"])

# INT8 quantized inference
input_name = session.get_inputs()[0].name
output_name = session.get_outputs()[0].name
result = session.run([output_name], {input_name: input_array})
```

## Potential Applications
- Faster-whisper (uses CTranslate2, not ONNX Runtime)
- MediaPipe BlazeFace export (not needed — TFLite Runtime handles it)
- Custom classification model for highlight scoring (not implemented)

## When to Use
- Replace openai-whisper with faster-whisper (CTranslate2, not ONNX)
- Export MediaPipe model to ONNX for cross-platform consistency
- Quantize any future ML model to INT8 for CPU inference speedup
