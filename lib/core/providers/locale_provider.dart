import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/storage/local_storage.dart';

/// Notifier that manages the current application locale.
///
/// Defaults to Arabic (`ar`) and persists the user's choice via
/// [LocalStorageService] (SharedPreferences).
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._localStorage) : super(const Locale('ar')) {
    _loadSavedLocale();
  }

  final LocalStorageService _localStorage;

  /// Supported locales for the application.
  static const List<Locale> supportedLocales = [
    Locale('ar'),
    Locale('en'),
  ];

  void _loadSavedLocale() {
    final saved = _localStorage.getLocale();
    if (saved == 'ar' || saved == 'en') {
      state = Locale(saved);
    }
  }

  /// Change the app locale and persist the choice.
  Future<void> setLocale(Locale locale) async {
    if (state == locale) return;
    state = locale;
    await _localStorage.setLocale(locale.languageCode);
  }

  /// Toggle between Arabic and English.
  Future<void> toggleLocale() async {
    final next = state.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    await setLocale(next);
  }

  /// Current language code (e.g. `ar` or `en`).
  String get languageCode => state.languageCode;
}

/// Provider for the current locale.
///
/// Depends on [localStorageSyncProvider], which must be initialised before
/// this provider is first read (typically during app bootstrap / splash).
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final localStorage = ref.watch(localStorageSyncProvider);
  return LocaleNotifier(localStorage);
});
