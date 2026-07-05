import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../domain/entities/project.dart';

part 'processing_state.freezed.dart';

/// States for [ProcessingBloc].
@freezed
class ProcessingState with _$ProcessingState {
  /// Initial idle state.
  const factory ProcessingState.initial() = _Initial;

  /// Processing is starting (calling POST /process).
  const factory ProcessingState.starting() = _Starting;

  /// Processing in progress with progress percentage.
  const factory ProcessingState.processing({required double progress}) =
      _Processing;

  /// Processing completed successfully.
  const factory ProcessingState.completed(Project project) = _Completed;

  /// Processing failed.
  const factory ProcessingState.error(String message) = _Error;
}
