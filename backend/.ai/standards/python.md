# Python Coding Standards — ClipForge

## Type Hints
- Every function/method signature MUST have type hints.
- Never use `Any`. Use `object`, `TypeVar`, `Protocol`, or `cast()` as last resort.
- Use `from __future__ import annotations` for PEP 604 syntax (`X | Y` over `Optional[X]`).
- Prefer `list[X]`, `dict[K,V]`, `tuple[A,B]` over `List[X]`, `Dict[K,V]` (Python 3.9+).
- Use `Self` return type for classmethods.

## Strings
- **Always f-strings** — never `%` formatting, never `.format()`, never `+` concatenation.
- Multi-line: wrap in parentheses, not backslashes.
- Log messages: pass as positional args, not f-strings (structlog lazy evaluation).

## Data Classes
- Use `@dataclass` for domain value objects.
- Use `pydantic.BaseModel` for API request/response models (serialization + validation).
- Use `TypedDict` for dict-like return types from untyped deps (e.g., raw FFprobe output).

## Error Handling
- Never `except:`. Always catch specific exception types.
- Business-logic exceptions inherit from custom `ClipForgeError` (see error-handling.md).
- Prefer early returns + guard clauses over deep nesting.

## Imports
- Standard -> Third-party -> First-party. One blank line between groups.
- Absolute imports only.
- `TYPE_CHECKING` block for type-only imports to avoid circular deps.
- No `import *`.

## Naming
- `snake_case` for functions/vars, `PascalCase` for classes, `UPPER_SNAKE_CASE` for constants.
- Private: `_leading_underscore`. Dunder only for protocols/operators.
- Boolean vars: `is_`, `has_`, `should_` prefix.

## Configuration
- Settings via pydantic-settings `BaseSettings`, loaded once at app startup.
- Never hardcode env-dependent values.

## Function Rules
- Max 40 lines. Extract helpers at 25.
- Boolean flag params forbidden — extract two functions instead.
- `Optional[str] = None` for optional params, never sentinel values like `""`.

## Forbidden
- `# type: ignore` without inline comment explaining why.
- `eval()`, `exec()`, `pickle.loads()` from untrusted sources.
- Mutable default arguments.
- `print()` in production code (use structlog).
- Global mutable state except module-level singleton caches (with thread safety).

ponytail: Enforce via Ruff + mypy strict. CI gate on violations.
