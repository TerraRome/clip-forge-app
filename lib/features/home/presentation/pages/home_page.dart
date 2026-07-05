import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/extensions/app_theme_extension.dart';
import '../../../../core/ui/app_app_bar.dart';
import '../../../../core/ui/app_primary_button.dart';
import '../../../../domain/entities/project.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HomeBloc>()..add(const LoadProjects()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppAppBar(
        title: Text(
          'AI YouTube Clipper',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: colors.textSecondary),
            onPressed: () => context.push(AppRoute.settings),
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return switch (state) {
            HomeInitial() || HomeLoading() => const _HomeShimmer(),
            HomeLoaded(:final projects) => _HomeContent(projects: projects),
            HomeError(:final message) => _HomeError(message: message),
          };
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoute.newProject),
        icon: const Icon(Icons.add),
        label: const Text('New Clip'),
      ),
    );
  }
}

/// Shimmer loading placeholder.
class _HomeShimmer extends StatelessWidget {
  const _HomeShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

/// Content when projects are loaded.
class _HomeContent extends StatelessWidget {
  final List<Project> projects;

  const _HomeContent({required this.projects});

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<HomeBloc>().add(const LoadProjects());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: projects.length,
        itemBuilder: (context, index) => _ProjectCard(
          project: projects[index],
          onTap: () {
            context.push(AppRoute.processingPath(projects[index].id));
          },
        ),
      ),
    );
  }
}

/// Empty state when no projects exist.
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 80,
              color: colors.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No clips yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Paste a YouTube URL and generate\nvertical clips with AI',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: 'Create your first clip',
              onPressed: () => context.push(AppRoute.newProject),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single project card in the list.
class _ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _ProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor = switch (project.status) {
      ProjectStatus.done => Colors.green,
      ProjectStatus.error => Colors.red,
      ProjectStatus.processing => Colors.orange,
      ProjectStatus.pending => Colors.grey,
    };
    final statusLabel = switch (project.status) {
      ProjectStatus.done => 'Done',
      ProjectStatus.error => 'Error',
      ProjectStatus.processing => 'Processing',
      ProjectStatus.pending => 'Pending',
    };
    final dateStr = project.createdAt != null
        ? '${project.createdAt!.day}/${project.createdAt!.month}/${project.createdAt!.year}'
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Thumbnail placeholder
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.play_circle_outline,
                  color: colors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YouTube Clip #${project.id.substring(0, 6)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${project.clipCount} clips',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                        if (dateStr.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error state.
class _HomeError extends StatelessWidget {
  final String message;

  const _HomeError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            AppPrimaryButton(
              label: 'Retry',
              onPressed: () =>
                  context.read<HomeBloc>().add(const LoadProjects()),
            ),
          ],
        ),
      ),
    );
  }
}
