# ClipForge Stack

## Core
| Component | Choice | Why |
|-----------|--------|-----|
| Language | Python 3.13 | AI/ML ecosystem, async support |
| Framework | FastAPI | Async-native, OpenAPI auto-docs, Pydantic v2 |
| Validation | Pydantic v2 | FastAPI native, performance |
| ORM | SQLAlchemy 2 | Mature, async, migration-friendly |
| Migrations | Alembic | SQLAlchemy-native, auto-generation |
| Queue | Celery | Distributed task queue, beat scheduler |
| Broker | Redis | Fast, simple, Celery-native |
| DB | PostgreSQL | JSON, full-text search, reliability |
| Storage | MinIO | S3-compatible, self-hosted, cheap |
| Container | Docker + Compose | Dev/prod parity |

## AI/ML
| Component | Choice | Why |
|-----------|--------|-----|
| Speech-to-text | Whisper (faster-whisper) | Accuracy, language support |
| Face detection | MediaPipe BlazeFace | Real-time, profile faces |
| Face tracking | YOLOv8 + ByteTrack | Multi-face tracking |
| Scene detection | PySceneDetect | Content-aware cuts |
| Speaker diarization | Pyannote-audio | Who speaks when |
| Embeddings | Sentence Transformers | Semantic similarity |
| LLM | OpenAI-compatible (Groq/DeepSeek) | Highlight selection |

## Media
| Component | Choice | Why |
|-----------|--------|-----|
| Processing | FFmpeg | Industry standard |
| Subtitle | ASS format | Karaoke, word-level highlight |
| GPU encode | h264_videotoolbox (Mac) / NVENC | Hardware acceleration |
| Video I/O | OpenCV | Frame extraction, filter graph |

## Infrastructure
| Component | Choice | Why |
|-----------|--------|-----|
| Auth | JWT (python-jose) | Stateless, simple |
| Config | Pydantic Settings | Type-safe, env override |
| Logging | structlog | Structured, correlatable |
| Monitoring | Prometheus + Grafana | Industry standard |
