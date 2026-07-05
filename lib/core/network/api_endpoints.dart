/// API endpoint constants.
class ApiEndpoints {
  ApiEndpoints._();

  static const String basePath = '/api/v1';

  // Projects
  static const String createProject = '$basePath/projects'; // POST
  static String project(String id) => '$basePath/projects/$id'; // GET

  // Processing
  static const String process = '$basePath/process'; // POST
  static String processingStatus(String id) =>
      '$basePath/projects/$id/status'; // GET

  // Download
  static String download(String id) => '$basePath/download/$id'; // GET
}
