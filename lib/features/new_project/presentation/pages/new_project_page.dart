import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/ui/app_primary_button.dart';
import '../../../../core/ui/app_text_field.dart';
import '../bloc/new_project_bloc.dart';
import '../bloc/new_project_event.dart';
import '../bloc/new_project_state.dart';

/// Page 2 — form to paste YouTube URL and choose clip count.
/// Listens to [NewProjectBloc] and navigates to processing on success.
class NewProjectPage extends StatelessWidget {
  const NewProjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NewProjectBloc>(),
      child: const _NewProjectForm(),
    );
  }
}

class _NewProjectForm extends StatefulWidget {
  const _NewProjectForm();

  @override
  State<_NewProjectForm> createState() => _NewProjectFormState();
}

class _NewProjectFormState extends State<_NewProjectForm> {
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _onUrlChanged(String value) {
    context.read<NewProjectBloc>().add(UrlChanged(value));
  }

  void _onClipCountChanged(int count) {
    context.read<NewProjectBloc>().add(ClipCountChanged(count));
  }

  void _onSubmit() {
    context.read<NewProjectBloc>().add(const CreateProjectSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NewProjectBloc, NewProjectState>(
      listener: (context, state) {
        if (state is NewProjectSuccess) {
          context.pushReplacement(AppRoute.processingPath(state.projectId));
        }
        if (state is NewProjectError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final clipCount = state is NewProjectFormReady
            ? state.clipCount
            : AppConstants.defaultClipCount;
        final isUrlValid = state is NewProjectFormReady && state.isUrlValid;
        final isLoading = state is NewProjectLoading;

        return Scaffold(
          appBar: AppBar(title: const Text('New Clip')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // YouTube URL input
                Text(
                  'YouTube URL',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _urlController,
                  hintText: 'https://youtube.com/watch?v=...',
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onChanged: _onUrlChanged,
                ),
                const SizedBox(height: 32),

                // Clip count selector
                Text(
                  'Number of clips',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: AppConstants.allowedClipCounts.map((count) {
                    final selected = clipCount == count;
                    return ChoiceChip(
                      label: Text('$count'),
                      selected: selected,
                      onSelected: (_) => _onClipCountChanged(count),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 48),

                // Submit button
                Center(
                  child: AppPrimaryButton(
                    label: isLoading ? 'Processing...' : 'Start Processing',
                    onPressed: isUrlValid && !isLoading ? _onSubmit : null,
                  ),
                ),
                if (isLoading) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
