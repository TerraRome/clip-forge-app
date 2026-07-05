import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/ui/app_primary_button.dart';
import '../bloc/processing_bloc.dart';
import '../bloc/processing_event.dart';
import '../bloc/processing_state.dart';

/// Page 3 — shows processing progress with polling.
/// Auto-starts on mount, navigates to results on completion.
class ProcessingPage extends StatelessWidget {
  const ProcessingPage({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProcessingBloc>()..add(ProcessingStarted(projectId)),
      child: _ProcessingView(projectId: projectId),
    );
  }
}

class _ProcessingView extends StatelessWidget {
  const _ProcessingView({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProcessingBloc, ProcessingState>(
      listener: (context, state) {
        state.whenOrNull(
          completed: (project) =>
              context.pushReplacement(AppRoute.resultsPath(project.id)),
          error: (msg) => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg))),
        );
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Processing'),
            automaticallyImplyLeading: false,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: state.maybeWhen(
                initial: () => const SizedBox.shrink(),
                starting: _buildStarting,
                processing: (progress) => _buildProgress(context, progress),
                completed: (_) => _buildDone(context),
                error: (msg) => _buildError(context, msg),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStarting() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 24),
        Text('Starting processing...'),
      ],
    );
  }

  Widget _buildProgress(BuildContext context, double progress) {
    final pct = (progress * 100).toStringAsFixed(1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(value: progress),
              Text('$pct%', style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Generating your clips...'),
      ],
    );
  }

  Widget _buildDone(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        const Text('Processing complete!'),
        const SizedBox(height: 24),
        AppPrimaryButton(
          label: 'View Results',
          onPressed: () =>
              context.pushReplacement(AppRoute.resultsPath(projectId)),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error, size: 80, color: Colors.red),
        const SizedBox(height: 24),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        AppPrimaryButton(
          label: 'Retry',
          onPressed: () =>
              context.read<ProcessingBloc>().add(ProcessingRetry(projectId)),
        ),
      ],
    );
  }
}
