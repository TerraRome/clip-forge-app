import 'package:go_router/go_router.dart';
import 'package:klip_mobile/features/home/presentation/pages/home_page.dart';
import 'package:klip_mobile/features/new_project/presentation/pages/new_project_page.dart';
import 'package:klip_mobile/features/processing/presentation/pages/processing_page.dart';
import 'package:klip_mobile/features/results/presentation/pages/results_page.dart';
import 'package:klip_mobile/features/clip_detail/presentation/pages/clip_detail_page.dart';
import 'package:klip_mobile/features/settings/presentation/pages/settings_page.dart';

// ponytail: generate route paths with freezed when route params are needed
// For M1, hardcoded paths are sufficient (<5 routes)
abstract class AppRoute {
  static const home = '/';
  static const newProject = '/new';
  static const processing = '/processing/:projectId';
  static const results = '/results/:projectId';
  static const clipDetail = '/clip/:projectId/:clipIndex';
  static const settings = '/settings';

  static String processingPath(String projectId) => '/processing/$projectId';
  static String resultsPath(String projectId) => '/results/$projectId';
  static String clipDetailPath(String projectId, int clipIndex) =>
      '/clip/$projectId/$clipIndex';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoute.home,
  routes: [
    GoRoute(
      path: AppRoute.home,
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoute.newProject,
      name: 'newProject',
      builder: (context, state) => const NewProjectPage(),
    ),
    GoRoute(
      path: AppRoute.processing,
      name: 'processing',
      builder: (context, state) =>
          ProcessingPage(projectId: state.pathParameters['projectId']!),
    ),
    GoRoute(
      path: AppRoute.results,
      name: 'results',
      builder: (context, state) =>
          ResultsPage(projectId: state.pathParameters['projectId']!),
    ),
    GoRoute(
      path: AppRoute.clipDetail,
      name: 'clipDetail',
      builder: (context, state) => ClipDetailPage(
        projectId: state.pathParameters['projectId']!,
        clipIndex: int.parse(state.pathParameters['clipIndex']!),
      ),
    ),
    GoRoute(
      path: AppRoute.settings,
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);
