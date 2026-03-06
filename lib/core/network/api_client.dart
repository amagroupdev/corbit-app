import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/core/network/api_interceptors.dart';

/// Central HTTP client for the ORBIT SMS V3 application.
///
/// Wraps [Dio] with pre-configured base URL, timeouts, headers, and
/// interceptors (auth, language, logging). Provides typed convenience
/// methods for GET, POST, PUT, DELETE, and multipart file uploads.
///
/// Obtain an instance through the [apiClientProvider] Riverpod provider
/// so that interceptors are automatically wired up.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  /// The underlying [Dio] instance. Exposed for edge cases where
  /// direct access is needed (e.g. download streams).
  Dio get dio => _dio;

  // ─── GET ──────────────────────────────────────────────────────────

  /// Sends a GET request to [path] with optional [queryParameters].
  ///
  /// Throws an [ApiException] subtype on failure.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ─── POST ─────────────────────────────────────────────────────────

  /// Sends a POST request to [path] with an optional request [data] body.
  ///
  /// Throws an [ApiException] subtype on failure.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ─── PUT ──────────────────────────────────────────────────────────

  /// Sends a PUT request to [path] with an optional request [data] body.
  ///
  /// Throws an [ApiException] subtype on failure.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ─── DELETE ───────────────────────────────────────────────────────

  /// Sends a DELETE request to [path] with optional [data] and
  /// [queryParameters].
  ///
  /// Throws an [ApiException] subtype on failure.
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ─── UPLOAD (multipart/form-data) ─────────────────────────────────

  /// Sends a multipart/form-data POST request for file uploads.
  ///
  /// [path] is the endpoint URL.
  /// [file] is the [MultipartFile] to upload (use [MultipartFile.fromFile]
  /// or [MultipartFile.fromBytes] to create one).
  /// [fileFieldName] is the form field name expected by the server
  /// (defaults to `'file'`).
  /// [data] is an optional map of additional form fields to include.
  /// [onSendProgress] receives upload progress callbacks.
  ///
  /// Example:
  /// ```dart
  /// final file = await MultipartFile.fromFile(filePath, filename: 'avatar.png');
  /// final response = await apiClient.upload(
  ///   '/user/avatar',
  ///   file: file,
  ///   fileFieldName: 'avatar',
  ///   data: {'description': 'Profile picture'},
  ///   onSendProgress: (sent, total) => print('${sent / total * 100}%'),
  /// );
  /// ```
  ///
  /// Throws an [ApiException] subtype on failure.
  Future<Response<T>> upload<T>(
    String path, {
    required MultipartFile file,
    String fileFieldName = 'file',
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        fileFieldName: file,
        if (data != null) ...data,
      });

      return await _dio.post<T>(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: Options(
          contentType: 'multipart/form-data',
        ),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Sends a multipart/form-data POST request with multiple files.
  ///
  /// [files] is a map of field names to [MultipartFile] instances.
  /// [data] is an optional map of additional form fields.
  ///
  /// Throws an [ApiException] subtype on failure.
  Future<Response<T>> uploadMultiple<T>(
    String path, {
    required Map<String, MultipartFile> files,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final Map<String, dynamic> formMap = {};
      if (data != null) {
        formMap.addAll(data);
      }
      formMap.addAll(files);

      final formData = FormData.fromMap(formMap);

      return await _dio.post<T>(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: Options(
          contentType: 'multipart/form-data',
        ),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provider for the configured [Dio] instance.
///
/// This is the single source of truth for Dio configuration. It sets
/// the base URL, timeouts, default headers, and registers all
/// interceptors in the correct order.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      sendTimeout: const Duration(milliseconds: ApiConstants.sendTimeout),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      responseType: ResponseType.json,
      validateStatus: (status) {
        // Only 2xx responses are treated as successful. All other status
        // codes (4xx, 5xx) will throw DioException so they can be properly
        // handled by interceptors and the ApiException.fromDioError factory.
        return status != null && status >= 200 && status < 300;
      },
    ),
  );

  // Register interceptors in order:
  // 1. Auth  - adds Bearer token
  // 2. Language - adds Accept-Language header
  // 3. Logging  - logs request/response (last, so it captures final state)
  final authInterceptor = ref.watch(authInterceptorProvider);
  final languageInterceptor = ref.watch(languageInterceptorProvider);
  final loggingInterceptor = ref.watch(loggingInterceptorProvider);

  dio.interceptors.addAll([
    authInterceptor,
    languageInterceptor,
    loggingInterceptor,
  ]);

  return dio;
});

/// Provider for [ApiClient].
///
/// Usage in a repository:
/// ```dart
/// final apiClient = ref.watch(apiClientProvider);
/// final response = await apiClient.get('/user/profile');
/// ```
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});
