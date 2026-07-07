# Add New AI/ML Model To Pipeline

## Context
Integrate a new model into the ClipForge pipeline. Existing models: Whisper (transcription), Groq llama-3.3-70b (highlight detection via LLM), MediaPipe BlazeFace (face detection), SmartCrop (heuristic). New model could be: pyannote/speaker-diarization, YOLO scene detection, sentiment analysis, or aesthetic scoring.

## Prerequisites
- Model identified (HuggingFace, API, or TFLite)
- `requirements.txt` updated (or API client for cloud model)
- Model weights downloaded or API key provisioned
- Baseline metrics: get 3 test videos with known clip outputs

## Steps

1. **Identify integration point** — where in pipeline?
   - Parallel to highlights? (adds dimension to clip selection)
   - Between transcribe and render? (modifies clip content)
   - Pre-processing? (enhances video before crop)
   - Post-processing? (adds metadata/tags to clip)

2. **Implement service** — follow FaceService pattern:
   ```python
   # app/services/scene_service.py
   import structlog
   import cv2
   import numpy as np
   from pathlib import Path
   from typing import Optional
   logger = structlog.get_logger()

   _model = None
   def _get_model():
       global _model
       if _model is None:
           # Lazy-load heavy model once
           import torch
           _model = torch.hub.load('ultralytics/yolov5', 'yolov5s', pretrained=True)
       return _model

   @dataclass
   class SceneChange:
       timestamp: float
       confidence: float

   class SceneService:
       def detect_scenes(self, video_path: str, max_frames: int = 100) -> list[SceneChange]:
           model = _get_model()
           cap = cv2.VideoCapture(video_path)
           fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
           total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
           step = max(1, total // max_frames)
           changes = []
           prev_hist = None
           for i in range(0, total, step):
               cap.set(cv2.CAP_PROP_POS_FRAMES, i)
               ret, frame = cap.read()
               if not ret:
                   break
               hist = cv2.calcHist([cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)], [0], None, [50], [0, 256])
               cv2.normalize(hist, hist)
               if prev_hist is not None:
                   diff = cv2.compareHist(prev_hist, hist, cv2.HISTCMP_CHISQR)
                   if diff > 50:  # threshold
                       changes.append(SceneChange(timestamp=i/fps, confidence=min(diff/100, 1.0)))
               prev_hist = hist
           cap.release()
           return changes
   ```

3. **Wire into pipeline** — `app/worker/pipeline.py`:
   ```python
   from app.services.scene_service import SceneService
   scene_svc = SceneService()
   # Between transcribe and highlights:
   log.info("step_scene_detect")
   scene_changes = scene_svc.detect_scenes(video_path)
   storage.update(project_id, progress=55.0)
   ```

4. **Benchmark latency** — compare with and without:
   ```python
   python3 -c "
   import time
   from app.services.scene_service import SceneService
   svc = SceneService()
   # Warm up
   svc.detect_scenes('tests/fixtures/sample_30s.mp4', max_frames=30)
   # Measure
   t0 = time.time()
   for _ in range(3):
       svc.detect_scenes('tests/fixtures/sample_30s.mp4', max_frames=100)
   avg = (time.time() - t0) / 3
   print(f'Avg: {avg:.2f}s')
   assert avg < 30, 'Too slow for pipeline timeout'
   "
   ```

5. **Optimize** if needed:
   - Reduce `max_frames` sampling rate
   - Use grayscale histograms instead of HSV (3x faster)
   - Skip every Nth frame
   - Use ONNX runtime instead of PyTorch

6. **Handle fallback** — model failure must not crash pipeline:
   ```python
   try:
       scene_changes = scene_svc.detect_scenes(video_path)
   except Exception as e:
       logger.warning("scene_detect_failed_fallback_to_uniform", error=str(e))
       scene_changes = []  # empty = no scene-aware optimization
   ```

## Verification
- Model loads and runs without error
- Pipeline completes within 2x baseline time
- Output clips are not degraded (check 3 test videos)
- Memory usage stable (no leak over 5+ pipeline runs)
- Fallback path works (e.g., delete model file, verify pipeline still completes)

## Rollback
```bash
# Option A: Revert code
git revert HEAD --no-edit
# Option B: Comment out the step in pipeline.py
```
