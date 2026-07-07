# Testing Standards — ClipForge

## Framework
- **pytest** — never `unittest.TestCase`.
- `pytest-asyncio` for async tests.
- `pytest-cov` for coverage reporting.
- `pytest-mock` for mocking.
- `vcrpy` or manual fixture files for HTTP-dependent tests (LLM, yt-dlp).

## Structure
```
backend/tests/
├── conftest.py              # Shared fixtures
├── services/                # Test highlight, crop, subtitle services
├── api/                     # Integration tests via TestClient
├── storage/                 # FileStorage CRUD, thread safety
├── worker/                  # Pipeline orchestration
└── fixtures/                # Sample media, transcripts, ASS outputs
```

## Fixtures
- Minimal scope first (function > class > module > session).
- `conftest.py` at each level for scoped fixtures.
- Use `tmp_path` fixture for file output.
- Async fixtures: `@pytest_asyncio.fixture`.

## Mocking External Services
- Mock at the boundary: mock `subprocess.run`, not FFmpeg.
- Mock external APIs: mock `openai.chat.completions.create`, not the HTTP layer.
- Never mock your own service methods. Test the real implementation.
- Use `mocker.patch("app.services.video_service.subprocess.run")`.

## Coverage Thresholds (CI gate)
| Layer     | Min  | Notes                                    |
|-----------|------|------------------------------------------|
| Overall   | 80%  |                                          |
| domain/   | 95%  | No I/O — should be trivial.             |
| service/  | 85%  | Mock repos.                             |
| api/      | 85%  | TestClient + override DI.               |
| storage/  | 75%  | Integration only.                       |
| worker/   | 65%  | Pipeline orchestration.                 |

## Naming Convention
- File: `test_<module_name>.py`
- Class: `Test<ServiceName>`
- Function: `test__<method>__<scenario>__<expected>`

## What to Test
- Highlight detection: empty input, single segment, overlap avoidance, fallback path.
- Smart crop: no face -> center fill, face at edge -> crop clamped, landscape vs portrait.
- Storage: save/get roundtrip, partial update, non-existent -> None, thread safety.
- Pipeline: happy path PENDING -> PROCESSING -> DONE, error path -> ERROR with message.

## Forbidden
- Tests writing to real `/tmp/klip*` or using hardcoded paths.
- Tests making real HTTP calls.
- `@pytest.mark.skip` without a tracked issue link.
- Tests with no assertions.
- Mocking private methods — test public API behavior only.
