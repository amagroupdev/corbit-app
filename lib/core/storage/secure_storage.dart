import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keys used for secure storage entries.
abstract class _StorageKeys {
  static const String accessToken = 'orbit_access_token';
  static const String refreshToken = 'orbit_refresh_token';
}

/// Provides a singleton [SecureStorageService] instance via Riverpod.
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Service that wraps [FlutterSecureStorage] for persisting sensitive
/// credentials such as access tokens and refresh tokens.
///
/// All data is encrypted at rest using the platform keystore (Keychain on iOS,
/// EncryptedSharedPreferences on Android).
class SecureStorageService {
  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  final FlutterSecureStorage _storage;

  // ---------------------------------------------------------------------------
  // Access Token
  // ---------------------------------------------------------------------------

  /// Persists the JWT access token.
  Future<void> saveToken(String token) async {
    await _storage.write(key: _StorageKeys.accessToken, value: token);
  }

  /// Retrieves the stored access token, or `null` if none exists.
  Future<String?> getToken() async {
    return _storage.read(key: _StorageKeys.accessToken);
  }

  /// Removes the stored access token.
  Future<void> deleteToken() async {
    await _storage.delete(key: _StorageKeys.accessToken);
  }

  // ---------------------------------------------------------------------------
  // Refresh Token
  // ---------------------------------------------------------------------------

  /// Persists the refresh token used to obtain new access tokens.
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _StorageKeys.refreshToken, value: token);
  }

  /// Retrieves the stored refresh token, or `null` if none exists.
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _StorageKeys.refreshToken);
  }

  /// Removes the stored refresh token.
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _StorageKeys.refreshToken);
  }

  // ---------------------------------------------------------------------------
  // Bulk Operations
  // ---------------------------------------------------------------------------

  /// Removes **all** entries written by this service.
  ///
  /// Typically called during logout to ensure no stale credentials remain on
  /// the device.
  Future<void> clearAll() async {
    await Future.wait([
      deleteToken(),
      deleteRefreshToken(),
    ]);
  }

  // ---------------------------------------------------------------------------
  // Generic helpers (useful for future expansion)
  // ---------------------------------------------------------------------------

  /// Writes an arbitrary key-value pair to secure storage.
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  /// Reads an arbitrary value from secure storage by [key].
  Future<String?> read({required String key}) async {
    return _storage.read(key: key);
  }

  /// Deletes a single entry identified by [key].
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  /// Returns `true` when an access token is present in storage.
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
