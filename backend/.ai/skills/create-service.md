# Create Service Class

## Description
Create a stateless service class encapsulating a single domain capability. Services wrap external tools/libraries (FFmpeg, Whisper, MediaPipe, yt-dlp) and communicate via typed domain objects. Used throughout the ClipForge pipeline.

## When to Use
- Wrapping a third-party library (Whisper, MediaPipe, OpenAI SDK)
- Abstracting a CLI tool (FFmpeg, yt-dlp, ffprobe)
- Extracting reusable logic from a pipeline step
- Adding a new analysis capability (motion, OCR, color analysis)

## Inputs
- Service name (PascalCase, e.g., `TranscriptService`)
- External dependency to wrap (library class, CLI binary, API client)
- Configuration parameters from `app.config.settings`
- Domain dataclasses for inputs/outputs

## Outputs
- Python class in `app/services/<name>_service.py`
- Typed public methods with docstrings
- Logger via `structlog.get_logger()`

## Steps

1. **Create file** at `app/services/<name>_service.py`. Import `structlog`, needed types from sibling services (e.g., `TranscriptSegment`, `FaceBox`), and `app.config.settings`. Do NOT import from `app.models.*` or `app.api.*`.

2. **Define class** with docstring explaining single responsibility. Constructor accepts explicit parameters with sensible defaults (e.g., `model_name: str = "base"`). Keep stateless — all mutable state is passed as method arguments.

3. **Implement typed public methods**. Each method does ONE logical operation (download, transcribe, compute_filter). Inputs: primitives or domain dataclasses. Outputs: primitives, dataclasses, or typed dicts. Never raw JSON or framework types.

4. **Manage expensive resources** (Whisper model, MediaPipe detector) as module-level lazy singletons. Use pattern: `_detector: Optional[Type] = None` + `def _get_detector() -> Type: global _detector; if _detector is None: _detector = ...; return _detector`. This defers loading to first use and avoids reloading per invocation.

5. **Log entry and exit** at INFO level. Log input summary (file paths, model names, sizes) and output summary (segment count, face found, clip path). Use `logger.warning` for fallbacks, `logger.error` for failures. Bind contextual keys.

6. **Handle errors** — raise specific exceptions (`RuntimeError`, `ValueError`) with descriptive messages. Do NOT catch broadly. For non-critical operations (word timestamps fallback), log warning and return graceful fallback (None, empty list).

## Example

```python
import structlog
from app.config import settings

logger = structlog.get_logger()

class VideoService:
    def download(self, url: str, output_path: str) -> str:
        Path(output_path).parent.mkdir(parents=True, exist_ok=True)
        cmd = ["yt-dlp", "-f", "bestvideo[height<=1080]+bestaudio/best[height<=1080]", "-o", output_path, url]
        logger.info("downloading_video", url=url, output=output_path)
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=600, stdin=subprocess.DEVNULL)
        if result.returncode != 0:
            raise RuntimeError(f"yt-dlp failed: {result.stderr}")
        return output_path
```

## Notes
- One service = one file. If >200 lines, split into sub-services.
- Use `@dataclass` for simple value objects shared between services (see `TranscriptSegment`, `FaceBox`).
- Services do NOT call Celery, emit HTTP responses, access storage — that belongs in pipeline/usecases.
- For CLI tools (FFmpeg, yt-dlp), always use `subprocess.run(..., stdin=subprocess.DEVNULL, timeout=...)`. FFmpeg hangs without stdin redirect.
- Current services: `VideoService`, `TranscriptService`, `LLMHighlightService`, `HighlightService`, `FaceService`, `SmartCropService`, `RenderService`, `subtitle_service` (module-level functions).
