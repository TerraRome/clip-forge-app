import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/project.dart';
import '../../../../domain/repositories/project_repository.dart';
import 'processing_event.dart';
import 'processing_state.dart';

/// Bloc for Processing page.
/// Starts processing via API, then polls until terminal status.
class ProcessingBloc extends Bloc<ProcessingEvent, ProcessingState> {
  final ProjectRepository _repository;
  Timer? _pollTimer;

  ProcessingBloc({required ProjectRepository repository})
    : _repository = repository,
      super(const ProcessingState.initial()) {
    on<ProcessingStarted>(_onStartProcessing);
    on<PollStatus>(_onPollStatus);
    on<ProcessingRetry>(_onRetry);
    on<ProcessingCancelled>(_onCancel);
  }

  Future<void> _onStartProcessing(
    ProcessingStarted event,
    Emitter<ProcessingState> emit,
  ) async {
    emit(const ProcessingState.starting());
    try {
      await _repository.startProcessing(event.projectId);
      emit(const ProcessingState.processing(progress: 0));
      // Start polling
      _startPolling(event.projectId);
    } catch (e) {
      emit(ProcessingState.error('Failed to start: $e'));
    }
  }

  Future<void> _onPollStatus(
    PollStatus event,
    Emitter<ProcessingState> emit,
  ) async {
    try {
      final project = await _repository.pollProject(event.projectId);
      if (project.status == ProjectStatus.done) {
        _pollTimer?.cancel();
        emit(ProcessingState.completed(project));
      } else if (project.status == ProjectStatus.error) {
        _pollTimer?.cancel();
        emit(
          ProcessingState.error(project.errorMessage ?? 'Processing failed'),
        );
      } else {
        emit(ProcessingState.processing(progress: project.progress));
      }
    } catch (e) {
      // Keep polling, don't emit error on network glitch
    }
  }

  void _onRetry(ProcessingRetry event, Emitter<ProcessingState> emit) {
    add(ProcessingStarted(event.projectId));
  }

  void _onCancel(ProcessingCancelled event, Emitter<ProcessingState> emit) {
    _pollTimer?.cancel();
    emit(const ProcessingState.initial());
  }

  void _startPolling(String projectId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => add(PollStatus(projectId)),
    );
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
