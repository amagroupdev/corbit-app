import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/core/storage/secure_storage.dart';
import 'package:orbit_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:orbit_app/features/auth/data/models/auth_response_model.dart';
import 'package:orbit_app/features/auth/data/models/user_model.dart';

// =============================================================================
// Result type
// =============================================================================

/// A simple result wrapper that avoids the need for a full Either/dartz
/// dependency. Every repository method returns [Result<T>].
class Result<T> {
  const Result._({this.data, this.error, this.fieldErrors});

  /// Successful result with data.
  factory Result.success(T data) => Result._(data: data);

  /// Failed result with an error message and optional field-level errors.
  factory Result.failure(
    String error, {
    Map<String, List<String>>? fieldErrors,
  }) =>
      Result._(error: error, fieldErrors: fieldErrors);

  final T? data;
  final String? error;
  final Map<String, List<String>>? fieldErrors;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}

// =============================================================================
// Repository
// =============================================================================

/// Repository that orchestrates authentication data operations.
///
/// Wraps [AuthRemoteDataSource] calls with unified error handling and
/// automatically persists / removes the access token in secure storage
/// on successful login / logout.
class AuthRepository {
  const AuthRepository({
    required AuthRemoteDataSource dataSource,
    required SecureStorageService storageService,
  })  : _dataSource = dataSource,
        _storageService = storageService;

  final AuthRemoteDataSource _dataSource;
  final SecureStorageService _storageService;

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------

  /// Attempts to log the user in.
  ///
  /// On success the access token is persisted automatically.
  /// When 2FA is required the caller receives an [AuthResponseModel] with
  /// `requires2fa == true` and a `verificationUuid`.
  Future<Result<AuthResponseModel>> login({
    required String username,
    required String password,
    String? fcmToken,
  }) async {
    return _guard(() async {
      final response = await _dataSource.login(
        username: username,
        password: password,
        fcmToken: fcmToken,
      );

      if (response.isAuthenticated) {
        await _storageService.saveToken(response.token!);
      }

      return response;
    });
  }

  // ---------------------------------------------------------------------------
  // Register
  // ---------------------------------------------------------------------------

  /// Registers a new account and persists the token when the server returns
  /// one immediately (i.e. phone verification is not required).
  Future<Result<AuthResponseModel>> register({
    required Map<String, dynamic> data,
    Map<String, MultipartFile>? files,
  }) async {
    return _guard(() async {
      final response = await _dataSource.register(data: data, files: files);

      if (response.isAuthenticated) {
        await _storageService.saveToken(response.token!);
      }

      return response;
    });
  }

  // ---------------------------------------------------------------------------
  // Two-Factor Verification
  // ---------------------------------------------------------------------------

  /// Verifies the 2FA code. On success the token is persisted.
  Future<Result<AuthResponseModel>> verify2fa({
    required String code,
    required String verificationUuid,
  }) async {
    return _guard(() async {
      final response = await _dataSource.verify2fa(
        code: code,
        verificationUuid: verificationUuid,
      );

      if (response.isAuthenticated) {
        await _storageService.saveToken(response.token!);
      }

      return response;
    });
  }

  // ---------------------------------------------------------------------------
  // Phone Verification
  // ---------------------------------------------------------------------------

  /// Verifies the phone OTP after registration.
  Future<Result<AuthResponseModel>> verifyPhone({
    required String code,
    required int userId,
  }) async {
    return _guard(() async {
      final response = await _dataSource.verifyPhone(
        code: code,
        userId: userId,
      );

      if (response.isAuthenticated) {
        await _storageService.saveToken(response.token!);
      }

      return response;
    });
  }

  /// Requests a new OTP for phone verification.
  Future<Result<String>> resendOtp({required int userId}) async {
    return _guard(() async {
      final json = await _dataSource.resendOtp(userId: userId);
      return json['message'] as String? ?? 'تم إرسال الرمز بنجاح';
    });
  }

  // ---------------------------------------------------------------------------
  // Forgot / Reset Password
  // ---------------------------------------------------------------------------

  /// Sends a password-reset OTP to [phone].
  Future<Result<String>> forgotPassword({required String phone}) async {
    return _guard(() async {
      final json = await _dataSource.forgotPassword(phone: phone);
      return json['message'] as String? ?? 'تم إرسال رمز التحقق';
    });
  }

  /// Resets the password using the provided [token].
  Future<Result<String>> resetPassword({
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    return _guard(() async {
      final json = await _dataSource.resetPassword(
        token: token,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      return json['message'] as String? ?? 'تم إعادة تعيين كلمة المرور بنجاح';
    });
  }

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  /// Fetches the authenticated user's profile.
  Future<Result<UserModel>> getMe() async {
    return _guard(() => _dataSource.getMe());
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  /// Logs out the current user by invalidating the token on the server and
  /// removing it from local storage.
  Future<Result<void>> logout() async {
    return _guard(() async {
      try {
        await _dataSource.logout();
      } catch (_) {
        // Best-effort server call; even if it fails we still clear local state.
      }
      await _storageService.clearAll();
    });
  }

  // ---------------------------------------------------------------------------
  // Token helpers
  // ---------------------------------------------------------------------------

  /// Returns `true` when a persisted access token exists.
  Future<bool> hasToken() => _storageService.hasToken();

  /// Returns the stored access token, if any.
  Future<String?> getToken() => _storageService.getToken();

  // ---------------------------------------------------------------------------
  // Private: unified error handling
  // ---------------------------------------------------------------------------

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      final data = await body();
      return Result.success(data);
    } on ValidationException catch (e) {
      return Result.failure(e.message, fieldErrors: e.errors);
    } on ApiException catch (e) {
      return Result.failure(e.message);
    } catch (e) {
      return Result.failure('حدث خطأ غير متوقع. حاول مرة أخرى.');
    }
  }
}

// =============================================================================
// Provider
// =============================================================================

/// Riverpod provider for [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(authRemoteDataSourceProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(dataSource: dataSource, storageService: storage);
});
