# MediaPipe BlazeFace Reference

## Model File
- `blaze_face_short_range.tflite` at repo root (committed to VCS)
- Short-range model: detects faces up to ~2m from camera
- No long-range model needed (podcast/talking-heads are close)

## Initialization
```python
from mediapipe.tasks.python.vision import FaceDetector, FaceDetectorOptions, RunningMode
from mediapipe.tasks.python.core.base_options import BaseOptions

opts = FaceDetectorOptions(
    base_options=BaseOptions(model_asset_path="blaze_face_short_range.tflite"),
    running_mode=RunningMode.IMAGE,
    min_detection_confidence=0.5,
)
detector = FaceDetector.create_from_options(opts)
```
- Singleton pattern: loaded once per process (`_get_detector()`)
- `min_detection_confidence=0.5` — balances recall vs false positives

## Detection
```python
from mediapipe import Image as MpImage, ImageFormat

rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
result = detector.detect(MpImage(ImageFormat.SRGB, rgb))

for detection in result.detections:
    bbox = detection.bounding_box  # origin_x, origin_y, width, height
    score = detection.categories[0].score  # confidence
```

## FaceBox Dataclass
```python
@dataclass
class FaceBox:
    x: float    # center X normalized (0-1)
    y: float    # center Y normalized (0-1)
    w: float    # width normalized
    h: float    # height normalized
    score: float
```

## Sampling Strategy
- Up to 30 frames evenly spaced across highlight duration
- Picks largest face by area (`w * h`) as dominant subject
- One face box per clip (no per-frame tracking)
