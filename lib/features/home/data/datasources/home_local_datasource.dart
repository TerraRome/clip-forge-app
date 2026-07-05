import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../domain/entities/project.dart';

/// Local data source for home screen.
/// Reads projects from Hive cache.
abstract class HomeLocalDatasource {
  /// Get cached projects, newest first.
  Future<List<Project>> getRecentProjects();

  /// Get a single project by ID.
  Future<Project> getProject(String id);

  /// Save a project to cache.
  Future<void> saveProject(Project project);

  /// Clear all cached projects.
  Future<void> clearProjects();
}

class HomeLocalDatasourceImpl implements HomeLocalDatasource {
  static const _boxName = 'projects';

  late Box<String> _box;

  HomeLocalDatasourceImpl() {
    // Lazy init handled by HiveFlutter.ensureInitialized in main.
  }

  Future<Box<String>> get _boxInstance async {
    _box = await Hive.openBox<String>(_boxName);
    return _box;
  }

  @override
  Future<Project> getProject(String id) async {
    try {
      final box = await _boxInstance;
      final json = box.get(id);
      if (json == null) throw CacheException('Project not found: $id');
      return Project.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Failed to read project: $e');
    }
  }

  @override
  Future<List<Project>> getRecentProjects() async {
    try {
      final box = await _boxInstance;
      final values = box.values.toList();
      final projects = values
          .map(
            (json) =>
                Project.fromJson(jsonDecode(json) as Map<String, dynamic>),
          )
          .toList();
      // Sort newest first
      projects.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(2000);
        final bTime = b.createdAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      return projects;
    } catch (e) {
      throw CacheException('Failed to read cached projects: $e');
    }
  }

  @override
  Future<void> saveProject(Project project) async {
    try {
      final box = await _boxInstance;
      await box.put(project.id, jsonEncode(project.toJson()));
    } catch (e) {
      throw CacheException('Failed to cache project: $e');
    }
  }

  @override
  Future<void> clearProjects() async {
    try {
      final box = await _boxInstance;
      await box.clear();
    } catch (e) {
      throw CacheException('Failed to clear projects: $e');
    }
  }
}
