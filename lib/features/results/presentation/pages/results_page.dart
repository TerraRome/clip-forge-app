import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/ui/app_primary_button.dart';
import '../../../../core/ui/app_video_card.dart';
import '../../../../domain/entities/project.dart';
import '../bloc/results_bloc.dart';
import '../bloc/results_event.dart';
import '../bloc/results_state.dart';

/// Page 4 — shows generated clips with download.
class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ResultsBloc>()..add(LoadProject(projectId)),
      child: _ResultsView(projectId: projectId),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResultsBloc, ResultsState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Results'),
          leading: IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ),
        body: state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const Center(child: CircularProgressIndicator()),
          loaded: (project) => _ClipList(project: project),
          error: (msg) => _ErrorView(message: msg),
        ),
      ),
    );
  }
}

class _ClipList extends StatelessWidget {
  const _ClipList({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: project.clips.length,
      itemBuilder: (context, index) {
        final clip = project.clips[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ClipCard(clip: clip, projectId: project.id),
        );
      },
    );
  }
}

class ClipCard extends StatelessWidget {
  const ClipCard({super.key, required this.clip, required this.projectId});

  final Clip clip;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    final label =
        'Clip ${clip.index} (${_formatSec(clip.startSec)} – ${_formatSec(clip.endSec)})';
    final durationStr = _formatSec(clip.endSec - clip.startSec);
    return AppVideoCard(
      label: label,
      duration: durationStr,
      onDownload: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Download started')));
      },
    );
  }

  String _formatSec(double sec) {
    final m = (sec / 60).floor();
    final s = (sec % 60).floor();
    return '${m}m ${s}s';
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: 'Retry',
              onPressed: () => context.read<ResultsBloc>().add(const Retry()),
            ),
          ],
        ),
      ),
    );
  }
}
