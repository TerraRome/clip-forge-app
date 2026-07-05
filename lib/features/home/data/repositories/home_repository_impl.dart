import '../../../../domain/entities/project.dart';
import '../../../../domain/repositories/project_repository.dart';
import '../datasources/home_local_datasource.dart';

/// Implementation of [ProjectRepository] for the home feature.
/// Delegates to [HomeLocalDatasource] for local operations.
class HomeRepositoryImpl implements ProjectRepository {
  final HomeLocalDatasource _localDatasource;

  HomeRepositoryImpl({required HomeLocalDatasource localDatasource})
    : _localDatasource = localDatasource;

  @override
  Future<List<Project>> getRecentProjects() async {
    return _localDatasource.getRecentProjects();
  }

  @override
  Future<Project> createProject({
    required String url,
    required int clipCount,
  }) async {
    final project = Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url,
      clipCount: clipCount,
      status: ProjectStatus.pending,
      createdAt: DateTime.now(),
    );
    await _localDatasource.saveProject(project);
    return project;
  }

  @override
  Future<Project> getProject(String id) {
    throw UnimplementedError('Will be implemented in future pages');
  }

  @override
  Future<Project> startProcessing(String projectId) async {
    // For MVP: update Hive status + progress, then return project.
    // Real impl will call POST /process on backend.
    final project = await _localDatasource.getProject(projectId);
    final updated = project.copyWith(
      status: ProjectStatus.processing,
      progress: 0.0,
    );
    await _localDatasource.saveProject(updated);
    return updated;
  }

  @override
  Future<Project> pollProject(String id) async {
    // For MVP: read from Hive (backend will update via polling).
    // Real impl will call GET /projects/{id}/status.
    return _localDatasource.getProject(id);
  }

  @override
  String getDownloadUrl(String projectId, int clipIndex) {
    throw UnimplementedError('Will be implemented in download feature');
  }
}
