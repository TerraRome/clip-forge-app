import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/project_repository.dart';
import 'results_event.dart';
import 'results_state.dart';

/// Bloc for Results page.
/// Loads project from local cache and exposes clips for display + download.
class ResultsBloc extends Bloc<ResultsEvent, ResultsState> {
  final ProjectRepository _repository;

  ResultsBloc({required ProjectRepository repository})
    : _repository = repository,
      super(const ResultsState.initial()) {
    on<LoadProject>(_onLoadProject);
    on<Retry>(_onRetry);
  }

  String? _projectId;

  Future<void> _onLoadProject(
    LoadProject event,
    Emitter<ResultsState> emit,
  ) async {
    _projectId = event.projectId;
    emit(const ResultsState.loading());
    try {
      final project = await _repository.getProject(event.projectId);
      if (project.clips.isEmpty) {
        emit(const ResultsState.error('No clips found for this project.'));
      } else {
        emit(ResultsState.loaded(project));
      }
    } catch (e) {
      emit(ResultsState.error('Failed to load results: $e'));
    }
  }

  void _onRetry(Retry event, Emitter<ResultsState> emit) {
    if (_projectId != null) {
      add(LoadProject(_projectId!));
    }
  }
}
