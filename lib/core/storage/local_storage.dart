import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys used for local (non-sensitive) preferences.
abstract class _PrefKeys {
  static const String locale = 'orbit_locale';
  static const String themeMode = 'orbit_theme_mode';
  static const String firstLaunch = 'orbit_first_launch';
  static const String rememberMe = 'orbit_remember_me';
  static const String lastUsername = 'orbit_last_username';
  static const String notificationsEnabled = 'orbit_notifications_enabled';
  static const String notificationSound = 'orbit_notification_sound';
  static const String notificationVibration = 'orbit_notification_vibration';
}

/// Riverpod provider that asynchronously initialises [LocalStorageService].
///
/// Usage:
/// ```dart
/// final localStorage = await ref.read(localStorageProvider.future);
/// ```
final localStorageProvider = FutureProvider<LocalStorageService>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return LocalStorageService(prefs);
});

/// Convenience provider that returns the already-resolved instance.
///
/// Only safe to use **after** the app has awaited [localStorageProvider] at
/// least once (e.g. during splash / bootstrap).
final localStorageSyncProvider = Provider<LocalStorageService>((ref) {
  return ref.watch(localStorageProvider).requireValue;
});

/// Lightweight wrapper around [SharedPreferences] that exposes typed helpers
/// for every user-facing preference in the ORBIT app.
class LocalStorageService {
  const LocalStorageService(this._prefs);

  final SharedPreferences _prefs;

  // ---------------------------------------------------------------------------
  // Locale / Language
  // ---------------------------------------------------------------------------

  /// Returns the persisted locale code (`'ar'` or `'en'`), defaulting to `'ar'`.
  String getLocale() {
    return _prefs.getString(_PrefKeys.locale) ?? 'ar';
  }

  /// Persists the selected locale code.
  Future<bool> setLocale(String localeCode) {
    return _prefs.setString(_PrefKeys.locale, localeCode);
  }

  /// Convenience getter that returns a [Locale] object.
  Locale get locale => Locale(getLocale());

  // ---------------------------------------------------------------------------
  // Theme Mode
  // ---------------------------------------------------------------------------

  /// Returns the persisted [ThemeMode], defaulting to [ThemeMode.system].
  ThemeMode getThemeMode() {
    final value = _prefs.getString(_PrefKeys.themeMode);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Persists the selected [ThemeMode].
  Future<bool> setThemeMode(ThemeMode mode) {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    return _prefs.setString(_PrefKeys.themeMode, value);
  }

  // ---------------------------------------------------------------------------
  // First Launch
  // ---------------------------------------------------------------------------

  /// Returns `true` if this is the first time the app has been opened.
  bool isFirstLaunch() {
    return _prefs.getBool(_PrefKeys.firstLaunch) ?? true;
  }

  /// Marks the first-launch onboarding as completed.
  Future<bool> setFirstLaunchCompleted() {
    return _prefs.setBool(_PrefKeys.firstLaunch, false);
  }

  // ---------------------------------------------------------------------------
  // Remember Me
  // ---------------------------------------------------------------------------

  /// Whether the user opted for "remember me" on the login screen.
  bool getRememberMe() {
    return _prefs.getBool(_PrefKeys.rememberMe) ?? false;
  }

  /// Stores the "remember me" flag.
  Future<bool> setRememberMe(bool value) {
    return _prefs.setBool(_PrefKeys.rememberMe, value);
  }

  // ---------------------------------------------------------------------------
  // Last Username
  // ---------------------------------------------------------------------------

  /// Returns the last username that was entered on the login screen, or `null`.
  String? getLastUsername() {
    return _prefs.getString(_PrefKeys.lastUsername);
  }

  /// Persists the last used username so it can be pre-filled.
  Future<bool> setLastUsername(String username) {
    return _prefs.setString(_PrefKeys.lastUsername, username);
  }

  /// Clears the stored username (e.g. when "remember me" is toggled off).
  Future<bool> clearLastUsername() {
    return _prefs.remove(_PrefKeys.lastUsername);
  }

  // ---------------------------------------------------------------------------
  // Notification Settings
  // ---------------------------------------------------------------------------

  /// Whether push notifications are enabled (app-level toggle).
  bool getNotificationsEnabled() {
    return _prefs.getBool(_PrefKeys.notificationsEnabled) ?? true;
  }

  /// Stores the push-notification toggle state.
  Future<bool> setNotificationsEnabled(bool value) {
    return _prefs.setBool(_PrefKeys.notificationsEnabled, value);
  }

  /// Whether a sound should accompany notifications.
  bool getNotificationSound() {
    return _prefs.getBool(_PrefKeys.notificationSound) ?? true;
  }

  /// Stores the notification-sound preference.
  Future<bool> setNotificationSound(bool value) {
    return _prefs.setBool(_PrefKeys.notificationSound, value);
  }

  /// Whether vibration should accompany notifications.
  bool getNotificationVibration() {
    return _prefs.getBool(_PrefKeys.notificationVibration) ?? true;
  }

  /// Stores the notification-vibration preference.
  Future<bool> setNotificationVibration(bool value) {
    return _prefs.setBool(_PrefKeys.notificationVibration, value);
  }

  // ---------------------------------------------------------------------------
  // Generic Helpers
  // ---------------------------------------------------------------------------

  /// Reads a [String] value by [key], returning [defaultValue] when absent.
  String getString(String key, {String defaultValue = ''}) {
    return _prefs.getString(key) ?? defaultValue;
  }

  /// Writes a [String] value under [key].
  Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }

  /// Reads a [bool] value by [key], returning [defaultValue] when absent.
  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  /// Writes a [bool] value under [key].
  Future<bool> setBool(String key, bool value) {
    return _prefs.setBool(key, value);
  }

  /// Reads an [int] value by [key], returning [defaultValue] when absent.
  int getInt(String key, {int defaultValue = 0}) {
    return _prefs.getInt(key) ?? defaultValue;
  }

  /// Writes an [int] value under [key].
  Future<bool> setInt(String key, int value) {
    return _prefs.setInt(key, value);
  }

  /// Reads a [double] value by [key], returning [defaultValue] when absent.
  double getDouble(String key, {double defaultValue = 0.0}) {
    return _prefs.getDouble(key) ?? defaultValue;
  }

  /// Writes a [double] value under [key].
  Future<bool> setDouble(String key, double value) {
    return _prefs.setDouble(key, value);
  }

  /// Reads a [List<String>] by [key], returning an empty list when absent.
  List<String> getStringList(String key) {
    return _prefs.getStringList(key) ?? [];
  }

  /// Writes a [List<String>] under [key].
  Future<bool> setStringList(String key, List<String> value) {
    return _prefs.setStringList(key, value);
  }

  /// Removes a single entry identified by [key].
  Future<bool> remove(String key) {
    return _prefs.remove(key);
  }

  /// Returns `true` if storage contains the given [key].
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  /// Removes **all** entries stored by this application.
  Future<bool> clearAll() {
    return _prefs.clear();
  }
}
