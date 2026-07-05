import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../domain/entities/project.dart';

part 'results_state.freezed.dart';

/// States for ResultsBloc.
@freezed
abstract class ResultsState with _$ResultsState {
  /// Initial state before loading.
  const factory ResultsState.initial() = Initial;

  /// Loading project from cache.
  const factory ResultsState.loading() = Loading;

  /// Loaded project with clips list.
  const factory ResultsState.loaded(Project project) = Loaded;

  /// Failed to load.
  const factory ResultsState.error(String message) = Error;
}
