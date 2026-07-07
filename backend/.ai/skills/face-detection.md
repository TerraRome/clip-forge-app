# MediaPipe BlazeFace Face Detection

## Description
Use MediaPipe's BlazeFace model via the Python `mediapipe` library to detect faces in video keyframes. In ClipForge, this drives smart-cropping: the detected face position anchors the 9:16 crop window so the speaker stays centered in vertical format.

## When to Use
- Implementing or debugging face detection in the pipeline
- Tuning detection confidence for different video types (talking head, group, interview)
- Adding per-frame face tracking (vs. current per-clip sampling)
- Switching between BlazeFace short-range and full-range models

## Inputs
- `video_path: str` — path to source MP4
- `highlight_start, highlight_end: float` — time window to analyze (seconds)
- `video_width, video_height: int` — source video pixel dimensions
- `max_frames: int` (default 30) — number of evenly-spaced frames to sample

## Outputs
- `FaceBox(x, y, w, h, score)` with normalized coordinates (0-1 range) or None

## Steps

1. **Load BlazeFace model** — MediaPipe Tasks Vision `FaceDetector`. Model file `blaze_face_short_range.tflite` at project root. Initialize once and cache globally (module-level singleton via `_get_detector()`). This prevents reloading the ~200KB model on every clip.

2. **Open video with OpenCV** — `cv2.VideoCapture(video_path)`. Get FPS: `cap.get(cv2.CAP_PROP_FPS)` (default 30 if unavailable). Calculate sample positions: evenly spaced across `[highlight_start, highlight_end]`. Sample count = `clamp(5, min(duration, max_frames))`.

3. **Sample frames** — for each position, seek with `cap.set(cv2.CAP_PROP_POS_FRAMES, int(ts * fps))`, read frame with `cap.read()`. Convert BGR to RGB (MediaPipe expects RGB). Call `detector.detect(MpImage(ImageFormat.SRGB, rgb))`. Collect all `Detection` bounding boxes.

4. **Select dominant face** — convert each detection to `FaceBox`: center `(x, y)`, size `(w, h)`, and `score` all normalized 0-1. Pick the face with the largest `w * h` (closest to camera, likely the main speaker). Log selection: center coords, size, confidence, frames sampled, total detections.

5. **Handle no-face case** — if no detections across all sampled frames, log `"no_faces_detected_in_highlight"` with clip duration and frame count, return `None`. SmartCropService will fall back to center-crop.

6. **Release resources** — call `cap.release()` in all exit paths (success, partial success, error). Use try/finally if needed.

## Example

```python
cap = cv2.VideoCapture(video_path)
fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
duration = highlight_end - highlight_start
sample_count = max(5, min(int(duration), max_frames))
all_faces = []
for i in range(sample_count):
    ts = highlight_start + (duration * i / max(sample_count - 1, 1))
    cap.set(cv2.CAP_PROP_POS_FRAMES, int(ts * fps))
    ret, frame = cap.read()
    if not ret: continue
    result = detector.detect(MpImage(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)))
    for d in result.detections:
        b = d.bounding_box
        all_faces.append(FaceBox(x=b.origin_x/video_width, y=b.origin_y/video_height, w=b.width/video_width, h=b.height/video_height, score=...))
cap.release()
return max(all_faces, key=lambda f: f.w * f.h) if all_faces else None
```

## Notes
- BlazeFace short-range handles faces up to ~2m from camera (talking head distance). Use `blaze_face_full_range.tflite` for smaller/distant faces.
- `min_detection_confidence=0.5` works for frontal or near-frontal faces. Lower to 0.3 for profile/partial faces, raise to 0.7 for high-precision (fewer false positives).
- All coordinates normalized 0-1 relative to source VIDEO dimensions, not output 1080x1920. `SmartCropService` handles the transform.
- OpenCV is used only for frame seeking/decoding — it's faster than subprocess FFmpeg for random frame access. Do NOT use OpenCV for encoding.
- Model file `blaze_face_short_range.tflite` ships with `mediapipe`. If missing, install with `pip install mediapipe`.
