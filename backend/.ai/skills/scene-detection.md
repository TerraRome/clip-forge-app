# PySceneDetect Scene Boundary Detection

## Description
Use PySceneDetect to find content-aware scene boundaries in a video. Scene cuts mark the best places to clip between highlights, ensuring rendered clips don't start or end mid-shot. When integrated with highlight detection, clip boundaries snap to the nearest scene cut for clean transitions.

## When to Use
- Improving highlight clip boundaries to align with natural scene changes
- Splitting a long video into chapters for navigation or parallel processing
- Filtering out low-activity segments (static frames, black frames) from highlight candidates
- Generating keyframe thumbnails per scene

## Inputs
- `video_path: str` — path to source video
- `detector: str` — "content" (default, HSV histogram diff), "threshold" (fade detection), "adaptive" (gradual transitions)
- `threshold: float` — sensitivity for ContentDetector (lower = more scenes)
- `min_scene_len: float` — minimum scene duration in seconds (filter out spurious cuts)

## Outputs
- `list[tuple[float, float]]` — scene boundaries as `(start_seconds, end_seconds)` tuples

## Steps

1. **Open video and create SceneManager**: `video = open_video(video_path); scene_manager = SceneManager()`. Add detector: `ContentDetector(threshold=27.0)` for standard cuts, `AdaptiveDetector(window_duration=2.0)` for gradual transitions (better for vlog/podcast static shots).

2. **Detect scenes**: `scene_manager.detect_scenes(video)`. Get result with `scene_list = scene_manager.get_scene_list()`. Each entry is `(start_timecode, end_timecode)` as `FrameTimecode` objects.

3. **Convert to seconds**: `[(s.get_seconds(), e.get_seconds()) for s, e in scene_list]`. Filter out scenes shorter than `min_scene_len` (default 2.0s) — these are usually false positives from flashing or rapid camera movement.

4. **Snap highlights to scene boundaries**: for each `HighlightSegment(start, end)`, find nearest scene boundary before `start` (backward snap) and nearest after `end` (forward snap). Snap only within a configurable tolerance (e.g., 5s). Never snap beyond min/max clip duration constraints.

5. **Score scenes for highlightability** — compute average word density per scene. Scenes with no dialog are low-value. Scenes with high word density and longer duration are better candidates. Use this to rank scenes before passing to highlight selection.

## Example

```python
from scenedetect import open_video, SceneManager
from scenedetect.detectors import ContentDetector

video = open_video(video_path)
scene_manager = SceneManager()
scene_manager.add_detector(ContentDetector(threshold=27.0))
scene_manager.detect_scenes(video)
scene_list = scene_manager.get_scene_list()
boundaries = [(s.get_seconds(), e.get_seconds()) for s, e in scene_list if (e.get_seconds() - s.get_seconds()) >= 2.0]

def snap_to_scene(ts: float, boundaries: list, direction: str = "backward") -> float:
    if direction == "backward":
        candidates = [b[1] for b in boundaries if b[1] <= ts]
    else:
        candidates = [b[0] for b in boundaries if b[0] >= ts]
    return min(candidates, key=lambda x: abs(x - ts)) if candidates else ts
```

## Notes
- Not currently integrated in the pipeline. Add as an optional pre-processing step before highlight selection.
- ContentDetector uses HSV histogram differences between consecutive frames. Works well for most content but may false-positive on fast camera movement, flashing, or rapid cuts (music videos).
- For podcast/vlog content with mostly static backgrounds, use `AdaptiveDetector(window_duration=2.0)` — it adapts its threshold to local content and produces fewer false positives on static shots.
- PySceneDetect 0.6+ uses `open_video()` not `VideoManager`. Pin version: `scenedetect[opencv]>=0.6.2`.
- Scene detection is fast (~0.1x realtime for 1080p). Run once per video, not per clip.
