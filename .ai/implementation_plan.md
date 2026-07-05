# Implementation Plan — AI YouTube Clipper (Flutter)

> **Document Version:** 1.0.0
> **Last Updated:** 2026-07-03
> **Author:** Flutter Tech Lead / AI Software Architect
> **Status:** Active
> **Scope:** MVP Implementation Blueprint — Cline ACT MODE reference

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Development Order](#2-development-order)
3. [Folder Creation Order](#3-folder-creation-order)
4. [Screen Implementation Order](#4-screen-implementation-order)
5. [Component Implementation Order](#5-component-implementation-order)
6. [Theme Implementation Order](#6-theme-implementation-order)
7. [Navigation Strategy](#7-navigation-strategy)
8. [State Management Strategy](#8-state-management-strategy)
9. [Performance Strategy](#9-performance-strategy)
10. [Quality Gates](#10-quality-gates)
11. [Common Pitfalls](#11-common-pitfalls)
12. [AI Working Rules](#12-ai-working-rules)

---

## 1. Project Overview

### 1.1 One-Pager

**What is being built:** A Flutter mobile application (AI YouTube Clipper) that allows users to paste a YouTube URL, select how many short clips to generate (1, 3, 5, or 10), and receive vertical 9:16 videos with embedded subtitles. The backend (FastAPI + Python) handles video download, transcription, highlight detection, and subtitle burning. The Flutter app handles URL input, clip count selection, progress display, download, and preview.

**What is NOT being built (MVP):**

- Timeline / video editor
- Subtitle editor
- User authentication / accounts
- Cloud sync
- AI-generated titles or thumbnails
- Multi-language subtitle support
- Custom highlight preferences (free text)
- Desktop or web layouts
- Notifications (push or local)

**MVP Scope:**

- 7 screens: Splash → Home → New Project → Processing → Results → Clip Detail → Settings
- 18 reusable components (AppScaffold through AppFAB)
- Complete dark/light theme with design tokens
- Bloc state management per feature
- GoRouter navigation
- API integration via Dio + Repository pattern
- Local project cache via Hive
- Full loading, empty, error states for every screen
- VoiceOver/TalkBack accessibility
- Responsive breakpoints (360dp to 839dp)

**Target Platforms:** iOS 15+, Android API 26+. Phone-first. Foldable/tablet adapted but not optimized.

**Dependencies (pubspec.yaml):**

- flutter_bloc (state management)
- freezed + freezed_annotation (data classes)
- injectable + get_it (dependency injection)
- go_router (navigation)
- hive + hive_flutter (local storage)
- dio (HTTP client)
- cached_network_image (image caching)
- media_kit (video player)
- flutter_lucide (icons)
- shimmer (loading skeletons)
- equatable (value equality)

---

## 2. Development Order

### 2.1 Phase Sequence

```
Phase  1: Project Scaffolding
Phase  2: Theme + Design Tokens
Phase  3: Shared Components (all 18)
Phase  4: Navigation Shell (GoRouter)
Phase  5: Feature — Splash
Phase  6: Feature — Home
Phase  7: Feature — New Project
Phase  8: Feature — Processing
Phase  9: Feature — Results
Phase 10: Feature — Clip Detail
Phase 11: Feature — Settings
Phase 12: API Layer + Integration
Phase 13: Testing + Polish
Phase 14: Release
```

### 2.2 Dependency Graph

```
Project Setup
    ↓
Theme Tokens (colors, typography, spacing, elevation, motion)
    ↓
Shared Components (buttons, cards, text field, chips, progress, dialogs, etc.)
    ↓
Navigation Shell
    ↓
Splash ───────────────────────────────────────┐
    ↓                                         │
Home (needs: AppCard, AppEmptyWidget, AppFAB)  ←─── uses AppScaffold, AppPrimaryButton, AppSecondaryButton
    ↓
New Project (needs: AppTextField, AppChip, AppSkeletonCard)
    ↓
Processing (needs: AppProgressRing, AppProgressCard, AppDestructiveButton)
    ↓
Results (needs: AppVideoCard, AppProgressRing, AppPrimaryButton, share bottom sheet)
    ↓
Clip Detail (needs: MediaKit player, AppPrimaryButton)
    ↓
Settings (needs: AppScaffold, no custom components)
    ↓
API Integration (wires repositories to Dio)
    ↓
Testing + Polish
```

### 2.3 Why This Order

1. **Theme first** — every visual element depends on color, typography, spacing tokens. Building UI without them guarantees inconsistency and rework.
2. **Components before screens** — screens are compositions of reusable widgets. Building screens without components guarantees duplication.
3. **Navigation before features** — you need the route map to verify screen transitions, back navigation, and parameter passing early.
4. **Splash first** — zero dependencies, validates the entire navigation pipeline, quick confidence win.
5. **New Project before Processing** — the form is the input for Processing. Processing state is driven by New Project submission.
6. **Results before Clip Detail** — Clip Detail is a detail view of Results. Results grid is the parent.
7. **API layer last** — the app can be fully built and tested with mock data. API integration is the final wiring step.

---

## 3. Folder Creation Order

### 3.1 Exact Folder Creation Sequence

```
lib/
├── core/                              # 1st — foundation layer
│   ├── theme/
│   │   ├── tokens/
│   │   │   ├── color_tokens.dart
│   │   │   ├── typography_tokens.dart
│   │   │   ├── spacing_tokens.dart
│   │   │   ├── radius_tokens.dart
│   │   │   ├── elevation_tokens.dart
│   │   │   └── motion_tokens.dart
│   │   ├── extensions/
│   │   │   └── theme_extensions.dart
│   │   ├── app_theme.dart              # light + dark ThemeData
│   │   └── theme_provider.dart
│   ├── router/
│   │   └── app_router.dart             # GoRouter config
│   ├── api/
│   │   ├── api_client.dart             # Dio instance
│   │   └── api_endpoints.dart
│   ├── constants/
│   │   └── app_constants.dart
│   └── errors/
│       └── app_exceptions.dart
│
├── shared/                            # 2nd — reusable widgets
│   ├── widgets/
│   │   ├── app_scaffold.dart
│   │   ├── app_primary_button.dart
│   │   ├── app_secondary_button.dart
│   │   ├── app_destructive_button.dart
│   │   ├── app_card.dart
│   │   ├── app_text_field.dart
│   │   ├── app_chip.dart
│   │   ├── app_video_card.dart
│   │   ├── app_progress_ring.dart
│   │   ├── app_progress_card.dart
│   │   ├── app_skeleton_card.dart
│   │   ├── app_empty_widget.dart
│   │   ├── app_error_widget.dart
│   │   ├── app_snackbar.dart
│   │   ├── app_dialog.dart
│   │   ├── app_bottom_sheet.dart
│   │   ├── app_status_badge.dart
│   │   └── app_fab.dart
│   └── helpers/
│       ├── responsive_helper.dart
│       ├── url_validator.dart
│       └── date_formatter.dart
│
├── features/                          # 3rd — feature modules
│   ├── splash/
│   │   └── presentation/
│   │       └── pages/
│   │           └── splash_page.dart
│   │
│   ├── home/
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   └── datasources/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── pages/
│   │       └── widgets/
│   │
│   ├── new_project/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── processing/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── results/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── clip_detail/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── settings/
│       └── presentation/
│           ├── bloc/
│           └── pages/
│
└── main.dart                           # App entry point
```

### 3.2 Folders That Must NEVER Exist

| Never create      | Why                                                                    |
| ----------------- | ---------------------------------------------------------------------- |
| `lib/utils/`      | Becomes a dumping ground. Helpers belong in `shared/helpers/`.         |
| `lib/helpers/`    | Same as `utils/`.                                                      |
| `lib/widgets/`    | Too vague. Widgets are in `shared/widgets/` or `features/*/widgets/`.  |
| `lib/screens/`    | Flat screen folder = no feature ownership. Screens belong in features. |
| `lib/blocs/`      | Global blocs folder = no encapsulation. Blocs belong in features.      |
| `lib/models/`     | Models belong in `features/*/data/` or `domain/entities/`.             |
| `lib/pages/`      | Same as `lib/screens/`.                                                |
| `lib/providers/`  | We use Bloc, not Provider. Don't mix.                                  |
| `lib/mixins/`     | Rarely needed. Put with the feature that uses them.                    |
| `lib/extensions/` | Extensions belong in `core/theme/extensions/` or `shared/helpers/`.    |

### 3.3 Rationale

- **Clean Architecture onion** (`data/` → `domain/` → `presentation/`) per feature ensures separation of concerns. Each layer can be tested independently.
- **No flat folders.** Flat folders scale to 10 files, not 100. Feature-first scales indefinitely.
- **`core/`** is truly cross-cutting. Only things that every feature depends on (theme, router, API client, constants, error types).
- **`shared/`** is for reusable presentation-layer code. Components and helpers used across features.
- **`features/`** are independent modules. One feature per folder. Features never import directly from other features — only from `shared/` and `core/`.

---

## 4. Screen Implementation Order

### 4.1 Order

```
Splash
   ↓
Home
   ↓
New Project
   ↓
Processing
   ↓
Results
   ↓
Clip Detail
   ↓
Settings
```

### 4.2 Splash

**Dependencies:** None. Theme tokens must exist (for colors). GoRouter must exist (for redirect).

**Required Components:**

| Component                   | Why                                |
| --------------------------- | ---------------------------------- |
| `AppScaffold`               | Screen shell                       |
| `CircularProgressIndicator` | Loading spinner (standard Flutter) |

**Acceptance / Completion Criteria:**

- [ ] Shows centered logo "ClipForge" + spinner for 1.5s
- [ ] Auto-navigates to `/home` after delay
- [ ] Dark/light theme applied
- [ ] Spinner has Semantics label
- [ ] No user interaction required
- [ ] No error state (local assets only)

### 4.3 Home

**Dependencies:** `AppScaffold`, `AppEmptyWidget`, `AppErrorWidget`, `AppFAB`, `AppSkeletonCard`, `AppCard` (for project cards). ProjectBloc + ProjectRepository (domain entities defined). GoRouter configured.

**Required Components:**

| Component         | Why                              |
| ----------------- | -------------------------------- |
| `AppScaffold`     | Screen shell                     |
| `AppEmptyWidget`  | Empty state (no projects)        |
| `AppErrorWidget`  | Error state (network failure)    |
| `AppFAB`          | Create new project button        |
| `AppSkeletonCard` | Loading state (3 skeleton cards) |
| `AppCard`         | Project horizontal card          |
| `AppStatusBadge`  | Project status indicator         |

**Acceptance / Completion Criteria:**

- [ ] Loading: 3 skeleton cards, no FAB
- [ ] Empty: AppEmptyWidget + FAB visible (+ Quick Tips card collapsed)
- [ ] Data: project list with thumbnails, titles, dates, status badges
- [ ] Error: AppErrorWidget with retry. FAB still visible.
- [ ] Tap FAB → navigate to `/new`
- [ ] Tap project card → navigate to `/processing/:id` or `/results/:id` based on status
- [ ] Tap settings icon → navigate to `/settings`
- [ ] Overflow menu (⋮) on project card → delete with confirmation dialog
- [ ] Quick Tips card: collapsed by default, hidden after 3 projects
- [ ] Dark/light theme applied consistently
- [ ] Semantics labels on all interactive elements

### 4.4 New Project

**Dependencies:** `AppScaffold`, `AppTextField`, `AppChip`, `AppPrimaryButton`, `AppSecondaryButton`, `AppCard` (preview). NewProjectBloc. URL validator helper.

**Required Components:**

| Component          | Why                                   |
| ------------------ | ------------------------------------- |
| `AppScaffold`      | Screen shell + back button            |
| `AppTextField`     | YouTube URL input + paste detection   |
| `AppChip`          | Clip count selector (1, 3, 5, 10)     |
| `AppPrimaryButton` | Generate Clips CTA                    |
| `AppCard`          | Video preview card (after URL valid)  |
| `AppSkeletonCard`  | Preview loading skeleton              |
| `AppSnackbar`      | "YouTube link detected!" notification |

**Acceptance / Completion Criteria:**

- [ ] Empty URL → chips disabled, Generate disabled
- [ ] Paste detection → pulsing icon, snackbar, validation starts
- [ ] Invalid URL → error text below field, chips hidden, Generate disabled
- [ ] Valid URL → preview appears, chips enabled
- [ ] Chip selected → selected fills primary, others outlined
- [ ] URL valid + count selected → Generate enabled
- [ ] Tap Generate → button loading state → navigate to `/processing/:id`
- [ ] Video preview: thumbnail, title, channel, duration
- [ ] Preview loading: skeleton, on error: inline error message
- [ ] Back button with dirty form → confirm discard dialog
- [ ] Responsive: chips in 2×2 grid on small phone, row on large

### 4.5 Processing

**Dependencies:** `AppScaffold`, `AppProgressRing`, `AppProgressCard`, `AppDestructiveButton`, `AppPrimaryButton` (retry). ProcessBloc. Pipeline step definitions.

**Required Components:**

| Component              | Why                                  |
| ---------------------- | ------------------------------------ |
| `AppScaffold`          | Screen shell + back disabled         |
| `AppProgressRing`      | Circular progress indicator          |
| `AppProgressCard`      | Pipeline step list + status messages |
| `AppDestructiveButton` | Cancel Processing                    |
| `AppPrimaryButton`     | Retry (on error state)               |
| `AppSecondaryButton`   | Back to Home (on error state)        |
| `AppSnackbar`          | Error notifications                  |
| `AppDialog`            | Cancel confirmation                  |

**Acceptance / Completion Criteria:**

- [ ] Processing: ring animating, steps updating, ETA visible
- [ ] Step status: pending (○), active (◉ spinner), done (✅), error (❌)
- [ ] Status messages change per step (3 variants: normal, prolonged, almost done)
- [ ] ETA updates every 10 seconds (via poll or timer)
- [ ] Complete: ring 100% → checkmark burst → auto-navigate to `/results/:id` after 800ms
- [ ] Error: ring stops → colorError transition → error message → retry button
- [ ] Stall (>30s no progress): amber warning banner, "hang tight" message
- [ ] Cancel: confirmation dialog → cancels → navigate to Home
- [ ] Back disabled during processing → cancel dialog
- [ ] Long processing (>3 min): tip/fun fact card appears
- [ ] App minimized → processing continues. Restored state on return.
- [ ] Semantics: liveRegion announcements for step changes

### 4.6 Results

**Dependencies:** `AppScaffold`, `AppVideoCard`, `AppPrimaryButton`, `AppSecondaryButton`, `AppEmptyWidget`, `AppErrorWidget`, `AppSkeletonCard`, `AppStatusBadge`. ResultsBloc.

**Required Components:**

| Component            | Why                                  |
| -------------------- | ------------------------------------ |
| `AppScaffold`        | Screen shell + back button           |
| `AppVideoCard`       | Clip cards with thumbnail + actions  |
| `AppPrimaryButton`   | Download All (fixed bottom)          |
| `AppSecondaryButton` | Generate Again (app bar or below)    |
| `AppEmptyWidget`     | No clips state                       |
| `AppErrorWidget`     | Load failure state                   |
| `AppSkeletonCard`    | Loading state (6 skeleton cards)     |
| `AppStatusBadge`     | Subtitle indicator on clips          |
| `AppProgressRing`    | Download progress on card thumbnails |
| `AppSnackbar`        | Download complete notification       |
| `AppBottomSheet`     | Share action sheet                   |

**Acceptance / Completion Criteria:**

- [ ] Loading: 6 skeleton cards in grid, no Download All button
- [ ] Empty: AppEmptyWidget "No clips generated" with retry
- [ ] Data: clip cards in grid layout (1 col small, 2 col large, 3 col tablet)
- [ ] Each card: 9:16 thumbnail, title, metadata, subtitle badge, duration
- [ ] Each card actions: Preview, Download, Share
- [ ] Download All: fixed bottom, shows progress (X/Y), skips failed clips
- [ ] Individual download: progress overlay on thumbnail → green checkmark on complete
- [ ] Share: bottom sheet with Save, Share to, Copy Link
- [ ] Generate Again: navigates to `/new` with URL pre-filled
- [ ] Staggered card appearance animation (50ms delay per card)
- [ ] Error state: AppErrorWidget with retry

### 4.7 Clip Detail

**Dependencies:** `AppScaffold`, `AppPrimaryButton`, `AppSecondaryButton`, `AppSkeletonCard`. MediaKit player.

**Required Components:**

| Component            | Why                                  |
| -------------------- | ------------------------------------ |
| `AppScaffold`        | Screen shell + back button + actions |
| `AppPrimaryButton`   | Download clip                        |
| `AppSecondaryButton` | Share clip                           |
| `AppSkeletonCard`    | Video player skeleton                |
| `MediaKit`           | Video playback (9:16)                |
| `AppSnackbar`        | Download complete                    |

**Acceptance / Completion Criteria:**

- [ ] Loading: skeleton player + metadata
- [ ] Video player: 9:16 aspect ratio, auto-play (muted), seek bar, time display
- [ ] Play/Pause overlay, toggle
- [ ] Metadata: clip title, index, resolution, file size, subtitle status, duration
- [ ] Download single clip: progress in button → snackbar "Clip downloaded!"
- [ ] Share: bottom sheet with platform options
- [ ] Fullscreen toggle (Maximize2 icon)
- [ ] Dark/light theme on player controls
- [ ] Player error: error overlay with retry icon

### 4.8 Settings

**Dependencies:** `AppScaffold`. SettingsBloc.

**Required Components:**

| Component     | Why                        |
| ------------- | -------------------------- |
| `AppScaffold` | Screen shell + back button |

**Acceptance / Completion Criteria:**

- [ ] Dark mode toggle (System / Light / Dark)
- [ ] Version display (from package info)
- [ ] Licenses link (Flutter LicensePage)
- [ ] Privacy Policy link (external URL)
- [ ] FAQ link (external URL)
- [ ] Contact link (email composer)
- [ ] All options grouped in sections with cards
- [ ] Dark/light theme applied

---

## 5. Component Implementation Order

### 5.1 Build Order

```
Step 1: AppScaffold
Step 2: AppPrimaryButton
Step 3: AppSecondaryButton
Step 4: AppDestructiveButton
Step 5: AppCard
Step 6: AppStatusBadge
Step 7: AppSkeletonCard
Step 8: AppEmptyWidget
Step 9: AppErrorWidget
Step 10: AppVideoCard
Step 11: AppTextField
Step 12: AppChip
Step 13: AppProgressRing
Step 14: AppProgressCard
Step 15: AppFAB
Step 16: AppDialog
Step 17: AppBottomSheet
Step 18: AppSnackbar
```

### 5.2 Rationale

| Step | Component              | Why Here                                                                                           |
| ---- | ---------------------- | -------------------------------------------------------------------------------------------------- |
| 1    | `AppScaffold`          | Every screen needs a shell. Cannot build any screen without this. Foundation component.            |
| 2    | `AppPrimaryButton`     | Every screen has exactly one primary CTA. Must exist before any screen.                            |
| 3    | `AppSecondaryButton`   | Paired with primary button. Needed for retry, cancel, back actions.                                |
| 4    | `AppDestructiveButton` | Needed for cancel/destructive actions. Depends on AppSecondaryButton patterns.                     |
| 5    | `AppCard`              | Home needs cards for project list. New Project needs preview card. Processing needs pipeline card. |
| 6    | `AppStatusBadge`       | Used inside AppVideoCard and project cards. Build before AppVideoCard.                             |
| 7    | `AppSkeletonCard`      | Needed for all loading states. Build before AppEmptyWidget/AppErrorWidget.                         |
| 8    | `AppEmptyWidget`       | Home empty state. Reuses AppPrimaryButton (for CTA).                                               |
| 9    | `AppErrorWidget`       | All error states. Reuses AppSecondaryButton (retry).                                               |
| 10   | `AppVideoCard`         | Results grid cards. Depends on AppCard, AppStatusBadge, AppSkeletonCard.                           |
| 11   | `AppTextField`         | New Project screen. Complex component with paste detection, validation, states.                    |
| 12   | `AppChip`              | New Project clip selector. Paired with Wrap/Row layout.                                            |
| 13   | `AppProgressRing`      | Processing screen. CustomPainter with animation. Independent.                                      |
| 14   | `AppProgressCard`      | Processing pipeline card. Composes AppProgressRing + step list + status.                           |
| 15   | `AppFAB`               | Home screen. Single-use component, least dependent.                                                |
| 16   | `AppDialog`            | Dialogs depend on buttons existing. Build after all buttons.                                       |
| 17   | `AppBottomSheet`       | Share actions. Depends on designs and icons. Last overlay component.                               |
| 18   | `AppSnackbar`          | Notifications. Depends on ScaffoldMessenger.                                                       |

---

## 6. Theme Implementation Order

### 6.1 Build Sequence

```
Step 1: Color Tokens
Step 2: Typography Tokens
Step 3: Spacing Tokens
Step 4: Radius Tokens
Step 5: Elevation Tokens
Step 6: Motion Tokens
Step 7: ThemeExtension class (combines all tokens)
Step 8: Light ThemeData
Step 9: Dark ThemeData
Step 10: ThemeProvider widget (applies theme + switches)
```

### 6.2 Rationale

| Step | Token             | Why Here                                                                                                      |
| ---- | ----------------- | ------------------------------------------------------------------------------------------------------------- |
| 1    | Color Tokens      | Foundation. Shadows need colors, text styles need colors, buttons need colors. No dependency on other tokens. |
| 2    | Typography Tokens | Text styles need color tokens (for base color). Otherwise independent.                                        |
| 3    | Spacing Tokens    | Pure numeric values. No dependencies. Can be values only.                                                     |
| 4    | Radius Tokens     | Pure numeric values. No dependencies.                                                                         |
| 5    | Elevation Tokens  | Need color tokens (shadow color).                                                                             |
| 6    | Motion Tokens     | Pure duration/curve values. No dependencies.                                                                  |
| 7    | ThemeExtension    | Combines all token classes into one accessible extension. Must wait for all tokens.                           |
| 8    | Light ThemeData   | Uses ThemeExtension + system defaults (AppBar, Card, etc.). Needs everything.                                 |
| 9    | Dark ThemeData    | Mirrors light with dark color tokens. Needs all tokens.                                                       |
| 10   | ThemeProvider     | Watches dark mode toggle, switches ThemeData. Depends on both light/dark.                                     |

### 6.3 Token File Structure

```dart
// lib/core/theme/tokens/color_tokens.dart
class ColorTokens extends ThemeExtension<ColorTokens> { ... }

// lib/core/theme/tokens/typography_tokens.dart
class TypographyTokens extends ThemeExtension<TypographyTokens> { ... }

// lib/core/theme/app_theme.dart
final lightTheme = ThemeData(
  extensions: [colorTokens, typographyTokens, spacingTokens, ...],
  // standard theme properties
);

final darkTheme = ThemeData.dark().copyWith(
  extensions: [colorTokensDark, typographyTokensDark, ...],
);
```

### 6.4 ThemeProvider

- Simple `ChangeNotifierProvider` (or wrap in InheritedWidget if avoiding Provider)
- Listens to dark mode toggle setting (from Hive or shared_preferences)
- Default: `ThemeMode.system`
- Switches between light/dark ThemeData
- Wraps `MaterialApp` with the theme

---

## 7. Navigation Strategy

### 7.1 GoRouter Hierarchy

```dart
GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/new',
      builder: (context, state) => const NewProjectPage(),
    ),
    GoRoute(
      path: '/processing/:id',
      builder: (context, state) => ProcessingPage(
        projectId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/results/:id',
      builder: (context, state) => ResultsPage(
        projectId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/clip/:projectId/:clipIndex',
      builder: (context, state) => ClipDetailPage(
        projectId: state.pathParameters['projectId']!,
        clipIndex: int.parse(state.pathParameters['clipIndex']!),
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
)
```

### 7.2 Transition Overrides

| From          | To         | Transition  | Duration | Curve        |
| ------------- | ---------- | ----------- | -------- | ------------ |
| `/`           | `/home`    | Cross-fade  | 400ms    | easeOut      |
| Any push      | —          | Slide left  | 250ms    | easeOutCubic |
| Any pop       | —          | Slide right | 200ms    | easeInCubic  |
| `/processing` | `/results` | Slide left  | 300ms    | easeOutCubic |

### 7.3 Route Guards

- **None for MVP**, except: `/processing/:id` and `/results/:id` must validate that the project exists (via Repository). If not found: redirect to `/home` with error snackbar.
- **No auth guard** (no login MVP).

### 7.4 Modal Routes (Not GoRouter)

| Component        | Trigger                          |
| ---------------- | -------------------------------- |
| `AppDialog`      | Destructive confirmations only   |
| `AppBottomSheet` | Share, selections, action sheets |

Dialogs and bottom sheets are NOT routed through GoRouter. They use:

```dart
showDialog(context: context, builder: (ctx) => AppDialog(...));
showModalBottomSheet(context: context, builder: (ctx) => AppBottomSheet(...));
```

### 7.5 Deep Links (Future)

- Schema defined but no implementation in MVP.
- URI: `clipforge://results/:id`, `clipforge://clip/:projectId/:clipIndex`
- GoRouter path patterns are already compatible. Just needs `deepLink: true` in MaterialApp.

### 7.6 Transition Implementation

```dart
// In GoRouter — custom transition
CustomTransitionPage(
  child: page,
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    );
  },
  transitionDuration: const Duration(milliseconds: 250),
  reverseTransitionDuration: const Duration(milliseconds: 200),
)
```

### 7.7 Navigation Rules

- [ ] Max stack depth: 5 (Home → New → Processing → Results → ClipDetail)
- [ ] Exactly one back button per push screen (except splash)
- [ ] Back on Processing → cancel confirmation dialog
- [ ] Back on New Project (dirty) → discard confirmation dialog
- [ ] No tabs, no bottom nav, no hamburger menu
- [ ] Push all transitions. Pop all exits. Never `pushReplacement` except splash→home.

---

## 8. State Management Strategy

### 8.1 High-Level Architecture

```
Screen (Widget)
    │ listens to
    ▼
Bloc (Business Logic)
    │ calls
    ▼
Repository (Abstract Interface)
    │ implemented by
    ▼
RepositoryImpl (Concrete)
    │ calls
    ▼
Data Source (Dio / Hive / Mock)
```

### 8.2 Bloc Ownership

| Feature     | Bloc             | State Classes                                                                                                                                | Events                                                                   |
| ----------- | ---------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| Home        | `ProjectBloc`    | `ProjectInitial`, `ProjectLoading`, `ProjectData`, `ProjectError`, `ProjectEmpty`                                                            | `LoadProjects`, `DeleteProject`, `RefreshProjects`                       |
| New Project | `NewProjectBloc` | `NewProjectInitial`, `UrlValidating`, `UrlValid`, `UrlInvalid`, `PreviewLoading`, `PreviewLoaded`, `PreviewError`, `FormReady`, `Submitting` | `UrlChanged`, `ClipCountChanged`, `UrlSubmitted`                         |
| Processing  | `ProcessBloc`    | `ProcessIdle`, `ProcessRunning`, `ProcessStepUpdate`, `ProcessCompleted`, `ProcessError`, `ProcessStalled`, `ProcessCancelling`              | `StartProcessing`, `PollProgress`, `CancelProcessing`, `RetryProcessing` |
| Results     | `ResultsBloc`    | `ResultsInitial`, `ResultsLoading`, `ResultsLoaded`, `ResultsError`                                                                          | `LoadResults`, `DownloadSingleClip`, `DownloadAllClips`, `ShareClip`     |
| Clip Detail | `ClipDetailBloc` | `ClipDetailInitial`, `ClipDetailLoading`, `ClipDetailLoaded`, `ClipDetailError`, `ClipDownloading`, `ClipDownloaded`                         | `LoadClipDetail`, `DownloadClip`, `ShareClip`                            |
| Settings    | `SettingsBloc`   | `SettingsLoaded`                                                                                                                             | `ToggleDarkMode`                                                         |

### 8.3 Loading Strategy

- Every async operation starts with a `Loading` state.
- Loading state causes the screen to show skeletons or spinners.
- Never show a blank screen under loading.
- Minimum loading duration: 200ms (avoid flash of loading for fast operations).

### 8.4 Error Strategy

- Every async operation has a corresponding `Error` state.
- Error state contains: `message` (user-readable), `errorCode` (for debugging), `retry` callback.
- Screen shows `AppErrorWidget` with the message and retry action.
- Network errors are caught at the Dio interceptor level and mapped to `NetworkException`.
- Business errors (invalid video, private video) are mapped in the Repository.
- Bloc never exposes raw exceptions to UI.

### 8.5 Success Strategy

- Data state is immutable (freezed).
- UI receives the full state and renders accordingly.
- Bloc emits new state on each change (project list, progress percentage, step status).
- Completed states are terminal: `ProcessCompleted` → auto-navigate after 800ms.
- Success snackbars are triggered in the widget layer (listen for success event → show snackbar).

### 8.6 Bloc Rules

1. One Bloc per feature. If a feature has multiple responsibilities (e.g., load + delete + refresh), use multiple Blocs only if they handle independent concerns.
2. Bloc never imports UI classes. No `BuildContext` in Bloc (except `di` for DI).
3. Bloc never calls API directly — always goes through Repository.
4. Bloc state is always `freezed`. Every field is immutable.
5. Bloc emits events for analytics/logging via `onTransition` override.
6. Bloc is tested in `test/features/*/bloc/` with `bloc_test`.

### 8.7 Screen → Bloc Communication

```dart
// Widget
BlocProvider<ProjectBloc>(
  create: (context) => getIt<ProjectBloc>()..add(const LoadProjects()),
  child: BlocBuilder<ProjectBloc, ProjectState>(
    builder: (context, state) => switch (state) {
      ProjectLoading() => ...,
      ProjectData() => ...,
      ProjectError() => ...,
      ProjectEmpty() => ...,
    },
  ),
)
```

- Use `BlocBuilder` for state changes.
- Use `BlocListener` for one-shot effects (snackbar, navigation).
- Use `BlocConsumer` when both are needed.
- Never use `context.read<Bloc>()` inside `build` method.

### 8.8 Feature Communication

Features do NOT import each other. When navigating:

- `/new` → `/processing/:id`: pass projectId as route parameter.
- `/processing/:id` → `/results/:id`: auto-navigate on completion.
- `/results` → `/new`: navigate with pre-filled URL via route parameter or repository.

Repository is the shared context (Hive cache). No need for inter-feature Bloc communication in MVP.

---

## 9. Performance Strategy

### 9.1 Cold Start

- Splash screen is shown immediately (no network call needed).
- GoRouter lazy-loads all routes by default (no large initial build).
- Theme is pre-built at compile time (static const or top-level variable).
- Hive initialization in `main()` before `runApp()`.
- `runApp` is called as soon as theme + Hive are ready.

### 9.2 Lazy Loading

- Routes are lazily created by GoRouter (no eager initialization).
- Home data loads after navigation (not during splash).
- Project list pagination: load 10, load more on scroll end.
- Clip thumbnails load lazily via `cached_network_image`.

### 9.3 Image Loading

- Use `cached_network_image` for all thumbnails.
- Placeholder: `AppSkeletonCard` matching exact dimensions.
- Error: fallback icon (broken image).
- Pre-generate thumbnail URLs on backend (thumbnail, small, medium) — backend responsibility.
- Cache: disk cache via `cached_network_image` (default behavior).

### 9.4 Video Thumbnails

- Generated server-side (not client-side extraction).
- Served as static image URLs.
- Same caching strategy as images.

### 9.5 Animation Limits

- Max 12 animated widgets on screen at once (processing ring + 7 steps + 4 status/eta = within limit).
- Staggered card animations: max 10 cards, 50ms delay per card, capped at 500ms total.
- No animation loops except shimmer (1.5s loop) — this is acceptable.
- Reduced motion: all animations disabled (0ms) when `AccessibilityFeatures.reduceMotion` is true.

### 9.6 Widget Rebuild Strategy

- Use `const` constructors everywhere.
- Use `RepaintBoundary` on static parts (app bar, bottom CTA area).
- Prefer `AnimatedSwitcher` over manual opacity animation for cross-fade content.
- Avoid `Container` with `padding` changes causing rebuilds — use `Padding` widget directly.
- List items use `const` constructors or `AutomaticKeepAliveClientMixin` only if needed.
- `BlocBuilder` uses `buildWhen` to filter unnecessary rebuilds.

### 9.7 Memory Usage

- Dispose `AnimationController`, `StreamSubscription`, `TextEditingController`, `FocusNode` in `dispose()`.
- Video player: release controller on `dispose()`, not before.
- Hive: close only on app lifecycle `detach`. Single instance, no per-page open.
- Dio: single instance shared across app.
- Image cache: cleared on low-memory warning via `WidgetsBindingObserver`.
- Project list: max 20 items in memory. Pagination discards pages outside +1 radius.

### 9.8 Dio Interceptor for Performance

- Request caching for GET `/projects` (5s TTL).
- POST `/projects`, POST `/process` — never cached.
- Download streams directly to file, not to memory.
- Thumbnail URLs prefetched on Home load.

---

## 10. Quality Gates

### 10.1 Universal Quality Gate (Check Before Every Milestone Completion)

**UI Consistency:**

- [ ] All colors use token values (no hex literals, no `Colors.blue`, no `Color(0xFF...)`)
- [ ] All spacing uses token values (no raw `EdgeInsets`, no raw `SizedBox`)
- [ ] All typography uses token values (no raw `TextStyle`)
- [ ] All border radius uses token values
- [ ] All elevation uses token values
- [ ] No hardcoded dimensions anywhere in widget files

**Accessibility:**

- [ ] Every interactive element has `Semantics(button: true)` or equivalent
- [ ] Every icon has `Semantics(label:)` (meaningful) or `Semantics(label: "")` (decorative)
- [ ] Every empty state has screen reader label
- [ ] Every error state has screen reader label
- [ ] Loading states announce via `liveRegion`
- [ ] Reduced motion disables all animations (test with emulator setting)
- [ ] Dynamic Type increases font sizes without layout breakage
- [ ] Touch targets ≥48dp (or padded to 48dp)

**Responsive:**

- [ ] Tested at 360dp (iPhone SE) — no horizontal overflow
- [ ] Tested at 400dp (iPhone 14) — ideal layout
- [ ] Tested at 600dp (foldable) — layouts adapt (rows → grids)
- [ ] Text does not overflow (single-line truncation where expected)
- [ ] Images maintain aspect ratio at all widths
- [ ] Bottom CTA is always visible and correctly positioned

**Performance:**

- [ ] No `setState` for async operations (use Bloc)
- [ ] No unnecessary `Opacity` animations on large widgets
- [ ] Skeleton loading matches final layout dimensions
- [ ] No blank screens during loading
- [ ] Dispose: no memory leaks from controllers, subscriptions, or streams

**Architecture:**

- [ ] Feature follows `data/domain/presentation` structure
- [ ] Repository pattern used (abstract in domain, impl in data)
- [ ] Bloc is in `presentation/bloc/`, not in widget file
- [ ] Bloc never imports UI classes
- [ ] API calls only in Repository layer, not in Bloc
- [ ] No cross-feature imports (features import from `shared/` or `core/` only)

**Naming:**

- [ ] Files follow pattern: `feature_name.*.dart` or `feature_name_*.dart`
- [ ] Bloc files: `*_bloc.dart`, `*_event.dart`, `*_state.dart`
- [ ] Widget files: `*_page.dart`, `*_widget.dart`
- [ ] Repository files: `*_repository.dart`, `*_repository_impl.dart`
- [ ] All names use `snake_case` for files, `lowerCamelCase` for code

**Testing:**

- [ ] Widget test for each screen (presentation)
- [ ] Bloc test for each feature (unit)
- [ ] Repository test for API layer (unit + mock Dio)
- [ ] Test passes `flutter test` without warnings

**Housekeeping:**

- [ ] No `print()` or `debugPrint()` in committed code
- [ ] No commented-out code
- [ ] No unused imports (`dart fix --apply` run)
- [ ] `flutter analyze` passes with zero errors
- [ ] All TODOs are documented (not left in code)

### 10.2 Milestone-Specific Gates

| Phase           | Additional Gate                                                                   |
| --------------- | --------------------------------------------------------------------------------- |
| Theme + Tokens  | Every token defined in design_system.md exists in code. Verify by comparing docs. |
| Components      | Each component matches ui.md spec exactly (tokens, states, sizes, colors).        |
| Splash          | Splash matches layout in ui.md.                                                   |
| Home            | Loading/empty/data/error states all visible and correct.                          |
| New Project     | Valid URL + invalid URL + empty URL states. Paste detection. Chip selection.      |
| Processing      | All 7 steps animate. ETA updates. Cancel works. Error + stall states.             |
| Results         | Grid layout per clip count. Download All works. Share sheet opens.                |
| Clip Detail     | Video plays. Download works. Fullscreen works. Player errors handled.             |
| Settings        | Dark mode toggle persists. About links open correctly.                            |
| API Integration | All endpoints called correctly. Error handling at Dio interceptor level.          |

---

## 11. Common Pitfalls

### 11.1 Mistakes the AI Must NEVER Make

| #   | Pitfall                                | Why It's Bad                                                                     | Prevention                                                                                                |
| --- | -------------------------------------- | -------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| 1   | **Skipping reusable widgets**          | Creates duplicated UI. Each screen re-implements buttons, cards.                 | Always create component in `shared/widgets/` before using it.                                             |
| 2   | **Using raw colors**                   | Breaks dark mode. Hard to change palette. Inconsistent.                          | Never use `Colors.*`, `Color(0xFF...)`, or hex directly. Use tokens via `context.colorTokens()`.          |
| 3   | **Hardcoding paddings**                | Breaks spacing consistency. Layout drifts over time.                             | Always use `SpacingTokens` via `context.spacingTokens()`.                                                 |
| 4   | **Hardcoding text styles**             | Breaks typography hierarchy. Dynamic Type doesn't scale.                         | Always use `TypographyTokens` via `context.typographyTokens()`.                                           |
| 5   | **Ignoring empty states**              | User sees blank screen with no guidance. Poor UX.                                | Every feature with async data must have `AppEmptyWidget`.                                                 |
| 6   | **Ignoring error states**              | User sees nothing or infinite spinner on failure.                                | Every async operation must have `AppErrorWidget` with retry.                                              |
| 7   | **Ignoring loading states**            | Blank screen while data loads. User thinks app is broken.                        | Every async operation must show skeleton or spinner.                                                      |
| 8   | **setState for async ops**             | No loading/error state management. Code becomes spaghetti.                       | Always use Bloc for async operations.                                                                     |
| 9   | **API calls in Bloc**                  | Untestable. Bloc logic couples to HTTP client.                                   | Always call Repository from Bloc. Repository calls API.                                                   |
| 10  | **Creating Bloc in widget**            | Bloc lifecycle tied to widget. Difficult to test. Violates architecture.         | Bloc is instantiated via DI (`getIt`) or in feature folder.                                               |
| 11  | **Flat folder structure**              | Files become disorganized. No separation of concerns.                            | Always use `data/domain/presentation` per feature.                                                        |
| 12  | **Nested scrollables**                 | Layout overflow. Scroll conflict.                                                | Use `CustomScrollView` + `SliverList`, never nest `ListView`.                                             |
| 13  | **Not disposing subscriptions**        | Memory leaks. Streams keep running after widget is gone.                         | Dispose `AnimationController`, `StreamSubscription`, `FocusNode`, `TextEditingController` in `dispose()`. |
| 14  | **Over-engineering**                   | Adding abstractions (abstract factories, strategy pattern) for MVP. Wastes time. | Use the simplest solution that works. Add abstraction only when there are ≥2 implementations.             |
| 15  | **Ignoring navigation guards**         | Invalid project ID causes crash. Empty processing state causes error.            | Validate route parameters. Redirect on invalid state.                                                     |
| 16  | **Using MediaQuery directly**          | Tightly couples widget to screen size. Hard to test.                             | Use `LayoutBuilder` or `ResponsiveHelper`.                                                                |
| 17  | **Not reading related docs**           | Implementation diverges from spec. Rework required.                              | Before implementing ANY feature, read: design_system.md, ui.md, implementation_rules.md.                  |
| 18  | **Skipping Semantics labels**          | App is inaccessible to screen reader users. Legal risk.                          | Every interactive element gets `Semantics` with label.                                                    |
| 19  | **Modifying unrelated files**          | Introduces risk in stable code. Drift from scope.                                | Only modify files in the current feature's scope. If a fix is needed elsewhere, create a separate task.   |
| 20  | **Adding dependencies without review** | Bloat. License conflicts. Security risk.                                         | Only use dependencies listed in pubspec.yaml strategy.                                                    |

### 11.2 Code Patterns to Avoid

```dart
// ❌ Raw color
Container(color: Color(0xFF6C5CE7))

// ❌ Raw padding
Padding(padding: EdgeInsets.all(24))

// ❌ Raw text style
Text("Hello", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500))

// ❌ setState for async
void _loadData() async {
  setState(() => _loading = true);
  final data = await api.getData();
  setState(() { _data = data; _loading = false; });
}

// ❌ API in Bloc without Repository
class MyBloc {
  void fetch() async {
    final response = await dio.get('/projects'); // WRONG
  }
}

// ❌ Bloc instantiated in widget
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => MyBloc(dio: Dio())); // WRONG
  }
}
```

### 11.3 Fix Patterns

```dart
// ✅ Token color
Container(color: context.colorTokens.primary)

// ✅ Token spacing
Padding(padding: EdgeInsets.all(context.spacingTokens.xl))

// ✅ Token typography
Text("Hello", style: context.typographyTokens.bodyMedium)

// ✅ Bloc for async
BlocProvider(
  create: (context) => getIt<MyBloc>()..add(LoadData()),
  child: BlocBuilder<MyBloc, MyState>(
    builder: (context, state) => switch (state) {
      Loading() => Skeleton(),
      Data() => Content(state.data),
      Error() => AppErrorWidget(message: state.message, onRetry: () => context.read<MyBloc>().add(LoadData())),
    },
  ),
)

// ✅ Repository
class MyBloc {
  final Repository repository;
  void fetch() async {
    final data = await repository.getProjects();
  }
}

// ✅ DI instantiation
@module
abstract class AppModule {
  @singleton
  MyBloc get myBloc => MyBloc(getIt<Repository>());
}
```

---

## 12. AI Working Rules

### 12.1 Before Every Implementation

The AI MUST read the following documents in order:

1. `vision.md` — understand the product context (1 min)
2. `prd.md` — understand feature requirements (2 min)
3. `architecture.md` — understand system design (2 min)
4. `design_system.md` — understand visual tokens (3 min)
5. `ui.md` — understand screen/component specifications (5 min)
6. `implementation_rules.md` — understand coding conventions (2 min)
7. `development_workflow.md` — understand git/branch strategy (1 min)
8. `implementation_plan.md` — THIS document (3 min)

**Total reading time:** ~19 minutes.

**Skip or abbreviate only if the feature was previously read and no changes occurred since then.** Update `memory.md` with the last-read timestamp for each doc.

### 12.2 Implementation Sequence for Each Feature

```
Step 1: READ all related docs (above)
Step 2: PLAN implementation (think: what files need to change?)
Step 3: Confirm plan with user (if complex)
Step 4: IMPLEMENT in order:
          1. Domain entities
          2. Repository abstract
          3. Data sources (API calls, Hive)
          4. Repository implementation
          5. Bloc (events, states, logic)
          6. Shared widgets (if new)
          7. Screen (page + child widgets)
Step 5: VERIFY each step:
          - flutter analyze (no errors)
          - flutter test (existing tests pass)
          - Manual review of ui.md spec
Step 6: UPDATE:
          - memory.md (append: what was implemented, decisions, deviations)
          - checklist.md (mark tasks complete)
          - progress.md (update milestone status)
Step 7: CONTINUE to next feature in order
```

### 12.3 Never Do

- Never modify files outside the current feature scope (exception: fixing a critical bug in a shared component).
- Never introduce unnecessary abstractions (no interface with one implementation unless it's required by architecture).
- Never add new dependencies to pubspec.yaml without reading `implementation_rules.md` dependency section.
- Never commit code that has `flutter analyze` errors.
- Never skip tests for a feature.
- Never generate backend code in this project (backend is separate repository).
- Never generate pseudocode or placeholder implementations.
- Never leave TODOs in code without an associated task in checklist.md.
- Never assume state — verify by reading the current file content.

### 12.4 When Stuck

1. Re-read the relevant section of the docs (ui.md, architecture.md, implementation_rules.md).
2. Check `memory.md` for prior decisions that may clarify the approach.
3. If still unclear: ask the user with a specific question, referencing the doc section and what is ambiguous.
4. Never guess. Wrong implementation costs more time than asking.

### 12.5 When Deviating from Spec

If during implementation the AI determines that a spec deviation is necessary:

1. Document the deviation in a comment block in the code (`// ponytail: ...`).
2. Update `memory.md` with the deviation, reason, and scope.
3. Flag to the user before marking the feature complete.
4. Acceptable deviations: performance optimizations, platform-specific fixes, missing edge cases.
5. Unacceptable deviations: changing UI layout, removing features, altering navigation flow, ignoring accessibility.

### 12.6 After Feature Completion

Before declaring a feature "done":

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
# Verify zero errors, zero warnings, zero info-level issues
```

Then verify against the Quality Gates (Section 10) for that feature.

Then update:

- `memory.md` — append timestamped entry with implementation details
- `checklist.md` — check all completed tasks
- `progress.md` — update phase completion percentage

### 12.7 Documentation Drift Prevention

Every 5 features or once per week (whichever comes first), run a consistency check:

- Re-read `design_system.md` and compare current code tokens against the spec.
- Re-read `ui.md` screen sections and compare actual widget code.
- If drift is found: file a fix task, do NOT ignore it.

---

> **Document Version:** 1.0.0
> **Last Updated:** 2026-07-03
> **Author:** Flutter Tech Lead / AI Software Architect
> **Status:** Active — Cline ACT MODE must follow this document as the authoritative implementation reference.
> **Scope:** All MVP Flutter implementation phases.
> **Source Docs:** vision.md, prd.md, architecture.md, design_system.md, ui.md, implementation_rules.md, development_workflow.md.
