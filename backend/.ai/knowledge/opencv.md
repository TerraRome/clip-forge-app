# OpenCV Usage (ClipForge)

## Face Detection Frame Extraction
```python
import cv2

cap = cv2.VideoCapture(video_path)
fps = cap.get(cv2.CAP_PROP_FPS)

# Seek to specific timestamp
cap.set(cv2.CAP_PROP_POS_FRAMES, int(timestamp * fps))
ret, frame = cap.read()

# Convert BGR to RGB for MediaPipe
rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

cap.release()
```

## Key Points
- Only used for frame extraction + color conversion
- No image processing, no transforms, no filters
- Always release capture: `cap.release()` after use
- Handles frame seeking by frame number (not time) for accuracy

## Limitations
- `cv2.VideoCapture` on macOS may have codec issues
- No GPU acceleration configured (CPU-only decode)
- `CAP_PROP_POS_FRAMES` is approximate for some codecs (seek to nearest keyframe)

## Dependencies
- `opencv-python` (not opencv-contrib-python — vanilla is sufficient)
- Imported in `face_service.py` only
