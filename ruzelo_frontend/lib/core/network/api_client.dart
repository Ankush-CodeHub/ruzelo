import 'dart:developer' as developer;
import 'package:dio/dio.dart';

/// Centralized API client for communicating with the Ruzelo FastAPI backend
class ApiClient {
  final Dio _dio;
  static const String defaultBaseUrl = 'http://localhost:8000/api/v1';

  ApiClient({String baseUrl = defaultBaseUrl, Dio? customDio})
      : _dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          developer.log('--> ${options.method} ${options.uri}', name: 'ApiClient');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          developer.log('<-- ${response.statusCode} ${response.requestOptions.uri}', name: 'ApiClient');
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          developer.log('API Error: ${error.message} on ${error.requestOptions.uri}', name: 'ApiClient', error: error);
          return handler.next(error);
        },
      ),
    );
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  // Endpoints
  Future<Response<dynamic>> getTracks({String? genre, String? mood, String? search}) async {
    return _dio.get(
      '/tracks',
      queryParameters: {
        if (genre != null) 'genre': genre,
        if (mood != null) 'mood': mood,
        if (search != null) 'q': search,
      },
    );
  }

  Future<Response<dynamic>> getTrackById(String trackId) async {
    return _dio.get('/tracks/$trackId');
  }

  Future<Response<dynamic>> getRecommendations(String trackId) async {
    return _dio.get('/tracks/$trackId/recommendations');
  }

  Future<Response<dynamic>> getAtmospheres() async {
    return _dio.get('/atmosphere');
  }

  Future<Response<dynamic>> getAtmosphereShaderUniforms(String atmosphereId) async {
    return _dio.get('/atmosphere/$atmosphereId/uniforms');
  }

  String getStreamingUrl(String trackId) {
    return '${_dio.options.baseUrl}/streaming/$trackId';
  }

  Future<Response<dynamic>> login(String username, String password) async {
    return _dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );
  }

  Future<Response<dynamic>> guestLogin() async {
    return _dio.post('/auth/guest');
  }
}
