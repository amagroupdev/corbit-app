import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/providers/locale_provider.dart';
import 'package:orbit_app/core/storage/secure_storage.dart';
import 'package:orbit_app/routing/app_router.dart';

// ═══════════════════════════════════════════════════════════════════════
// AUTH INTERCEPTOR
// ═══════════════════════════════════════════════════════════════════════

/// Attaches the Bearer token to every outgoing request and transparently
/// refreshes the access token when the server returns 401 Unauthorized.
///
/// Behaviour on a 401:
///  1. If the failing request was itself `/auth/refresh`, or no token is
///     stored, fall back to the legacy behaviour: clear credentials and
///     redirect to `/login`.
///  2. Otherwise, call `POST /auth/refresh` once (using a separate
///     [Dio] instance to avoid recursing through this interceptor) and:
///     - On success: persist the new token, retry the original request
///       and resolve with the retried response.
///     - On failure: clear credentials and redirect to `/login`.
///
/// The [_isRefreshing] guard prevents concurrent refreshes from looping.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorageService storageService,
    required GoRouter router,
  })  : _storageService = storageService,
        _router = router;

  final SecureStorageService _storageService;
  final GoRouter _router;

  /// Set while a refresh is in flight to prevent concurrent refreshes.
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storageService.getToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshCall = _isRefreshEndpoint(err);

    // Bail out of refresh logic for non-401 errors, or while a refresh is
    // already in flight, or when the failing call is itself /auth/refresh.
    if (!isUnauthorized || _isRefreshing || isRefreshCall) {
      if (isUnauthorized && (isRefreshCall || _isRefreshing)) {
        // Refresh itself failed (or recursive 401 during refresh) → log out.
        await _logoutAndRedirect();
      }
      return handler.next(err);
    }

    // Guest mode users should not be redirected; just propagate the error.
    final isGuest = await _storageService.isGuestMode();
    if (isGuest) {
      return handler.next(err);
    }

    final currentToken = await _storageService.getToken();
    if (currentToken == null || currentToken.isEmpty) {
      await _logoutAndRedirect();
      return handler.next(err);
    }

    _isRefreshing = true;
    try {
      // Use a separate Dio instance so we don't recurse through THIS
      // interceptor while attempting the refresh.
      final freshDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout:
              const Duration(milliseconds: ApiConstants.connectTimeout),
          receiveTimeout:
              const Duration(milliseconds: ApiConstants.receiveTimeout),
          sendTimeout: const Duration(milliseconds: ApiConstants.sendTimeout),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final refreshResp = await freshDio.post<Map<String, dynamic>>(
        ApiConstants.authRefresh,
        options: Options(
          headers: {'Authorization': 'Bearer $currentToken'},
        ),
        data: <String, dynamic>{},
      );

      final newToken = _extractToken(refreshResp.data);
      if (newToken == null || newToken.isEmpty) {
        await _logoutAndRedirect();
        return handler.next(err);
      }

      await _storageService.saveToken(newToken);

      // Retry the original request with the new token.
      final clonedReq = err.requestOptions;
      clonedReq.headers['Authorization'] = 'Bearer $newToken';

      final retryResp = await freshDio.fetch(clonedReq);
      _isRefreshing = false;
      return handler.resolve(retryResp);
    } catch (refreshError) {
      // Refresh failed — fall back to the legacy behaviour.
      if (kDebugMode) {
        debugPrint('[AuthInterceptor] Token refresh failed: $refreshError');
      }
      await _logoutAndRedirect();
      return handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  /// Returns `true` when the failing request targets `/auth/refresh`.
  bool _isRefreshEndpoint(DioException err) {
    final path = err.requestOptions.path;
    return path.contains(ApiConstants.authRefresh);
  }

  /// Extracts the new access token from a refresh response. Tolerates the
  /// three shapes the server is known to return:
  ///   1. `{ "data": { "token": { "access_token": "..." } } }`
  ///   2. `{ "data": { "token": "..." } }`
  ///   3. `{ "data": { "access_token": "..." } }`
  ///   4. Any of the above without the `data` envelope.
  static String? _extractToken(Map<String, dynamic>? json) {
    if (json == null) return null;

    final Map<String, dynamic> payload =
        json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : json;

    final tokenField = payload['token'];
    if (tokenField is String && tokenField.isNotEmpty) {
      return tokenField;
    }
    if (tokenField is Map<String, dynamic>) {
      final nested = tokenField['access_token'];
      if (nested is String && nested.isNotEmpty) return nested;
    }

    final accessToken = payload['access_token'];
    if (accessToken is String && accessToken.isNotEmpty) return accessToken;

    return null;
  }

  /// Clears credentials and navigates to `/login`.
  Future<void> _logoutAndRedirect() async {
    await _storageService.clearAll();
    _router.go('/login');
  }
}

// ═══════════════════════════════════════════════════════════════════════
// LANGUAGE INTERCEPTOR
// ═══════════════════════════════════════════════════════════════════════

/// Adds the `Accept-Language` header to every request based on the
/// currently selected locale (Arabic or English).
class LanguageInterceptor extends Interceptor {
  LanguageInterceptor({required Ref ref}) : _ref = ref;

  final Ref _ref;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final locale = _ref.read(localeProvider);
    options.headers['Accept-Language'] = locale.languageCode;
    handler.next(options);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// LOGGING INTERCEPTOR
// ═══════════════════════════════════════════════════════════════════════

/// Returns a [PrettyDioLogger] instance configured for debug builds.
///
/// In release mode the logger is still created but configured to be
/// minimally verbose so it does not leak data into production logs.
PrettyDioLogger createLoggingInterceptor() {
  return PrettyDioLogger(
    requestHeader: kDebugMode,
    requestBody: kDebugMode,
    responseHeader: false,
    responseBody: kDebugMode,
    error: true,
    compact: !kDebugMode,
    maxWidth: 120,
  );
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provider for [AuthInterceptor].
final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  final storageService = ref.watch(secureStorageProvider);
  final router = ref.watch(appRouterProvider);
  return AuthInterceptor(
    storageService: storageService,
    router: router,
  );
});

/// Provider for [LanguageInterceptor].
final languageInterceptorProvider = Provider<LanguageInterceptor>((ref) {
  return LanguageInterceptor(ref: ref);
});

/// Provider for the logging interceptor.
final loggingInterceptorProvider = Provider<PrettyDioLogger>((ref) {
  return createLoggingInterceptor();
});
