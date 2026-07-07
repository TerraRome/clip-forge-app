# Testing: Unit, Integration, and E2E with Pytest

## Description
Write and run tests for ClipForge using pytest. Covers: service unit tests (mocked subprocess/APIs), integration tests (real FFmpeg with small fixture files), API endpoint tests (TestClient), and E2E pipeline tests (full download-to-render with local test videos).

## When to Use
- Adding a new service, endpoint, use case, or pipeline step
- Fixing a bug — write a test that reproduces it first
- Refactoring — verify behavioral preservation
- Before deploying to production or merging a PR

## Inputs
- Target module (service, API, pipeline, utility)
- Test type (unit = mocked deps, integration = real deps with fixtures, E2E = full pipeline)
- Fixture data (short audio clips, mock transcript, sample video frames)

## Outputs
- Test file at `tests/test_<module>.py`
- Fixtures in `tests/conftest.py`
- Coverage report via `pytest --cov=app`

## Steps

1. **Set up test infrastructure** — create `tests/conftest.py` with shared fixtures: `@pytest.fixture` for sample `TranscriptSegment` list, mocked `storage`, sample video metadata dict, temp directory via `tmp_path`. Configure pytest in `pyproject.toml`: `[tool.pytest.ini_options] testpaths = ["tests"]`.

2. **Write unit tests for services** — instantiate the service, call its method, assert return value. Mock heavy dependencies: `@patch("app.services.video_service.subprocess.run")` for FFmpeg/yt-dlp, `@patch("whisper.load_model")` for transcription, `@patch("app.services.llm_highlight_service.OpenAI")` for LLM calls.

3. **Write integration tests** — use real FFmpeg and small fixture videos under `tests/fixtures/`. Generate 3-second test clips with: `ffmpeg -f lavfi -i testsrc=d=3:s=640x360 -f lavfi -i sine=f=440:d=3 -c:v libx264 -c:a aac tests/fixtures/sample.mp4`. Keep fixtures under 1MB and checked into git.

4. **Write API tests** — use `TestClient(app)`. Test each endpoint: 201 for creation, 200 for polling, 404 for missing, 409 for double-processing, 400 for invalid params. Use `client = TestClient(app)` in conftest. Override storage dependency for isolation.

5. **Write pipeline E2E tests** — call `run_pipeline` with a mock project pointing to a local test video. Assert output clips exist, duration within constraints, subtitle file generated. Mark with `@pytest.mark.e2e` and skip in CI unless explicitly run (these take 10-30s).

6. **Parameterize tests** — use `@pytest.mark.parametrize` for subtitle presets, `num_clips` values, edge cases (0 segments, 0 duration, negative timestamps, empty input).

## Example

```python
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_create_project_valid():
    resp = client.post("/api/projects", json={
        "youtube_url": "https://youtube.com/watch?v=dQw4w9WgXcQ",
        "num_clips": 3,
        "subtitle_preset": "classic",
    })
    assert resp.status_code == 201
    assert resp.json()["status"] == "pending"
    assert "id" in resp.json()

def test_create_project_invalid_url():
    resp = client.post("/api/projects", json={
        "youtube_url": "not-a-url",
        "num_clips": 3,
    })
    assert resp.status_code == 422
```

## Notes
- Fixture media files go in `tests/fixtures/`. Generate with FFmpeg as described above. Never commit large video files (>5MB).
- Tests hitting the LLM API need `responses` or `vcrpy` to record/replay HTTP interactions, or a `@pytest.mark.skipif` guard when API key is missing.
- Run with `pytest -v --cov=app tests/`. Target: >80% for services, >60% for API routes, >20% for pipeline.
- Use `tmp_path` fixture for all file output — never write to production directories.
- For async route tests, use `pytest-asyncio`: `@pytest.mark.asyncio` and `async def test_...`.
