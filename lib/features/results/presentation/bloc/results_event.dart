import 'package:freezed_annotation/freezed_annotation.dart';

part 'results_event.freezed.dart';

/// Events for ResultsBloc.
@freezed
abstract class ResultsEvent with _$ResultsEvent {
  /// Load project from local cache.
  const factory ResultsEvent.loadProject(String projectId) = LoadProject;

  /// Retry loading.
  const factory ResultsEvent.retry() = Retry;
}
