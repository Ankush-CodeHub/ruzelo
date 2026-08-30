/// Centralized API configuration for Ruzelo.
/// Change [baseUrl] when deploying your backend to Render, Railway, Fly.io, or VPS.
class ApiConfig {
  /// Local development URL: http://127.0.0.1:8000
  /// Production example: https://ruzelo-api.onrender.com
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static String get liveLatest => '$baseUrl/api/v1/tracks/live-latest';
  static String get livePlaylists => '$baseUrl/api/v1/tracks/live-playlists';
  static String get liveSearch => '$baseUrl/api/v1/tracks/live-search';
  static String get lastPlayed => '$baseUrl/api/v1/tracks/last-played';
  static String get resolveFull => '$baseUrl/api/v1/tracks/resolve-full';
  static String get streamingProxy => '$baseUrl/api/v1/streaming/proxy';
}
