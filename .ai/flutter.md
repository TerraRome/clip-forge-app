# AI YouTube Clipper — Flutter Architecture

## Technology Stack

| Category             | Choice                | Rationale                                               |
| -------------------- | --------------------- | ------------------------------------------------------- |
| Framework            | Flutter latest stable | Cross-platform mobile, single codebase                  |
| State management     | Bloc (flutter_bloc)   | Predictable, testable, scales with complexity           |
| Code generation      | Freezed               | Immutable state/events, union types, copyWith, equality |
| Dependency injection | Injectable + GetIt    | Compile-safe DI, minimal boilerplate                    |
| Routing              | GoRouter              | Declarative, deep link support, type-safe               |
| Local storage        | Hive                  | Fast, no native deps, good for MVP                      |
| HTTP client          | Dio                   | Interceptors, retry, streaming download                 |
| Video playback       | media_kit             | Cross-platform video player, subtitle support           |
| Linting              | analysis_options.yaml | Strict rules, custom config                             |

## Clean Architecture Structure

```
lib/
├── main.dart                      # App entry, DI setup
├── app.dart                       # MaterialApp, theme, router
│
├── core/                          # Shared infrastructure
│   ├── constants/
│   │   ├── app_constants.dart     # App-wide constants
│   │   └── api_endpoints.dart     # URL constants
│   ├── errors/
│   │   ├── failures.dart          # Failure sealed class
│   │   └── exceptions.dart        # Custom exceptions
│   ├── network/
│   │   └── api_client.dart        # Dio instance, interceptors
│   ├── router/
│   │   └── app_router.dart        # GoRouter config
│   ├── theme/
│   │   ├── tokens/
│   │   │   ├── color_tokens.dart
│   │   │   ├── typography_tokens.dart
│   │   │   ├── spacing_tokens.dart
│   │   │   └── elevation_tokens.dart
│   │   ├── extensions/
│   │   │   ├── color_extension.dart
│   │   │   └── app_theme_extension.dart
│   │   └── theme.dart
│   └── ui/
│       ├── ui.dart                # Barrel export
│       ├── app_primary_button.dart
│       ├── app_secondary_button.dart
│       ├── app_text_field.dart
│       ├── app_card.dart
│       ├── app_chip.dart
│       ├── app_badge.dart
│       ├── app_loader.dart
│       ├── app_progress_indicator.dart
│       ├── app_page.dart
│       ├── app_app_bar.dart
│       ├── app_scaffold.dart
│       └── app_video_card.dart
│
├── domain/                        # Enterprise business rules
│   ├── entities/
│   │   └── project.dart           # Core entity
│   └── repositories/
│       └── project_repository.dart # Abstract interface
│
├── data/                          # Data layer
│   ├── datasources/
│   │   ├── api/
│   │   │   ├── project_api.dart
│   │   │   └── project_api.g.dart # Generated
│   │   └── local/
│   │       ├── project_local.dart
│   │       └── project_local.g.dart
│   ├── dto/
│   │   ├── project_dto.dart
│   │   └── project_dto.freezed.dart
│   └── repositories/
│       └── project_repository_impl.dart
│
└── features/                      # Feature modules
    ├── home/
    │   └── presentation/
    │       ├── pages/
    │       │   └── home_page.dart
    │       └── widgets/
    │           └── url_input_field.dart
    ├── new_project/
    │   ├── bloc/
    │   │   ├── project_bloc.dart
    │   │   ├── project_event.dart
    │   │   ├── project_state.dart
    │   │   └── project_bloc.g.dart
    │   └── presentation/
    │       ├── pages/
    │       │   └── new_project_page.dart
    │       └── widgets/
    │           └── clip_count_selector.dart
    ├── processing/
    │   ├── bloc/
    │   │   ├── process_bloc.dart
    │   │   ├── process_event.dart
    │   │   ├── process_state.dart
    │   │   └── process_bloc.g.dart
    │   └── presentation/
    │       ├── pages/
    │       │   └── processing_page.dart
    │       └── widgets/
    │           └── progress_indicator.dart
    └── results/
        ├── bloc/
        │   ├── download_bloc.dart
        │   ├── download_event.dart
        │   ├── download_state.dart
        │   └── download_bloc.g.dart
        └── presentation/
            ├── pages/
            │   └── results_page.dart
            └── widgets/
                └── clip_grid_item.dart
```

## Naming Conventions

| Element                  | Convention                        | Example             |
| ------------------------ | --------------------------------- | ------------------- |
| File (feature)           | snake_case                        | `home_page.dart`    |
| File (bloc)              | snake_case                        | `project_bloc.dart` |
| Class (screen)           | PascalCase feature + 'Page'       | `HomePage`          |
| Class (bloc)             | PascalCase feature + 'Bloc'       | `ProjectBloc`       |
| Class (event)            | PascalCase feature + 'Event'      | `ProjectEvent`      |
| Class (state)            | PascalCase feature + 'State'      | `ProjectState`      |
| Class (widget)           | PascalCase description + 'Widget' | `ClipCountSelector` |
| Class (dto)              | PascalCase feature + 'Dto'        | `ProjectDto`        |
| Directory (feature)      | snake_case                        | `new_project/`      |
| Directory (bloc)         | `bloc/`                           | `bloc/`             |
| Directory (presentation) | `presentation/`                   | `presentation/`     |
| Directory (pages)        | `pages/`                          | `pages/`            |
| Directory (widgets)      | `widgets/`                        | `widgets/`          |

## Bloc Rules

1. **One Bloc per feature** — project creation, processing, download each get their own Bloc
2. **Events are actions** — named as verb + noun: `UrlSubmitted`, `ClipCountSelected`, `ProcessStarted`
3. **States are snapshots** — named as noun + status: `ProjectInitial`, `ProjectLoading`, `ProjectCreated`, `ProjectError`
4. **No business logic in UI** — all API calls, validation, and data transformation live in Bloc or Repository
5. **Bloc only emits when state changes** — no duplicate emission
6. **Use `on<Event>` with `emit`** — no raw `mapEventToState`
7. **Dispose timers** — cancel polling when leaving processing screen
8. **Error states** — every Bloc has a `*Failure` or `*Error` state variant

## Repository Pattern

```dart
// domain/repositories/project_repository.dart — Abstract
abstract class ProjectRepository {
  Future<Either<Failure, Project>> createProject(String url, int clipCount);
  Stream<Project> watchProject(String id);
  Future<Either<Failure, Unit>> cancelProject(String id);
  Future<Either<Failure, String>> downloadProject(String id); // returns file path
}

// data/repositories/project_repository_impl.dart — Implementation
class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectApi api;
  final ProjectLocal local;

  ProjectRepositoryImpl(this.api, this.local);

  @override
  Future<Either<Failure, Project>> createProject(String url, int clipCount) async {
    try {
      final dto = await api.createProject(url, clipCount);
      final project = dto.toEntity();
      await local.saveProject(project);
      return Right(project);
    } on DioException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }
  // ...
}
```

## Dependency Injection

- **Injectable** for code-generated factory registration
- **GetIt** as service locator (singleton scoped)
- Auto-register: Blocs, Repositories, DataSources, ApiClient
- Manual register: Hive boxes (needs async init)

```dart
// injectable config
@injectableInit
void configureDependencies() => getIt.init();

// usage in main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  configureDependencies();
  runApp(const KlipApp());
}
```

## Error Handling

### Failure Hierarchy

```dart
@freezed
sealed class Failure with _$Failure {
  const factory Failure.network(String message) = NetworkFailure;
  const factory Failure.server(String message, int? statusCode) = ServerFailure;
  const factory Failure.validation(String message) = ValidationFailure;
  const factory Failure.cache(String message) = CacheFailure;
  const factory Failure.unknown(String message) = UnknownFailure;
}
```

### Error Handling Strategy

| Layer      | Strategy                                                         |
| ---------- | ---------------------------------------------------------------- |
| API (Dio)  | Interceptor catches `DioException`, translates to `Failure`      |
| Repository | Returns `Either<Failure, T>`                                     |
| Bloc       | Emits `*Error` state with `Failure`                              |
| UI         | Reads `Failure` → user-friendly message → show SnackBar or retry |

## State Management Patterns

### ProjectBloc (one-shot operation)

```dart
@injectable
class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final ProjectRepository _repository;

  ProjectBloc(this._repository) : super(const ProjectInitial()) {
    on<UrlSubmitted>(_onUrlSubmitted);
    on<ClipCountSelected>(_onClipCountSelected);
    on<ProjectReset>(_onProjectReset);
  }

  Future<void> _onUrlSubmitte(UrlSubmitted event, Emitter<ProjectState> emit) async {
    emit(const ProjectValidating());
    // client-side URL validation
    if (!_isValidYoutubeUrl(event.url)) {
      emit(const ProjectError('Invalid YouTube URL'));
      return;
    }
    emit(ProjectValidated(event.url));
  }
}
```

### ProcessBloc (polling)

```dart
@injectable
class ProcessBloc extends Bloc<ProcessEvent, ProcessState> {
  final ProjectRepository _repository;
  Timer? _pollTimer;

  ProcessBloc(this._repository) : super(const ProcessInitial()) {
    on<ProcessStarted>(_onProcessStarted);
    on<ProcessPolled>(_onProcessPolled);
    on<ProcessCancelled>(_onProcessCancelled);
  }

  Future<void> _onProcessStarted(ProcessStarted event, Emitter<ProcessState> emit) async {
    emit(const ProcessInProgress(0, 'Starting...'));
    await _repository.startProcessing(event.projectId);
    _startPolling(event.projectId);
  }

  void _startPolling(String projectId) {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      add(ProcessPolled(projectId));
    });
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
```

## Testing Strategy

| Test Type         | Tools                   | Coverage Target                   |
| ----------------- | ----------------------- | --------------------------------- |
| Unit (Bloc)       | flutter_test, bloc_test | 90%+ for events→state transforms  |
| Unit (Repository) | flutter_test, mocktail  | 100% for error handling paths     |
| Unit (API)        | flutter_test, mocktail  | 100% for response deserialization |
| Widget            | flutter_test            | Key user flows, all screens       |
| Integration       | integration_test        | Full flow (requires backend)      |

### Bloc Test Example

```dart
void main() {
  late ProjectBloc bloc;
  late MockProjectRepository repository;

  setUp(() {
    repository = MockProjectRepository();
    bloc = ProjectBloc(repository);
  });

  blocTest<ProjectBloc, ProjectState>(
    'emits [ProjectValidating, ProjectError] when URL is invalid',
    build: () => bloc,
    act: (bloc) => bloc.add(const UrlSubmitted('not-a-url')),
    expect: () => [
      const ProjectValidating(),
      const ProjectError('Invalid YouTube URL'),
    ],
  );
}
```

## Coding Standards

1. **Imports order**: dart → flutter → 3rd party → project
2. **Named constructors** for named parameters (prefer `const` where possible)
3. **Private members** start with `_`
4. **Avoid `dynamic`** — use `Object` + type check or sealed types
5. **Comments**: only when logic is non-obvious; prefer self-documenting code
6. **`ponytail:` comments** mark deliberate simplifications with upgrade path
7. **No `print()`** — use `log()` or `Logger` in debug builds
8. **Barrel files** (`ui.dart`) for related exports
9. **File naming**: match class name in snake_case
10. **Line length**: 100 chars max (configurable in `analysis_options.yaml`)

## Build Configuration

```
# build.yaml — code generation
targets:
  $default:
    builders:
      injectable_generator:
        options:
          auto_register: true
      freezed:
        options:
          union_key: type
          union_value_case: snake
```

## Key Dependencies with Versions (pubspec.yaml)

```yaml
dependencies:
  flutter_bloc: ^8.1.0
  freezed_annotation: ^2.4.0
  injectable: ^2.3.0
  get_it: ^7.6.0
  go_router: ^14.0.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  dio: ^5.4.0
  media_kit: ^1.1.0
  media_kit_video: ^1.2.0

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.4.0
  injectable_generator: ^2.4.0
  bloc_test: ^9.1.0
  mocktail: ^1.0.0
```

## Platform Support (MVP)

| Platform | Target            | Notes                      |
| -------- | ----------------- | -------------------------- |
| iOS      | 15.0+             | Optimized for iPhone       |
| Android  | 5.0+ (API 21)     | Tested on major OEMs       |
| Web      | Not supported     | Video processing too heavy |
| macOS    | Not supported MVP | Future release             |
