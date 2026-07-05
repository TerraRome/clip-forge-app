import 'package:freezed_annotation/freezed_annotation.dart';

part 'project.freezed.dart';
part 'project.g.dart';

@freezed
abstract class Project with _$Project {
  const factory Project({
    required String id,
    required String url,
    required int clipCount,
    required ProjectStatus status,
    @Default(0) double progress,
    @Default([]) List<Clip> clips,
    String? errorMessage,
    DateTime? createdAt,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
}

@freezed
abstract class Clip with _$Clip {
  const factory Clip({
    required int index,
    required double startSec,
    required double endSec,
    String? subtitlePath,
    String? videoPath,
  }) = _Clip;

  factory Clip.fromJson(Map<String, dynamic> json) => _$ClipFromJson(json);
}

enum ProjectStatus {
  pending,
  processing,
  done,
  error;

  bool get isTerminal => this == done || this == error;
  bool get isProcessing => this == processing;
}
