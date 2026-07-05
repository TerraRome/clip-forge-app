# AI YouTube Clipper — Implementation Rules

## 1. Purpose & Scope

This document defines **mandatory implementation rules** for all code written in this project. Rules are organized by topic and are enforceable via automation (linter, analyzer, custom checks) or code review. Every rule includes a rationale, a good example (markdown), and a bad example (markdown). No rule may be violated without an explicit ADR in `memory.md`.

**Authority**: This document supersedes general Flutter/Dart conventions where they conflict. All other `.ai/` docs reference these rules — do not duplicate them.

**Enforcement tiers**:

- **HARD**: Violation blocks PR (automated check exists)
- **SOFT**: Violation flagged in review (no automated check yet)
- **ADVISORY**: Best practice, documented for AI consistency

---

## 2. Architecture Rules

### Rule ARCH-01: Layer isolation (HARD)

Domain layer imports NOTHING from Data or Presentation. Data layer imports only Domain. Presentation imports only Domain.

```
Good:
domain/entity/project.dart → imports `package:freezed_annotation`
data/repository/project_repository_impl.dart → imports `domain/entity/project.dart`
presentation/home/home_screen.dart → imports `domain/entity/project.dart`

Bad:
domain/entity/project.dart → imports `dart:io` (platform leak)
data/repository/project_repository_impl.dart → imports `presentation/home/home_bloc.dart`
presentation/home/home_bloc.dart → imports `data/datasource/project_api_datasource.dart`
```

### Rule ARCH-02: Repository pattern (HARD)

Presentation never calls DataSource directly. Every data access goes through a Repository. Repository interface lives in Domain, implementation in Data.

### Rule ARCH-03: Feature isolation (SOFT)

One feature folder must not import another feature folder directly. Cross-feature communication happens through Domain entities or shared core utilities.

### Rule ARCH-04: Bloc-to-Bloc forbidden (SOFT)

Blocs never reference other Blocs. Use `BlocListener` in the widget layer or propagate through Repository events if cross-feature coordination is needed.

---

## 3. Naming Rules

### Rule NAME-01: File naming (HARD)

| Artifact             | Convention                        | Example                              |
| -------------------- | --------------------------------- | ------------------------------------ |
| Feature screen       | `{feature}_screen.dart`           | `home_screen.dart`                   |
| Feature bloc         | `{feature}_bloc.dart`             | `home_bloc.dart`                     |
| Feature event        | `{feature}_event.dart`            | `home_event.dart`                    |
| Feature state        | `{feature}_state.dart`            | `home_state.dart`                    |
| Domain entity        | `{name}.dart`                     | `project.dart`                       |
| Domain enum          | `{name}.dart`                     | `project_status.dart`                |
| Repository interface | `{name}_repository.dart`          | `project_repository.dart`            |
| Repository impl      | `{name}_repository_impl.dart`     | `project_repository_impl.dart`       |
| DTO                  | `{name}_dto.dart`                 | `project_dto.dart`                   |
| DataSource           | `{source}_{type}_datasource.dart` | `project_api_datasource.dart`        |
| Core utility         | `{purpose}.dart`                  | `validators.dart`, `constants.dart`  |
| Test (unit)          | `{tested_file}_test.dart`         | `project_bloc_test.dart`             |
| Test (widget)        | `{widget}_test.dart`              | `home_screen_test.dart`              |
| Test (integration)   | `{feature}_integration_test.dart` | `project_flow_integration_test.dart` |

### Rule NAME-02: Class naming (HARD)

- Bloc: `{Feature}Bloc` (e.g., `HomeBloc`)
- Event: `{Feature}Event` (e.g., `HomeEvent`) with union case names like `UrlSubmitted`, `ClipCountSelected`
- State: `{Feature}State` (e.g., `HomeState`) with union case names like `HomeInitial`, `HomeValid`, `HomeError`
- Entity: plain PascalCase (e.g., `Project`)
- DTO: `{Entity}Dto` (e.g., `ProjectDto`)
- DataSource: `{Source}DataSource` (e.g., `ProjectApiDataSource`)
- Repository interface: `{Entity}Repository` (e.g., `ProjectRepository`)
- Repository impl: `{Entity}RepositoryImpl` (e.g., `ProjectRepositoryImpl`)

### Rule NAME-03: Constant naming (HARD)

Constants use `lowerCamelCase`. No SCREAMING_SNAKE_CASE except in legacy interop.

```
Good: const defaultClipCount = 3;
Bad: const DEFAULT_CLIP_COUNT = 3;
```

### Rule NAME-04: Private members (HARD)

Private methods and fields use `_lowerCamelCase`. Private top-level functions use `_lowerCamelCase`.

---

## 4. Folder Structure Rules

### Rule FOLDER-01: Feature folder boundary (HARD)

A feature folder must contain exactly:

```
{presentation,data,domain}/<feature>/
├── {feature}_screen.dart (presentation only)
├── {feature}_bloc.dart (presentation only)
├── {feature}_event.dart (presentation only)
├── {feature}_state.dart (presentation only)
├── {entity}.dart (domain only, if feature owns entity)
├── {entity}_repository.dart (domain only, if feature owns interface)
├── {entity}_repository_impl.dart (data only, if feature owns impl)
├── {entity}_dto.dart (data only, if feature owns DTO)
├── {source}_datasource.dart (data only)
└── widgets/ (presentation only, shared sub-widgets)
```

### Rule FOLDER-02: Core folder contents (SOFT)

`lib/core/` contains only: `di/`, `router/`, `network/`, `theme/`, `utils/`. No feature code. No domain entities.

### Rule FOLDER-03: Test mirroring (HARD)

Test folder structure mirrors `lib/` exactly:

```
test/
├── core/
│   ├── di/ (integration tests for DI)
│   ├── router/ (route tests)
│   ├── network/ (Dio interceptor tests)
│   └── utils/ (validator tests)
├── data/
│   ├── datasources/
│   ├── models/ (DTO tests)
│   └── repositories/
├── domain/
│   └── entities/ (entity validation tests)
└── presentation/
    ├── home/ (bloc unit + widget tests)
    ├── process/
    └── download/
```

---

## 5. SOLID Rules

### S — Single Responsibility (HARD)

Each class has exactly one reason to change. Bloc handles state transitions, not API calls. Widget renders UI, not business logic. Repository coordinates data sources, not validation.

Thresholds:

- Bloc >300 lines → extract pure functions or split into multiple blocs
- Widget >200 lines → extract sub-widgets
- Repository >200 lines → extract datasource logic
- Function >30 lines → extract helper

### O — Open/Closed (SOFT)

Classes are open for extension, closed for modification. Use sealed unions (Freezed) for state/event types rather than if-else chains. Add new union cases instead of modifying existing handlers.

### L — Liskov Substitution (HARD)

Repository implementations must satisfy all contracts of their interface. No `UnimplementedError` or `throw` in stub methods. If a method cannot be implemented, revisit the interface design.

### I — Interface Segregation (ADVISORY)

Repository interfaces should have ≤5 methods. If a repository needs more, split into multiple focused interfaces (e.g., `ProjectReadRepository`, `ProjectWriteRepository`).

### D — Dependency Inversion (HARD)

High-level modules (Domain) define interfaces. Low-level modules (Data) implement them. Both depend on abstractions. Concrete classes are injected via DI (GetIt).

```
Good:
class ProcessBloc {
  ProcessBloc({required ProjectRepository repo}) : _repo = repo;
}

Bad:
class ProcessBloc {
  ProcessBloc() : _repo = ProjectRepositoryImpl(ApiDataSource(Dio()));
}
```

---

## 6. DRY Rules

### Rule DRY-01: Three-strike rule (SOFT)

Copy code once: acceptable. Copy twice: extract on the third occurrence. Never copy-paste the same logic more than twice.

### Rule DRY-02: Small duplication tolerance (ADVISORY)

Duplication under 5 lines that is conceptually different (even if structurally similar) does not need extraction. Premature extraction creates confusing abstractions.

```
Good: Keep two 3-line URL validators for YouTube input — one for home screen, one for process screen.
Bad: Duplicate a 20-line highlight detection algorithm in two places.
```

### Rule DRY-03: Configuration DRY (HARD)

All configurable values (timeouts, retry counts, polling intervals, clip options) live in `lib/core/utils/constants.dart`. No magic numbers anywhere else.

---

## 7. KISS Rules

### Rule KISS-01: Method length limit (SOFT)

Every function must fit on one screen (≤30 lines, including blank lines). If a function exceeds 30 lines, extract helper functions.

### Rule KISS-02: Widget depth limit (SOFT)

Maximum widget nesting depth: 5 levels of custom widgets. Deeply nested widget trees indicate missing extractions.

### Rule KISS-03: Single level of abstraction (SOFT)

A function must not mix high-level orchestration with low-level implementation details.

```
Good:
void _handleSubmit() {
  _validateUrl();
  _startProcessing();
  _startPolling();
}

void _validateUrl() { /* regex check */ }
void _startProcessing() { /* API call */ }
void _startPolling() { /* timer logic */ }

Bad:
void _handleSubmit() {
  if (!_urlRegex.hasMatch(state.url)) {
    emit(state.copyWith(error: 'Invalid URL'));
    return;
  }
  final response = await _dio.post('/process', data: {'url': state.url});
  final projectId = response.data['id'];
  _timer = Timer.periodic(Duration(seconds: 2), ...);
}
```

### Rule KISS-04: Boolean parameter ban (SOFT)

Never pass a boolean flag to a function to change its behavior. Extract two functions instead.

```
Good: Renderer.exportVertical() / Renderer.exportHorizontal()
Bad: Renderer.export(vertical: true)
```

---

## 8. YAGNI Rules

### Rule YAGNI-01: Interface for one implementation (HARD)

If a repository interface has exactly one implementation and no planned second implementation, skip the interface. Add one when the second implementation appears.

Exception: Interface required for test mocking. In that case, keep the interface but document it as test-only with `// ponytail: for testing, add second impl when X`.

### Rule YAGNI-02: Config for one environment (SOFT)

Don't create environment config files, feature flags, or abstraction layers for features that don't exist yet. Hardcode values until a second environment/configuration exists.

### Rule YAGNI-03: Abstract base classes (HARD)

Never create abstract base classes for the purpose of "future extensibility." Use sealed unions or concrete classes. Add abstraction when you need the second variant.

### Rule YAGNI-04: Extra constructor parameters (ADVISORY)

If a parameter has no current use case, don't add it "just in case." Add it when the use case arrives.

---

## 9. Bloc Rules

### Rule BLOC-01: Feature-per-Bloc (HARD)

Every feature screen gets exactly one Bloc. Never share a Bloc across screens. Never create a Bloc that is not tied to a route.

### Rule BLOC-02: State union completeness (HARD)

State union must cover: initial, loading, data/valid, error. Form features additionally need valid/invalid sub-states. Never skip `initial` — even if it transitions immediately.

### Rule BLOC-03: Exhaustive handling (HARD)

Use `state.when()` or `state.map()` for state handling. `state is SomeState` is **forbidden**. Compile-time exhaustive checking prevents missed states.

```
Good:
state.when(
  initial: () => SizedBox.shrink(),
  valid: (url, count) => SubmitButton(count: count),
  invalid: (error) => ErrorBanner(error),
  loading: () => LoadingIndicator(),
  error: (msg) => ErrorScreen(message: msg),
);

Bad:
if (state is Initial) return SizedBox.shrink();
if (state is HomeValid) return SubmitButton();  // silently ignores new states
```

### Rule BLOC-04: `close()` cleanup (HARD)

Every Bloc that uses `Timer`, `StreamSubscription`, or `AnimationController` must override `close()` and cancel/dispose them:

```
@override
Future<void> close() {
  _pollTimer?.cancel();
  _progressSubscription?.cancel();
  return super.close();
}
```

### Rule BLOC-05: Scoped provider (HARD)

BlocProvider must be scoped to the feature route — never global. Use `BlocProvider<T>(create: ...)` at the route level in GoRouter.

### Rule BLOC-06: Bloc-to-Repository only (HARD)

Bloc depends on Repository interface — never on DataSource, never on Dio, never on Hive.

### Rule BLOC-07: Event naming (SOFT)

Events are past tense or imperative: `UrlChanged`, `ClipCountSelected`, `SubmitRequested`, `PollingTimedOut`. Not `ChangeUrl`, `SelectCount`, `DoSubmit`.

### Rule BLOC-08: Single emit per event handler (ADVISORY)

An event handler should emit at most 2 states (loading → loaded, or loading → error). Long chains of emits indicate a need to split events.

---

## 10. Freezed Rules

### Rule FRZ-01: All entities are Freezed (HARD)

Every domain entity, DTO, state, and event must be a `@freezed` class with `@immutable` annotation. No manual `==`/`hashCode` overrides.

### Rule FRZ-02: Union vs sealed class (SOFT)

Use Freezed union (sealed) types for Bloc states and events where each case has different properties. Use simple `@freezed` class for entities where a single shape suffices.

```
// Union — different shapes
@freezed
sealed class ProjectState with _$ProjectState {
  const factory ProjectState.initial() = _Initial;
  const factory ProjectState.loading() = _Loading;
  const factory ProjectState.done(Project project, List<Clip> clips) = _Done;
  const factory ProjectState.error(String message) = _Error;
}

// Simple entity — single shape
@freezed
class Project with _$Project {
  const factory Project({
    required String id,
    required String url,
    required int clipCount,
    required ProjectStatus status,
  }) = _Project;
}
```

### Rule FRZ-03: `copyWith` scope (ADVISORY)

Use `copyWith` only for mutable-like state transitions within Blocs. Never expose `copyWith` outside the feature folder — DTOs and entities should be immutable externally.

### Rule FRZ-04: Equality default (HARD)

Rely on Freezed-generated `==` and `hashCode`. Never add custom equality logic. If custom equality is needed, reconsider the model design — a different union case may be needed.

---

## 11. Injectable Rules

### Rule INJ-01: Module registration per layer (SOFT)

Register dependencies in modules organized by layer:

```dart
@module
abstract class DataModule {
  @lazySingleton
  Dio get dio => createDioClient();

  @Named('baseUrl')
  String get baseUrl => AppConstants.baseUrl;
}

@module
abstract class RepositoryModule {
  @lazySingleton
  ProjectRepository get projectRepository => ProjectRepositoryImpl(
    getIt<ProjectApiDataSource>(),
    getIt<ProjectLocalDataSource>(),
  );
}
```

### Rule INJ-02: Scope decision table (HARD)

| Scope            | When                                                   | Example                            |
| ---------------- | ------------------------------------------------------ | ---------------------------------- |
| `@singleton`     | Identical instance needed across entire app            | `Dio`, `Hive boxes`, `Loggers`     |
| `@lazySingleton` | Singleton but expensive to create, create on first use | `ApiDataSource`, `RepositoryImpl`  |
| `@factory`       | New instance on every injection                        | `Bloc` (scoped via `BlocProvider`) |

### Rule INJ-03: No manual `getIt()` in feature code (SOFT)

Feature code must receive dependencies via constructor injection. `GetIt.I()` direct calls are only allowed in `bootstrap.dart`, `app_router.dart`, and DI modules.

### Rule INJ-04: Test overrides (HARD)

Tests must override real dependencies with mocks via `GetIt.I().pushNewScope()` or `getIt.reset()`:

```dart
setUp(() {
  getIt.reset();
  getIt.registerFactory<ProjectRepository>(() => MockProjectRepository());
});
```

---

## 12. GoRouter Rules

### Rule ROUTE-01: One router file (HARD)

All routes are defined in `lib/core/router/app_router.dart`. No route definitions outside this file.

### Rule ROUTE-02: Route name constants (SOFT)

Route paths are defined as constants in `app_router.dart`:

```dart
static const homePath = '/';
static const processPath = '/process';
static const downloadPath = '/download/:projectId';
```

### Rule ROUTE-03: BlocProvider in route (HARD)

BlocProviders are attached to routes, not to the widget tree:

```dart
GoRoute(
  path: '/process',
  builder: (context, state) => BlocProvider(
    create: (_) => getIt<ProcessBloc>(),
    child: const ProcessScreen(),
  ),
)
```

### Rule ROUTE-04: Redirect guards (ADVISORY)

If a route requires a pre-condition (e.g., project exists), use `redirect` with a guard function. Keep guards minimal — not for business logic.

### Rule ROUTE-05: Deep link support (ADVISORY)

Route paths must use path parameters (not query parameters) for resource identifiers:

```
Good: /download/abc-123
Bad:  /download?projectId=abc-123
```

---

## 13. Hive Rules

### Rule HIVE-01: Box naming convention (SOFT)

Box names are `snake_case`: `project_cache`, `settings`, `download_queue`.

### Rule HIVE-02: TypeAdapter registration (HARD)

Every custom type stored in Hive must have a registered TypeAdapter. Registration happens in `bootstrap.dart` before `runApp()`:

```dart
void bootstrap() async {
  await Hive.initFlutter();
  Hive.registerAdapter(ProjectDtoAdapter());
  Hive.registerAdapter(ProjectStatusDtoAdapter());
  await Hive.openBox<ProjectDto>('project_cache');
  runApp(const ClipForgeApp());
}
```

### Rule HIVE-03: Migration versioning (ADVISORY)

When a model changes, increment the TypeAdapter `typeId` and write an `adapterVersion` getter. Never change an existing adapter — create a new one.

```dart
@HiveType(typeId: 1, adapterName: 'ProjectDtoV1Adapter')
class ProjectDtoV1 extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String url;
}
```

### Rule HIVE-04: Error handling (HARD)

Hive operations must be wrapped in try-catch. Flutter apps crash silently on `late final` Box access — always check `isOpen` before operations:

```dart
Future<List<ProjectDto>> getCachedProjects() async {
  try {
    final box = Hive.box<ProjectDto>('project_cache');
    return box.values.toList();
  } catch (e) {
    logger.warning('Failed to read project cache', e);
    return [];
  }
}
```

---

## 14. Dio Rules

### Rule DIO-01: Interceptor order (SOFT)

Interceptors are added in this order: Logger → Auth (future) → Retry → Error mapper.

```dart
final dio = Dio()
  ..interceptors.addAll([
    LogInterceptor(requestBody: true, responseBody: true),
    AuthInterceptor(),
    RetryInterceptor(dio: dio, retries: 2),
    ErrorMapperInterceptor(),
  ]);
```

### Rule DIO-02: Retry policy (HARD)

Retry only on 5xx status codes (server errors). Never retry on 4xx (client errors). Max 2 retries. Exponential backoff: 1s, 2s.

### Rule DIO-03: Timeout constants (HARD)

```dart
connectTimeout: const Duration(seconds: 10),
receiveTimeout: const Duration(seconds: 30),
```

Timeouts are constants in `lib/core/utils/constants.dart`.

### Rule DIO-04: Cancel tokens (SOFT)

Cancellable requests (polling, download) must accept an optional `CancelToken`:

```dart
Future<ProjectDto> getProject(String id, {CancelToken? cancelToken}) async {
  final response = await dio.get(
    '/projects/$id',
    cancelToken: cancelToken,
  );
  return ProjectDto.fromJson(response.data);
}
```

### Rule DIO-05: Error mapping (HARD)

Dio exceptions must be mapped to the Failure sealed hierarchy. Raw `DioException` never escapes the DataSource layer.

```dart
Failure _mapDioError(DioException e) => switch (e.type) {
  DioExceptionType.connectionTimeout => NetworkFailure('Connection timed out'),
  DioExceptionType.receiveTimeout => NetworkFailure('Server not responding'),
  DioExceptionType.badResponse => ServerFailure(
    statusCode: e.response?.statusCode ?? 0,
    message: e.response?.data?['message'] ?? 'Unknown server error',
  ),
  DioExceptionType.cancel => const CancelledFailure(),
  _ => NetworkFailure('Network error: ${e.message}'),
};
```

---

## 15. Widget Rules

### Rule WIDGET-01: const constructors mandatory (HARD)

Every widget that does not use `BlocProvider.watch`, `context.watch`, or `MediaQuery` must have a `const` constructor.

```
Good: const SubmitButton({super.key, required this.label})
Bad:  SubmitButton({Key? key, required this.label})  // missing const
```

### Rule WIDGET-02: Extraction threshold (SOFT)

Extract a widget at 40 lines. Any widget rendering more than one conditional branch or list item must be a separate widget file.

### Rule WIDGET-03: No business logic (HARD)

Widgets dispatch events and render states. They do not call repositories, make API calls, or perform calculations longer than 3 lines.

### Rule WIDGET-04: Build method structure (SOFT)

Build methods follow this order:

1. `final` state variables from Bloc
2. Conditional early returns (loading, error)
3. Main widget tree (Scaffold, Column, ListView)
4. Helper methods below (if any)

### Rule WIDGET-05: Styling extraction (ADVISORY)

Inline `SizedBox`, `Padding`, `EdgeInsets`, `BorderRadius` values of 4+ are extracted to constants. Values 1-3 can stay inline.

---

## 16. Performance Rules

### Rule PERF-01: RepaintBoundary placement (SOFT)

Isolate widgets below `BlocBuilder` in `RepaintBoundary`. Static widgets (headers, bottom nav) inside `RepaintBoundary`.

```dart
Column(
  children: [
    const RepaintBoundary(child: AppHeader()),  // static
    RepaintBoundary(
      child: BlocBuilder<ProcessBloc, ProcessState>(
        builder: (context, state) { /* dynamic */ },
      ),
    ),
  ],
)
```

### Rule PERF-02: ListView.builder mandatory (HARD)

Any list with >5 items must use `ListView.builder`. `Column` with `children:` is acceptable only for ≤5 known items.

### Rule PERF-03: Image cache sizing (SOFT)

Set `width` and `height` on images. Avoid `Image.network` without cacheWidth/cacheHeight — they decode at full resolution.

### Rule PERF-04: Avoid rebuild cascades (HARD)

`BlocBuilder` must use `buildWhen` to avoid unnecessary rebuilds:

```dart
BlocBuilder<ProcessBloc, ProcessState>(
  buildWhen: (prev, curr) => curr.maybeWhen(
    progress: (_) => true,
    orElse: () => false,
  ),
  builder: (context, state) => ProgressBar(state.progress),
)
```

### Rule PERF-05: Widgets per frame budget (ADVISORY)

Keep build() under 16ms (60fps). If build time exceeds 100ms, extract into `addPostFrameCallback` or isolate.

---

## 17. Async Rules

### Rule ASYNC-01: StreamSubscription dispose (HARD)

Every `StreamSubscription` must have `cancel()` called in `dispose()` or `close()`. Failure to dispose causes memory leaks.

```dart
@override
Future<void> close() {
  _subscription.cancel();
  return super.close();
}
```

### Rule ASYNC-02: Unawaited futures guard (HARD)

Fire-and-forget futures must be suppressed with `// ignore: unawaited_futures` — but only when the future truly doesn't need awaiting. Prefer `unawaited()` wrapper.

```dart
unawaited(_repository.logEvent(eventType));  // fire and forget, intentional
```

### Rule ASYNC-03: Completer forbidden (HARD)

`Completer` is forbidden. Use `Future` constructors or `async`/`await` instead. Completers hide exceptions and create untrackable futures.

### Rule ASYNC-04: `buildWhen`, `listenWhen` for streams (SOFT)

Always use `buildWhen`/`listenWhen` on Bloc listeners when only a subset of states needs attention.

### Rule ASYNC-05: Isolate for heavy computation (ADVISORY)

JSON parsing of large responses, video metadata extraction, or any computation >100ms must run in an isolate using `Isolate.run()` or `compute()`.

---

## 18. Error Handling Rules

### Rule ERR-01: Failure sealed hierarchy (HARD)

All errors are represented as a sealed `Failure` type. Raw `Exception` or `Error` objects never cross layer boundaries.

```dart
@freezed
sealed class Failure with _$Failure {
  const factory Failure.network({required String message}) = NetworkFailure;
  const factory Failure.server({required int statusCode, required String message}) = ServerFailure;
  const factory Failure.parse({required String message}) = ParseFailure;
  const factory Failure.cancelled() = CancelledFailure;
  const factory Failure.unknown({String? message}) = UnknownFailure;
}
```

### Rule ERR-02: Try-catch scoping (HARD)

`try` blocks must be as narrow as possible. Never wrap an entire function body in try-catch.

```
Good:
try {
  final data = await dio.get('/projects/$id');
} on DioException catch (e) {
  return _mapDioError(e);
}

Bad:
try {
  // 50 lines of logic
} catch (e) {
  return Failure.unknown(message: e.toString());
}
```

### Rule ERR-03: Error boundary widgets (ADVISORY)

Every screen wrapped in a `BlocListener` for error states that shows a `SnackBar` or navigates to error screen. Errors are user-visible and actionable (retry action).

### Rule ERR-04: No silent catches (HARD)

Every `catch` block must either: (a) return a Failure, (b) log + rethrow, or (c) log + show user feedback. `catch (e) {}` with empty body is forbidden.

---

## 19. Null Safety Rules

### Rule NULL-01: `!` operator forbidden (HARD)

The `!` (null assertion) operator is forbidden. Use pattern matching, `?.` with fallback, or `??` instead.

```
Good:  final name = user.name ?? 'Anonymous';
Good:  if (user case User(name: final n)) useName(n);
Bad:   final name = user!.name!;
```

### Rule NULL-02: `late` limited to DI (SOFT)

`late` is allowed only in two cases:

1. DI-injected fields in Blocs/Repositories (where GetIt guarantees non-null)
2. `late final` for controllers initialized in `initState()` (AnimationController, TextEditingController)

Never use `late` for values that could genuinely be null.

### Rule NULL-03: `required` over positional (SOFT)

Constructor parameters must use `required named` parameters if the value can be null or has no sensible default. Positional optional parameters are only for values with a clear default.

```
Good: const SubmitButton({super.key, required this.label, this.isDisabled = false})
Bad:  const SubmitButton(this.label, [this.isDisabled])
```

### Rule NULL-04: Null-aware cascade (ADVISORY)

Use `?..` cascade for operations on nullable receivers.

```dart
state.project?.toDomain()
  ?..validate()
  ..export();
```

---

## 20. Logging Rules

### Rule LOG-01: Level map (SOFT)

| Level     | When                                       | Example                                                 |
| --------- | ------------------------------------------ | ------------------------------------------------------- |
| `info`    | Normal flow (state transitions, API calls) | `info('Project $id status: done')`                      |
| `warning` | Recoverable errors, retries                | `warning('API retry #2 for project $id')`               |
| `error`   | Unrecoverable errors, exceptions           | `error('Failed to process project $id', e, stackTrace)` |
| `fine`    | Debug details (polling, timer ticks)       | `fine('Polling project $id: attempt $n')`               |

### Rule LOG-02: Context enrichment (SOFT)

Log messages include feature name, bloc name, and relevant identifiers:

```dart
logger.info('[ProcessBloc] Project $projectId: polling attempt $attempt');
```

### Rule LOG-03: No PII (HARD)

Never log: user IP addresses, full names, email addresses, or any data that could identify a person. Log anonymized IDs only.

### Rule LOG-04: Structured format (ADVISORY)

Use structured logging format: `[Feature] Message {key: value}`

### Rule LOG-05: No `print` statements (HARD)

`print()` is forbidden. All logging uses `Logger` from `logging` package or `talker_flutter`. Lint must flag `print` statements (built-in `avoid_print`).

---

## 21. Documentation Rules

### Rule DOC-01: Public API documentation (SOFT)

Every public class, method, and top-level function must have a doc comment explaining **why** (not what).

```
Good:
/// Maximum number of clips a user can request in one batch.
/// Limited to 10 to balance backend processing time and user expectation.
const maxClipCount = 10;

Bad:
/// Max clip count constant.
const maxClipCount = 10;
```

### Rule DOC-02: TODO format (HARD)

```dart
// TODO(author): YYYY-MM-DD - Description. Issue: #123
```

Example:

```dart
// TODO(macbook): 2026-07-03 - Add retry logic for network failures. Issue: #42
```

### Rule DOC-03: Inline comment limits (ADVISORY)

One inline comment per 20 lines of code. If more comments are needed, extract to a well-named function.

### Rule DOC-04: Magic number documentation (SOFT)

Every non-obvious constant value needs a comment explaining where it came from:

```dart
// YouTube Data API quota: 10,000 units/day per project
const ytQuotaLimit = 10000;
```

---

## 22. Testing Rules

### Rule TEST-01: `given_when_then` naming (SOFT)

Test names follow the pattern: `given_[condition]_when_[action]_then_[expected]`.

```dart
test('given valid URL, when SubmitRequested, then emits ProcessBlocProcessing', () { ... });
test('given network error, when SubmitRequested, then emits ProcessBlocError with message', () { ... });
```

### Rule TEST-02: Test structure (SOFT)

Every test has three sections separated by blank lines:

```dart
test('given ...', () {
  // Arrange
  final mockRepo = MockProjectRepository();

  // Act
  bloc.add(const SubmitRequested(url: 'https://youtube.com/watch?v=abc', clipCount: 3));

  // Assert
  expect(bloc.state, isA<Processing>());
});
```

### Rule TEST-03: Mock policy (HARD)

Use `mocktail` for all mocks. Never create manual mock classes. Register fallback values for required parameters.

### Rule TEST-04: Golden tests for stable UI only (ADVISORY)

Golden tests are only added when the widget tree is finalized. Prefer widget tests with `find.text()` and `pump()` for dynamic UI.

### Rule TEST-05: Integration test coverage (SOFT)

Each feature must have exactly one integration test covering the happy path. Error path integration tests use mocked Dio interceptor to simulate failures.

### Rule TEST-06: Test isolation (HARD)

Tests must not share state. `setUp` creates fresh instances. `tearDown` closes blocs, disposes widgets, and resets mocks.

---

## 23. Code Review Checklist

Every code review checks these items. The AI presents this checklist as part of the review stage.

### Architecture

- [ ] No layer violations (domain → data, domain → presentation, data → presentation)
- [ ] Repository pattern followed (Presentation → Domain interface → Data impl)
- [ ] Feature isolation maintained (no cross-feature imports)
- [ ] YAGNI pass applied (no unused abstractions)

### Bloc

- [ ] Exhaustive `when()`/`map()` used — no `is` checks
- [ ] State union has all required cases (initial, loading, data, error)
- [ ] `close()` overridden with Timer/Subscription cleanup
- [ ] BlocProvider scoped to route (not global)
- [ ] Bloc depends on Repository interface (not DataSource)
- [ ] Events named past tense/imperative

### Widget

- [ ] `const` constructors on all widgets
- [ ] No business logic in widget tree
- [ ] Widgets <200 lines, functions <30 lines
- [ ] `buildWhen`/`listenWhen` used (not unnecessary rebuilds)
- [ ] `ListView.builder` for lists >5 items
- [ ] Hardcoded values absent (uses Design System tokens)

### DI & Routing

- [ ] No `GetIt.I()` calls in feature code
- [ ] Route paths in `app_router.dart` only
- [ ] BlocProvider attached to route, not widget
- [ ] DI scope correct (@singleton vs @lazySingleton vs @factory)

### Error Handling

- [ ] Failure sealed class used (no raw exceptions)
- [ ] No empty catch blocks
- [ ] User-visible errors (SnackBar or error screen)
- [ ] Retry options on transient errors

### Performance

- [ ] RepaintBoundary placed correctly
- [ ] Image cacheWidth/cacheHeight set
- [ ] No unnecessary rebuilds (buildWhen checked)
- [ ] Memory usage: no unclosed streams, no Timer leaks

---

## 24. Definition of Done

A feature is "Done" only when all 6 gates pass:

### Gate 1: Code Complete

- [ ] All ACs from PRD implemented
- [ ] All files created per architecture plan
- [ ] No TODOs without owner

### Gate 2: Tests Pass

- [ ] Unit tests: all Bloc state transitions covered
- [ ] Widget tests: all visual states covered
- [ ] Integration test: happy path passes
- [ ] Coverage ≥80% (reported)

### Gate 3: Lint Clean

- [ ] `flutter analyze` — 0 errors, 0 warnings
- [ ] `dart format` — no changes needed

### Gate 4: Review Approved

- [ ] Code Review Checklist adopted — 0 violations
- [ ] Human review approval obtained

### Gate 5: Acceptance Criteria Met

- [ ] All ACs from PRD verified on device/emulator
- [ ] Ground truth test passes (paste URL, select clips, process, download)

### Gate 6: No Regression

- [ ] Existing tests still pass
- [ ] Existing features unaffected
- [ ] Memory profile stable (DevTools)

---

## 25. Forbidden Practices

| #   | Practice                                           | Reason                                            | Alternative                     |
| --- | -------------------------------------------------- | ------------------------------------------------- | ------------------------------- |
| 1   | `if (state is SomeState)`                          | Breaks exhaustive checking when new states added  | `state.when()`                  |
| 2   | `print()`                                          | No log levels, no structure, no context           | `Logger`                        |
| 3   | `GetIt.I()` in feature code                        | Hardcodes DI, makes testing impossible            | Constructor injection           |
| 4   | `Completer<T>()`                                   | Creates untrackable futures, hides exceptions     | `async/await`                   |
| 5   | Null assertion `!`                                 | Hides null safety bugs until runtime              | Pattern matching or `??`        |
| 6   | `BuildContext` stored in a field                   | Causes memory leaks, widget not disposed          | Use `BuildContext` locally only |
| 7   | `Timer` without `cancel()` in `close()`            | Memory leak, ghost callbacks after dispose        | Always cancel in `close()`      |
| 8   | Direct DataSource access from Presentation         | Bypasses Repository, breaks layer isolation       | Repository pattern              |
| 9   | Hardcoded strings (colors, sizes, messages)        | No theming, no i18n, impossible to maintain       | Design System tokens, Constants |
| 10  | `setState()` in widgets with Bloc                  | Mixes state management, bypasses Bloc             | Bloc events                     |
| 11  | `late final` without initialization in `initState` | Runtime null error if called before init          | Use `late final` only for DI    |
| 12  | Duplicate >5 lines without extraction              | Violates DRY, increases maintenance               | Extract on 3rd occurrence       |
| 13  | `try { wholeFunction() }`                          | Swallows specific errors, hard to debug           | Narrow try-catch per operation  |
| 14  | `@visibleForTesting` without testing the method    | Lies about visibility, tests should be behavioral | Test public API only            |
| 15  | `build()` with >100ms execution                    | Causes jank                                       | Extract heavy work to isolate   |

---

## 26. Examples of Good vs Bad Design

### Example 1: Bloc Exhaustiveness

```
Good:
state.when(
  initial: () => SizedBox.shrink(),
  valid: (url, count) => SubmitForm(url: url, count: count),
  invalid: (msg) => ErrorBanner(message: msg),
  loading: () => LoadingIndicator(),
  error: (msg) => ErrorScreen(message: msg, onRetry: () => add(RetryRequested())),
);

// When a new state `ProcessBloc.paused` is added, the compiler forces every when() to handle it.
```

```
Bad:
if (state is Initial) return SizedBox.shrink();
if (state is HomeValid) return SubmitForm(/* ... */);

// Adding a new state `Paused` silently bypasses all handlers. No compiler warning.
```

### Example 2: Widget Composition

```
Good:
class ProcessScreen extends StatelessWidget {
  const ProcessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      body: BlocProvider(
        create: (_) => getIt<ProcessBloc>(),
        child: const _ProcessBody(),
      ),
    );
  }
}

// _ProcessBody extracted because generate() method exceeded 40 lines
// ponytail: extract to separate file when a third variant appears
```

```
Bad:
class ProcessScreen extends StatefulWidget {
  @override
  _ProcessScreenState createState() => _ProcessScreenState();
}

class _ProcessScreenState extends State<ProcessScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Process')),
      body: BlocProvider(
        create: (_) => getIt<ProcessBloc>(),
        child: Column(children: [
          // 80 lines of UI
        ]),
      ),
    );
  }
}

// Bloated build method, StatefulWidget not needed, no extraction.
```

### Example 3: Error Handling

```
Good:
Future<Project> getProject(String id) async {
  try {
    final dto = await _api.getProject(id);
    return dto.toDomain();
  } on DioException catch (e) {
    return Failure.network(message: e.message ?? 'Network error');
  } on FormatException catch (e) {
    return Failure.parse(message: 'Invalid response format: ${e.message}');
  } catch (e, st) {
    logger.error('Unexpected error fetching project $id', e, st);
    return Failure.unknown(message: 'Something went wrong');
  }
}

// Narrow catches, specific error types, failure returned, edge cases logged.
```

```
Bad:
Future<Project> getProject(String id) async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/projects/$id'));
    final json = jsonDecode(response.body);
    return Project(id: json['id'], url: json['url'], /* ... */);
  } catch (e) {
    throw Exception('Failed to get project: $e');
  }
}

// Throws raw Exception, no error type distinction, no logging, manual JSON parsing.
```

### Example 4: Dependency Injection

```
Good:
class ProcessBloc {
  final ProjectRepository _repository;

  ProcessBloc({required ProjectRepository repository})
      : _repository = repository;
}

// Testable: inject MockProjectRepository
```

```
Bad:
class ProcessBloc {
  final _repository = ProjectRepositoryImpl(
    ApiDataSource(GetIt.I<Dio>()),
    LocalDataSource(GetIt.I<Box<ProjectDto>>()),
  );
}

// Not testable (hardcoded impl), uses GetIt.I() in feature code.
```

### Example 5: Async Lifecycle

```
Good:
class ProcessBloc extends Bloc<ProcessEvent, ProcessState> {
  Timer? _timer;

  void _startPolling(String projectId) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      add(_PollTick(projectId));
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

// Timer lifecycle managed, cancel on close, existing timer cancelled before new one.
```

```
Bad:
class ProcessBloc extends Bloc<ProcessEvent, ProcessState> {
  Timer? _timer;

  void _startPolling(String projectId) {
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      add(_PollTick(projectId));
    });
  }

  // No close() override — _timer leaks when Bloc is disposed
}
```

### Example 6: State Selection

```
Good:
BlocBuilder<ProjectBloc, ProjectState>(
  buildWhen: (prev, curr) => curr.maybeWhen(
    progress: (_) => true,
    orElse: () => false,
  ),
  builder: (context, state) => state.maybeWhen(
    progress: (pct) => LinearProgressIndicator(value: pct / 100),
    orElse: () => SizedBox.shrink(),
  ),
);

// Builds only on progress state, uses maybeWhen for non-exhaustive matching.
```

```
Bad:
BlocBuilder<ProjectBloc, ProjectState>(
  builder: (context, state) {
    if (state is ProjectProgress) {
      return LinearProgressIndicator(value: state.progress / 100);
    }
    return SizedBox.shrink();
  },
);

// Rebuilds on every state change, uses `is` check (violates BLOC-03).
```
