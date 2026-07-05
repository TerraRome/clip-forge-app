/// Centralized application constants.
class AppConstants {
  AppConstants._();

  /// App info
  static const String appName = 'Klip — AI YouTube Clipper';
  static const String appVersion = '1.0.0';

  /// API
  static const String baseUrl = 'http://localhost:8000';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration pollInterval = Duration(seconds: 3);

  /// Processing
  static const List<int> allowedClipCounts = [1, 3, 5, 10];
  static const int defaultClipCount = 3;

  /// Video
  static const double outputAspectRatio = 9.0 / 16.0; // vertical 9:16
  static const int outputWidth = 1080;
  static const int outputHeight = 1920;

  /// Limits
  static const int maxUrlLength = 2048;
  static const Duration processingTimeout = Duration(minutes: 10);
}
