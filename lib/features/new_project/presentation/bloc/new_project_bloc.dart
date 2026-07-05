import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klip_mobile/core/constants/app_constants.dart';
import 'package:klip_mobile/domain/repositories/project_repository.dart';
import 'new_project_event.dart';
import 'new_project_state.dart';

/// Validates YouTube URL format.
bool _isValidYouTubeUrl(String url) {
  if (url.length > AppConstants.maxUrlLength) return false;
  final youtubeRegex = RegExp(
    r'^(https?://)?(www\.)?(youtube\.com|youtu\.be)/.+$',
  );
  return url.isNotEmpty && youtubeRegex.hasMatch(url.trim());
}

/// Bloc for the New Project form.
class NewProjectBloc extends Bloc<NewProjectEvent, NewProjectState> {
  final ProjectRepository _repository;

  NewProjectBloc({required ProjectRepository repository})
    : _repository = repository,
      super(const NewProjectInitial()) {
    on<UrlChanged>(_onUrlChanged);
    on<ClipCountChanged>(_onClipCountChanged);
    on<CreateProjectSubmitted>(_onCreateProjectSubmitted);
  }

  void _onUrlChanged(UrlChanged event, Emitter<NewProjectState> emit) {
    final isUrlValid = _isValidYouTubeUrl(event.url);
    final currentState = state;
    final clipCount = currentState is NewProjectFormReady
        ? currentState.clipCount
        : AppConstants.defaultClipCount;

    emit(
      NewProjectFormReady(
        url: event.url,
        clipCount: clipCount,
        isUrlValid: isUrlValid,
      ),
    );
  }

  void _onClipCountChanged(
    ClipCountChanged event,
    Emitter<NewProjectState> emit,
  ) {
    final currentState = state;
    final url = currentState is NewProjectFormReady ? currentState.url : '';
    final isUrlValid =
        currentState is NewProjectFormReady && currentState.isUrlValid;

    emit(
      NewProjectFormReady(
        url: url,
        clipCount: event.clipCount,
        isUrlValid: isUrlValid,
      ),
    );
  }

  Future<void> _onCreateProjectSubmitted(
    CreateProjectSubmitted event,
    Emitter<NewProjectState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NewProjectFormReady || !currentState.isUrlValid) {
      emit(const NewProjectError('Please enter a valid YouTube URL.'));
      return;
    }

    emit(const NewProjectLoading());

    try {
      final project = await _repository.createProject(
        url: currentState.url.trim(),
        clipCount: currentState.clipCount,
      );
      emit(NewProjectSuccess(project.id));
    } catch (e) {
      emit(NewProjectError('Failed to create project: $e'));
    }
  }
}
