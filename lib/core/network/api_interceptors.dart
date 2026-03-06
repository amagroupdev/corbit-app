import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:orbit_app/core/providers/locale_provider.dart';
import 'package:orbit_app/core/storage/secure_storage.dart';
import 'package:orbit_app/routing/app_router.dart';

// ═══════════════════════════════════════════════════════════════════════
// AUTH INTERCEPTOR
// ═══════════════════════════════════════════════════════════════════════

/// Attaches the Bearer token to every outgoing request and handles
/// 401 Unauthorized responses by clearing the stored token and
/// redirecting to the login screen.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorageService storageService,
    required GoRouter router,
  })  : _storageService = storageService,
        _router = router;

  final SecureStorageService _storageService;
  final GoRouter _router;

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
    if (err.response?.statusCode == 401) {
      // Clear all stored credentials.
      await _storageService.clearAll();

      // Navigate to login, clearing the navigation stack.
      _router.go('/login');
    }

    handler.next(err);
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
