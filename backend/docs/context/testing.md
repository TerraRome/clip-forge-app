# Testing Strategy

## Purpose

ClipForge uses a layered testing strategy: fast unit tests for pure logic, integration tests for FFmpeg and service boundaries, and end-to-end tests for the full pipeline. Mocking isolates external dependencies (YouTube, LLM API, filesystem).

## Test Pyramid

```
        ╱╲
       ╱ E2E ╲           ← 3-5 smoke tests
      ╱────────╲
     ╱ Integration ╲     ← 10-15 tests
    ╱────────────────╲
   ╱    Unit Tests     ╲  ← 30-50 tests
  ╱──────────────────────╲
```

## Directory Structure

```
backend/
  tests/
    conftest.py               # Shared fixtures
    unit/
      test_highlight_service.py
      test_smart_crop_service.py
      test_subtitle_service.py
      test_project_model.py
    integration/
      test_video_service.py     # Requires FFmpeg
      test_transcript_service.py  # Requires Whisper model
      test_render_service.py    # Requires FFmpeg + GPU
      test_file_storage.py      # Temp filesystem
    e2e/
      test_pipeline.py          # Full pipeline with mocks
    fixtures/
      sample_16_9.mp4            # 3-second 16:9 test video
      sample_9_16.mp4            # 3-second portrait video
      sample_transcript.json     # Pre-computed transcript
      sample_audio.wav           # 16kHz mono test audio
```

## Unit Tests

### SmartCropService (pure logic, no IO)

```python
class TestSmartCropService:
    def test_center_crop_when_no_face(self):
        svc = SmartCropService()
        result = svc.compute_filter(None, 1920, 1080)
        assert "crop=1080:1920" in result
        assert "force_original_aspect_ratio=increase" in result

    def test_crop_follows_face_landscape(self):
        svc = SmartCropService()
        face = FaceBox(x=0.5, y=0.5, w=0.2, h=0.3, score=0.9)
        result = svc.compute_filter(face, 1920, 1080)
        # Scale height to 1920 → width scales to 3413
        # Face at x=0.5 → face_x = 1706 → crop_x = 1706 - 540 = 1166
        assert "scale=3413:1920" in result
        assert "crop=1080:1920:1166:0" in result

    def test_crop_clamps_to_bounds(self):
        svc = SmartCropService()
        face = FaceBox(x=0.0, y=0.0, w=0.1, h=0.1, score=0.9)
        result = svc.compute_filter(face, 1920, 1080)
        # Face at extreme left → crop_x should be 0, not negative
        assert "crop=1080:1920:0:0" in result
```

### HighlightService (pure logic)

```python
class TestHighlightService:
    def test_selects_highest_density_windows(self):
        svc = HighlightService()
        segments = [
            TranscriptSegment(0, 5, "hello world"),
            TranscriptSegment(60, 120, "word " * 100),  # dense speech
            TranscriptSegment(180, 200, "test"),
        ]
        highlights = svc.detect(segments, 200, 3)
        assert len(highlights) <= 3
        assert all(h.end - h.start >= MIN_CLIP_DURATION for h in highlights)

    def test_no_overlap(self):
        segments = [TranscriptSegment(i, i+10, "test") for i in range(0, 200, 10)]
        highlights = svc.detect(segments, 200, 5)
        for i in range(len(highlights)):
            for j in range(i+1, len(highlights)):
                assert not (highlights[i].start < highlights[j].end
                            and highlights[j].start < highlights[i].end)

    def test_empty_segments_returns_empty(self):
        assert svc.detect([], 100, 3) == []
```

### SubtitleService (pure string generation)

```python
class TestSubtitleService:
    def test_classic_preset(self):
        result = build_ass(SEGMENTS, HIGHLIGHT, preset="classic")
        assert "[V4+ Styles]" in result
        assert "Dialogue:" in result
        assert "Arial,58" in result

    def test_tiktok_3words_chunks(self):
        result = build_ass(SEGMENTS, HIGHLIGHT, preset="tiktok_3words")
        lines = [l for l in result.split("\n") if l.startswith("Dialogue:")]
        # Each line should have at most 3 words
        for line in lines:
            text = line.split(",,")[-1]  # After the last ,,
            word_count = len(text.split())
            assert word_count <= 3
```

### Project Model

```python
class TestProject:
    def test_create_generates_uuid(self):
        p = Project.create("https://youtu.be/abc123", 3)
        assert p.id and len(p.id) == 36  # UUID4
        assert p.status == ProjectStatus.PENDING
        assert p.progress == 0.0

    def test_serialization_roundtrip(self):
        p = Project.create("https://youtu.be/abc123", 3)
        p.status = ProjectStatus.DONE
        p.progress = 100.0
        restored = Project.from_dict(p.to_dict())
        assert restored.id == p.id
        assert restored.status == ProjectStatus.DONE
```

## Integration Tests

### VideoService (requires FFmpeg)

```python
class TestVideoService:
    def test_extract_audio_creates_wav(self, tmp_path):
        svc = VideoService()
        # Use the fixture sample video
        video = str(FIXTURES / "sample_16_9.mp4")
        out = str(tmp_path / "test.wav")
        svc.extract_audio(video, out)
        assert Path(out).exists()
        # ffprobe to verify format
        info = svc.get_info(out)
        assert info["streams"][0]["sample_rate"] == "16000"
        assert info["streams"][0]["channels"] == 1
```

### FileStorage (temp filesystem)

```python
class TestFileStorage:
    def test_save_and_retrieve(self, tmp_path, monkeypatch):
        monkeypatch.setattr(settings, "downloads_dir", str(tmp_path))
        store = FileStorage()
        p = Project.create("https://youtu.be/abc", 3)
        store.save(p)
        retrieved = store.get(p.id)
        assert retrieved.id == p.id
        assert retrieved.youtube_url == p.youtube_url

    def test_update_roundtrip(self, tmp_path, monkeypatch):
        monkeypatch.setattr(settings, "downloads_dir", str(tmp_path))
        store = FileStorage()
        p = Project.create("https://youtu.be/abc", 3)
        store.save(p)
        store.update(p.id, status=ProjectStatus.DONE, progress=100.0)
        updated = store.get(p.id)
        assert updated.status == ProjectStatus.DONE
        assert updated.progress == 100.0
```

## Mocking Patterns

### HTTP Clients (LLM API)

```python
@pytest.fixture
def mock_openai(monkeypatch):
    class MockResponse:
        def __init__(self):
            self.choices = [
                type("Choice", (), {
                    "message": type("Msg", (), {
                        "content": '[{"start": 10, "end": 40, "reason": "test"}]'
                    })
                })
            ]

    def mock_create(*args, **kwargs):
        return MockResponse()

    monkeypatch.setattr("openai.OpenAI.chat.completions.create", mock_create)
```

### yt-dlp (Subprocess)

```python
@pytest.fixture
def mock_ytdlp(monkeypatch):
    def fake_run(cmd, **kwargs):
        # Create a minimal valid MP4 at output path
        output_idx = cmd.index("-o") + 1
        output_path = cmd[output_idx]
        _create_minimal_mp4(output_path)
        return subprocess.CompletedProcess(cmd, 0, "", "")

    monkeypatch.setattr(subprocess, "run", fake_run)
```

## E2E Tests

```python
@pytest.mark.slow
def test_pipeline_end_to_end(tmp_path, monkeypatch, mock_ytdlp, mock_openai, mock_ffprobe):
    monkeypatch.setattr(settings, "downloads_dir", str(tmp_path / "downloads"))
    video_path = str(FIXTURES / "sample_16_9.mp4")
    monkeypatch.setattr(settings, "ffmpeg_path", "ffmpeg")

    project = Project.create("https://youtu.be/test", 3, subtitle_preset="classic")
    storage = FileStorage()
    storage.save(project)

    run_pipeline(project.id)

    completed = storage.get(project.id)
    assert completed.status == ProjectStatus.DONE
    assert len(completed.clip_paths) == 3
    for clip in completed.clip_paths:
        assert Path(clip).exists()
```

## Running Tests

```bash
# Fast unit tests (no external deps)
pytest tests/unit/ -v

# Integration tests (requires FFmpeg)
pytest tests/integration/ -v

# All tests
pytest -v

# With coverage
pytest --cov=app --cov-report=term-missing

# Skip slow E2E tests
pytest -v -m "not slow"
```
