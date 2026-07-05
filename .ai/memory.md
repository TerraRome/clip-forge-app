# AI YouTube Clipper — Agent Memory

> **Append-only.** Never overwrite history. Each entry is timestamped and immutable.

---

## Entry 2026-07-04T14:00:00Z — Project Initialization

### Project Summary

AI YouTube Clipper is a Flutter + FastAPI application that converts YouTube videos into batches of short vertical clips with burnt-in subtitles. MVP supports: paste URL, select clip count (1/3/5/10), one-click processing, ZIP download. No login, no editor, no AI metadata.

### Architecture Decisions

| Decision            | Chosen                  | Alternative          | Rationale                                                       |
| ------------------- | ----------------------- | -------------------- | --------------------------------------------------------------- |
| State management    | Bloc                    | Riverpod, Provider   | Predictable, testable, industry-standard for production Flutter |
| Backend async       | FastAPI BackgroundTasks | Celery + Redis       | No message broker dependency for MVP; simple enough             |
| Transcription       | Whisper (local)         | Google/Azure STT API | Zero API cost, privacy, offline-capable                         |
| Highlight detection | Heuristic               | ML model             | No training data needed; decent results for MVP                 |
| Client storage      | Hive                    | SQLite, SharedPrefs  | Fast, no native deps, good for MVP scope                        |
| Code generation     | Freezed + Injectable    | Manual boilerplate   | Reduces error-prone repeated code                               |
| Download format     | ZIP stream              | Individual file URLs | Simpler UX, single download action                              |

### Folder Structure Reference

```
.ai/                      # Project memory and documentation
├── vision.md
├── prd.md
├── checklist.md
├── architecture.md
├── flutter.md
├── python.md
├── api.md
└── memory.md             # This file

backend/                  # Python FastAPI server (planned)
├── app/
├── temp/
├── tests/
└── Dockerfile

lib/                      # Flutter app (existing scaffold)
├── core/
├── domain/
├── data/
└── features/
```

### Current Features

- No implemented features — project in documentation phase

### Completed Tasks

- [x] Created `.ai/` documentation directory
- [x] vision.md — product vision, mission, goals, metrics
- [x] prd.md — full product requirements, personas, user stories, acceptance criteria
- [x] checklist.md — 5 milestones with tasks, AC, DoD, estimates
- [x] architecture.md — system diagrams, data flow, folder structure, decisions
- [x] flutter.md — clean architecture, Bloc rules, DI, testing, conventions
- [x] python.md — service layer, pipeline orchestration, config, logging
- [x] api.md — all endpoints with req/res/errors/examples
- [x] memory.md — this file

### Pending Tasks

- [ ] Milestone 1: Scaffold Flutter + Python projects
- [ ] Milestone 2: Implement Python backend endpoints + pipeline
- [ ] Milestone 3: Build Flutter UI + Bloc integration
- [ ] Milestone 4: End-to-end integration testing
- [ ] Milestone 5: Polish, error handling, documentation, CI

### Known Limitations (MVP)

1. **Whisper accuracy**: base model has ~90% word accuracy; poor for accented English or background noise
2. **Highlight quality**: heuristic-based; may miss good moments or include dull sections
3. **No retry-on-failure**: if pipeline stage fails, entire project fails
4. **Single server**: no horizontal scaling; max ~10 concurrent jobs
5. **No authentication**: anyone who reaches the API can process
6. **No progress persistence**: in-memory project store; restarts lose all state
7. **English-only subtitles**: Whisper language detection disabled; forced English

### Future Improvements

1. **Celery + Redis** for distributed task queue and persistent job state
2. **GPU inference** (CUDA) for Whisper to reduce transcription time 5x
3. **ML highlight model** trained on YouTube engagement data
4. **User accounts** with project history and favorites
5. **Multi-language subtitles** via Whisper language detection
6. **WebSocket** for real-time progress instead of polling
7. **S3 storage** for scalable file serving and cleanup
8. **Rate limiting** and API key authentication

### Coding Conventions

**Flutter:**

- Dart: const constructors preferred; avoid `dynamic`; use `sealed class` for failures
- Bloc: one Bloc per feature; events = verb+noun; states = noun+status
- DI: `@injectable` + `@singleton` scoping; auto-register via build_runner
- Naming: `feature_*` directories, `*_page.dart`, `*_bloc.dart`, `*_event.dart`, `*_state.dart`
- Error handling: `Either<Failure, T>` from repository; Bloc emits error state
- `ponytail:` comments for deliberate simplifications with upgrade path

**Python:**

- Type hints everywhere; `mypy --strict` in CI
- Async for I/O (`asyncio.to_thread` for CPU-bound)
- Services are stateless classes injected via FastAPI `Depends()`
- Pydantic for all request/response schemas
- structlog for structured JSON logging
- Pipeline exceptions caught by orchestrator; partial cleanup on failure

### Version History

- **v0.1.0** — Documentation phase complete (current)
- **v0.2.0** — Milestone 1: Project scaffold
- **v0.3.0** — Milestone 2: Backend API + pipeline
- **v0.4.0** — Milestone 3: Flutter UI
- **v0.5.0** — Milestone 4: Integration testing
- **v1.0.0** — Milestone 5: MVP release

---
