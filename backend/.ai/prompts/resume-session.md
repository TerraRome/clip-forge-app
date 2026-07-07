# Prompt: Resume Interrupted Session

## Context
Used when resuming a coding session on ClipForge after interruption (context window limit, crash, or manual pause). Provides the LLM with full context so it can continue without re-reading the codebase.

## System Prompt
You are resuming work on ClipForge, a Python/FastAPI backend for AI YouTube-to-shorts conversion. Read the context summary below carefully. Project state (files, git branch) has NOT changed since last session. Continue exactly where you left off. Do not re-explore the codebase. Do not re-read files unless the summary explicitly says to. Focus only on remaining steps.

The repository has ClipForge-specific patterns you already used last session:
- Models: `app/models/project.py` -> `@dataclass` with `to_dict`/`from_dict`, JSON schema versioning
- Storage: `app/storage/file_storage.py` -> `FileStorage` class, thread-safe with `_lock`, `get/save/update`
- Services: `app/services/*.py` -> stateless classes, structlog, lazy module-level model singletons
- Pipeline: `app/worker/pipeline.py` -> `run_pipeline(project_id)` sequentially calling services
- Config: `app/config.py` -> `pydantic-settings` `Settings` class, loads from `.env`
- API: `app/api/router.py` -> FastAPI routes with Pydantic v2 schemas
- FFmpeg: subprocess with `h264_videotoolbox`, `1080x1920` output, ASS subtitle filter
- Whisper: `base` model, `language="id"`, returns `TranscriptSegment` list
- Face detect: MediaPipe BlazeFace TFLite, normalized coordinates, 30 frame samples

## User Prompt Template
## Session Resume

### Git State
- Branch: `{{branch_name}}` ({{branch_status}})
- Last commit: `{{last_commit}}`
- Uncommitted: {{uncommitted_changes}}

### Goal
{{session_goal}}

### Progress
**Completed** (verified):
{% for item in completed %}
- [x] {{item}}
{% endfor %}

**Remaining** (in order):
{% for item in remaining %}
- [ ] {{item}}
{% endfor %}

### Files Modified This Session
{% for file in modified_files %}
- `{{file.path}}`: {{file.summary}}
{% endfor %}

### Key Decisions
{% for decision in key_decisions %}
- {{decision}}
{% endfor %}

### Last State
Last command executed: `{{last_command}}`

Output:
```
{{last_output}}
```

### Next Action
{{next_action}}

### Context Hints
{% for hint in context_hints %}
- {{hint}}
{% endfor %}

## Variables
| Variable | Description |
|----------|-------------|
| `branch_name` | Git branch |
| `branch_status` | Clean/dirty, ahead/behind |
| `last_commit` | `git log -1 --oneline` |
| `uncommitted_changes` | `git diff --stat` summary |
| `session_goal` | What we're building |
| `completed` | Finished tasks (verified working) |
| `remaining` | Ordered todo |
| `modified_files` | Files touched with one-line summary |
| `key_decisions` | Design choices made |
| `last_command` | The last command that was run |
| `last_output` | Its output |
| `next_action` | The exact next step |
| `context_hints` | Important file paths, patterns, or pitfalls |

## Example
```
Branch: feature/word-pop-subtitles (clean, 2 ahead of main)
Goal: Implement word_pop subtitle preset
Completed:
  - Added _build_word_pop() to subtitle_service.py
  - Added 'word_pop' case to build_ass() dispatch
  - Added fallback to classic on error
Remaining:
  - Wire subtitle_preset param through RenderService.render_clip()
  - Add subtitle_preset to CreateProjectRequest schema
Next action: Modify render_clip() signature in render_service.py to accept subtitle_preset
Context hints: render_clip currently only uses preset inside build_ass call;
  subtitle_preset comes from project.subtitle_preset which is saved in project.json
```
