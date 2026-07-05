import 'package:freezed_annotation/freezed_annotation.dart';

part 'processing_event.freezed.dart';

/// Events for [ProcessingBloc].
@freezed
class ProcessingEvent with _$ProcessingEvent {
  /// Start processing the project.
  const factory ProcessingEvent.startProcessing(String projectId) =
      ProcessingStarted;

  /// Poll status from backend.
  const factory ProcessingEvent.pollStatus(String projectId) = PollStatus;

  /// Retry after an error.
  const factory ProcessingEvent.retry(String projectId) = ProcessingRetry;

  /// Cancel the processing.
  const factory ProcessingEvent.cancel() = ProcessingCancelled;
}
