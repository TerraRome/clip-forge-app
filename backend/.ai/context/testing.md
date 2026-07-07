# Testing: Current State

## Current Gaps
- No test files exist in the codebase
- No pytest configuration
- No CI pipeline

## Recommended Setup
- `pytest`, `pytest-asyncio`, `httpx` (for TestClient)
- `pytest-cov` for coverage reporting
- Fixtures in `tests/conftest.py`

## Test Strategy

### Unit Tests (Services)
- `test_highlight_service.py`: Test sliding window algorithm, fallback segments, edge cases (empty segments, short video)
- `test_smart_crop_service.py`: Test crop filter string generation with/without face, landscape/portrait
- `test_subtitle_service.py`: Test ASS output for all 4 presets, time formatting, text escaping
- `test_project_model.py`: Test Project.create(), to_dict/from_dict round-trip

### Integration Tests (API)
- `test_api.py`: Create project → process → poll → download flow using `TestClient`
- Mock FileStorage with temp directory fixture
- Mock external services (no real yt-dlp/whisper/ffmpeg)

### Mock Strategy
- `conftest.py`: `tmp_path` fixture for FileStorage, mock subprocess.run for ffmpeg/yt-dlp
- `unittest.mock.patch("subprocess.run")` returning fake CompletedProcess
- `unittest.mock.patch("whisper.load_model")` returning fake transcript
- `unittest.mock.patch("openai.OpenAI")` returning fake LLM response

## CI (Future)
- GitHub Actions: lint (ruff) → type-check (mypy) → test (pytest)
- macOS runner for VideoToolbox GPU tests (optional)
