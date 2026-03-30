import 'package:orbit_app/features/auth/data/models/user_model.dart';

/// Encapsulates the API response for authentication requests (login, register).
///
/// The server may return one of two response shapes:
///
/// 1. **Direct authentication** -- contains an `access_token` and `user` object.
///    The client should persist the token and navigate to the main app.
///
/// 2. **Two-factor / OTP challenge** -- contains `requires_2fa: true` and a
///    `verification_uuid` that must be sent with the OTP code to complete
///    authentication.
class AuthResponseModel {
  const AuthResponseModel({
    this.token,
    this.user,
    this.requires2fa = false,
    this.verificationUuid,
    this.requiresPhoneVerification = false,
    this.userId,
    this.message,
  });

  /// JWT access token. Present only when authentication succeeds without 2FA.
  final String? token;

  /// The authenticated user. Present only when authentication succeeds.
  final UserModel? user;

  /// `true` when the server requires a second factor (OTP) before granting
  /// access. When `true`, [verificationUuid] will also be present.
  final bool requires2fa;

  /// UUID to pass alongside the OTP code when verifying two-factor auth.
  final String? verificationUuid;

  /// `true` when the user must verify their phone number (post-registration).
  final bool requiresPhoneVerification;

  /// User ID needed for phone verification flow.
  final int? userId;

  /// Optional server message (e.g. "OTP sent to your phone").
  final String? message;

  /// Whether the response represents a completed authentication (token received).
  bool get isAuthenticated => token != null && token!.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Parses the full API response body (the top-level JSON object).
  ///
  /// Handles both envelope patterns:
  /// ```json
  /// { "data": { "access_token": "...", "user": {...} } }
  /// ```
  /// and flat responses:
  /// ```json
  /// { "access_token": "...", "user": {...} }
  /// ```
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    // Some endpoints wrap their payload in a `data` key.
    final Map<String, dynamic> payload =
        json.containsKey('data') && json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : json;

    // Extract access token – the API may return it in several shapes:
    //   1. payload['access_token'] = "abc123"              (flat string)
    //   2. payload['token'] = "abc123"                     (flat string)
    //   3. payload['token'] = {"access_token": "abc123"}   (nested object)
    String? extractedToken;
    final tokenValue = payload['token'];
    if (tokenValue is String) {
      extractedToken = tokenValue;
    } else if (tokenValue is Map<String, dynamic>) {
      extractedToken = tokenValue['access_token'] as String?;
    }
    extractedToken ??= payload['access_token'] as String?;

    // Extract user ID from payload or nested user object.
    int? userId = payload['user_id'] as int?;
    if (userId == null && payload['user'] is Map<String, dynamic>) {
      userId = (payload['user'] as Map<String, dynamic>)['id'] as int?;
    }

    return AuthResponseModel(
      token: extractedToken,
      user: payload['user'] != null
          ? UserModel.fromJson(payload['user'] as Map<String, dynamic>)
          : null,
      requires2fa: payload['requires_2fa'] as bool? ??
          payload['requires_two_factor'] as bool? ??
          payload['require_2fa'] as bool? ??
          payload['two_factor_required'] as bool? ??
          payload['otp_required'] as bool? ??
          false,
      verificationUuid: payload['verification_uuid'] as String? ??
          payload['uuid'] as String? ??
          payload['otp_uuid'] as String?,
      requiresPhoneVerification:
          payload['requires_phone_verification'] as bool? ??
              payload['requires_verification'] as bool? ??
              false,
      userId: userId,
      message: json['message'] as String? ?? payload['message'] as String?,
    );
  }

  @override
  String toString() =>
      'AuthResponseModel(isAuthenticated: $isAuthenticated, '
      'requires2fa: $requires2fa, '
      'requiresPhoneVerification: $requiresPhoneVerification)';
}
