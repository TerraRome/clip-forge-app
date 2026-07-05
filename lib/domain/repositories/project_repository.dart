import '../entities/project.dart';

/// Repository interface for project operations.
abstract class ProjectRepository {
  /// Create a new project.
  Future<Project> createProject({required String url, required int clipCount});

  /// Get project by ID.
  Future<Project> getProject(String id);

  /// Start processing a project.
  Future<Project> startProcessing(String projectId);

  /// Poll project status.
  Future<Project> pollProject(String id);

  /// Get download URL for a clip.
  String getDownloadUrl(String projectId, int clipIndex);
}
