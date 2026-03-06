import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/features/auth/data/models/auth_response_model.dart';
import 'package:orbit_app/features/auth/data/models/user_model.dart';

/// Remote data source that communicates with the ORBIT SMS V3 auth endpoints.
///
/// All methods throw [ApiException] subtypes on failure; the repository layer
/// is responsible for mapping those into user-facing results.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final ApiClient _client;

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------

  /// Authenticates using [username] (which may be a phone number or a username)
  /// and [password].
  ///
  /// Optionally sends [fcmToken] so the server can associate the device with
  /// push notifications.
  ///
  /// Returns an [AuthResponseModel] which may indicate either successful login
  /// or a 2FA challenge.
  Future<AuthResponseModel> login({
    required String username,
    required String password,
    String? fcmToken,
  }) async {
    final response = await _client.post(
      ApiConstants.login,
      data: {
        'username': username,
        'password': password,
        if (fcmToken != null) 'fcm_token': fcmToken,
      },
    );

    return AuthResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ---------------------------------------------------------------------------
  // Register
  // ---------------------------------------------------------------------------

  /// Registers a new user account.
  ///
  /// [data] contains all form fields. File fields (e.g. profile photo,
  /// freelance document) must already be [MultipartFile] instances inside
  /// [files]. The method merges them into a single `FormData` upload.
  Future<AuthResponseModel> register({
    required Map<String, dynamic> data,
    Map<String, MultipartFile>? files,
  }) async {
    final Map<String, dynamic> formMap = {...data};
    if (files != null) {
      formMap.addAll(files);
    }

    final formData = FormData.fromMap(formMap);

    final response = await _client.post(
      ApiConstants.register,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return AuthResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ---------------------------------------------------------------------------
  // Two-Factor Verification
  // ---------------------------------------------------------------------------

  /// Completes the two-factor authentication challenge.
  ///
  /// [code] is the 6-digit OTP the user received.
  /// [verificationUuid] is the UUID returned by the login endpoint.
  Future<AuthResponseModel> verify2fa({
    required String code,
    required String verificationUuid,
  }) async {
    final response = await _client.post(
      ApiConstants.verify2fa,
      data: {
        'code': code,
        'verification_uuid': verificationUuid,
      },
    );

    return AuthResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ---------------------------------------------------------------------------
  // Phone Verification (post-registration)
  // ---------------------------------------------------------------------------

  /// Verifies the user's phone number using the OTP [code].
  Future<AuthResponseModel> verifyPhone({
    required String code,
    required int userId,
  }) async {
    final response = await _client.post(
      ApiConstants.verifyPhone,
      data: {
        'code': code,
        'user_id': userId,
      },
    );

    return AuthResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Requests a new OTP code for the given [userId].
  Future<Map<String, dynamic>> resendOtp({required int userId}) async {
    final response = await _client.post(
      ApiConstants.resendOtp,
      data: {
        'user_id': userId,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Forgot / Reset Password
  // ---------------------------------------------------------------------------

  /// Initiates the password-reset flow by sending an OTP to [phone].
  Future<Map<String, dynamic>> forgotPassword({
    required String phone,
  }) async {
    final response = await _client.post(
      ApiConstants.forgotPassword,
      data: {
        'phone': phone,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  /// Resets the user's password using the reset [token].
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _client.post(
      ApiConstants.resetPassword,
      data: {
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // User Profile
  // ---------------------------------------------------------------------------

  /// Fetches the currently authenticated user's profile.
  Future<UserModel> getMe() async {
    final response = await _client.get(ApiConstants.me);
    final json = response.data as Map<String, dynamic>;

    // Handle both { "data": { ... } } and flat { ... } envelopes.
    final userData = json.containsKey('data') && json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return UserModel.fromJson(userData);
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  /// Invalidates the current access token on the server.
  Future<void> logout() async {
    await _client.post(ApiConstants.logout);
  }
}

// =============================================================================
// Provider
// =============================================================================

/// Riverpod provider for [AuthRemoteDataSource].
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthRemoteDataSource(client);
});
