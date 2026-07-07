# Create Use Case

## Description
Create a use case class orchestrating multiple services to fulfill a business operation. Use cases sit between API routes/pipeline and individual services, coordinating the workflow and enforcing business rules. They are stateless and testable without HTTP or Celery infrastructure.

## When to Use
- A feature requires coordinated calls to multiple services (download + transcribe + analyze)
- Business logic spans multiple domain services and needs a single entry point
- An API handler or pipeline function is getting too complex and needs extracted orchestration

## Inputs
- Business operation name (e.g., `ProcessVideoUseCase`)
- List of services it coordinates (via constructor DI)
- Input data (typed, from schemas or pipeline context)
- Output type (result dataclass or typed dict)

## Outputs
- Use case class in `app/usecases/<name>_usecase.py`
- Single public `execute` method
- Structured logging at orchestration level

## Steps

1. **Create file** at `app/usecases/<name>_usecase.py`. Import the services it will orchestrate. Do NOT import API schemas or FastAPI types — use case receives plain Python objects and returns domain types.

2. **Define class** with docstring describing the business flow. Constructor accepts service instances (dependency injection). Provide default instantiation for convenience, but allow injection for testing. Example: `def __init__(self, video_svc=None): self.video_svc = video_svc or VideoService()`.

3. **Implement `execute` method** that chains service calls with clear step boundaries. Between steps, enforce business rules (e.g., "if no faces detected, use center crop"). Log each step: `logger.info("step_name", input_summary=...)`.

4. **Handle errors at use case boundary** — catch service-level exceptions and wrap with context: `raise ProcessingError(f"Download failed for {url}: {e}") from e`. Return a result object or raise — never return HTTP errors.

5. **Return typed result** — dataclass or typed dict with all outputs. Keep return shape stable even if internal steps change. Example: `ProcessingResult(clip_paths=[...], segments=[...])`.

## Example

```python
class ProcessVideoUseCase:
    def __init__(self, video_svc=None, transcript_svc=None, highlight_svc=None, render_svc=None):
        self.video_svc = video_svc or VideoService()
        self.transcript_svc = transcript_svc or TranscriptService()
        self.highlight_svc = highlight_svc or LLMHighlightService()
        self.render_svc = render_svc or RenderService()

    def execute(self, video_path: str, total_duration: float, num_clips: int) -> ProcessingResult:
        segments = self.transcript_svc.transcribe(video_path)
        highlights = self.highlight_svc.detect(segments, total_duration, num_clips)
        clip_paths = []
        for hl in highlights:
            path = self.render_svc.render_clip(video_path, segments, hl, ...)
            clip_paths.append(path)
        return ProcessingResult(clip_paths=clip_paths)
```

## Notes
- Use cases can be synchronous (pipeline calls them) or async (API handlers). Prefer sync; wrap with `run_in_executor` from handlers if needed.
- Each use case should have one reason to change. If orchestration exceeds 3-4 services or has >2 decision branches, consider splitting.
- Use cases do NOT import FastAPI/Celery/HTTP types. They are pure domain logic.
- For pipeline integration, use cases can accept a progress callback: `on_progress: Callable[[float], None]` injected at construction.
- The current pipeline in `app/worker/pipeline.py` IS effectively a use case in function form — extract to a class when adding tests.
