# Klip Mobile — Flutter Frontend

## Vision
Flutter mobile app for ClipForge — AI-powered video clipping platform. Paste URL, get viral-ready short clips.

## Tech Stack
Flutter latest stable, Bloc (state management), Freezed (immutable models), Injectable/GetIt (DI), GoRouter (routing), Hive (local storage), Dio (HTTP), media_kit (video playback)

## Folder Structure
```
lib/
├── core/          — Theme, constants, widgets, extensions
├── domain/        — Entities, use cases, repository interfaces
├── data/          — DTOs, API client, Hive adapters, repository impls
└── features/      — Per-feature: bloc, pages, widgets
```

## Coding Rules
- `const` constructors preferred. No `dynamic`.
- Bloc: one per feature; events = verb+noun; states = noun+status
- DI: `@injectable` + `@singleton`; auto-register via build_runner
- Errors: `Either<Failure, T>` from repos; Bloc emits error state
- `ponytail:` comments for deliberate simplifications with upgrade path
- No business logic in widgets — delegate to Bloc/use cases.
- All API calls through repository layer, never direct Dio in widgets.

## Do
- Use Freezed for all state/event/dto classes
- GoRouter for navigation with type-safe args
- Hive for offline cache; sync with API on connectivity
- media_kit for video preview in results screen

## Don't
- Don't import `package:dio` in UI layer
- Don't use `setState` for complex state — use Bloc
- Don't hardcode API URLs — use env/config
- Don't mix Bloc event/state in same file

## Current Milestone
Post-MVP Flutter app — stable, tested, production-ready.

## Definition of Done
- Compiles with zero analyzer warnings
- Bloc state coverage for loading/empty/error/success
- Widget tests for pages, unit tests for blocs/repos
- Integrated with backend API
