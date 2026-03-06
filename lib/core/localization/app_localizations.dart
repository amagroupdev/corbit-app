import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:orbit_app/core/localization/ar.dart' as arabic;
import 'package:orbit_app/core/localization/en.dart' as english;

/// The set of locales supported by the ORBIT SMS application.
const List<Locale> supportedLocales = [
  Locale('ar'), // Arabic (default)
  Locale('en'), // English
];

/// Provides translated strings for the ORBIT SMS V3 application.
///
/// Usage from any widget:
/// ```dart
/// final t = AppLocalizations.of(context);
/// Text(t.translate('login'));
/// ```
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  // ---------------------------------------------------------------------------
  // Accessor
  // ---------------------------------------------------------------------------

  /// Retrieves the nearest [AppLocalizations] from the widget tree.
  ///
  /// Returns `null` only if the [AppLocalizationsDelegate] was never installed.
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // ---------------------------------------------------------------------------
  // Translation maps keyed by locale code
  // ---------------------------------------------------------------------------

  static const Map<String, Map<String, String>> _translations = {
    'ar': arabic.ar,
    'en': english.en,
  };

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns the translated string for the given [key].
  ///
  /// When the key does not exist in the current locale's map the key itself is
  /// returned so that missing translations are immediately visible during
  /// development.
  String translate(String key) {
    return _translations[locale.languageCode]?[key] ?? key;
  }

  /// Shorthand operator for [translate].
  ///
  /// ```dart
  /// final t = AppLocalizations.of(context)!;
  /// Text(t('login'));
  /// ```
  String call(String key) => translate(key);

  /// Translates a string that contains placeholder tokens such as `{count}`
  /// or `{min}` and replaces them with the provided [params].
  ///
  /// ```dart
  /// t.translateWithParams('minLength', {'min': '8'});
  /// // => "Minimum length is 8 characters"
  /// ```
  String translateWithParams(String key, Map<String, String> params) {
    String result = translate(key);
    params.forEach((placeholder, value) {
      result = result.replaceAll('{$placeholder}', value);
    });
    return result;
  }

  /// Returns the current locale's language code (`'ar'` or `'en'`).
  String get currentLocaleCode => locale.languageCode;

  /// Whether the current locale is right-to-left.
  bool get isRtl => locale.languageCode == 'ar';

  /// The [TextDirection] matching the current locale.
  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  /// Returns the list of all supported locales.
  static List<Locale> get locales => supportedLocales;

  /// Checks whether [locale] is among the supported locales.
  static bool isSupported(Locale locale) {
    return supportedLocales
        .any((supported) => supported.languageCode == locale.languageCode);
  }
}

/// [LocalizationsDelegate] that creates [AppLocalizations] instances.
///
/// Register this delegate in your `MaterialApp`:
/// ```dart
/// MaterialApp(
///   localizationsDelegates: const [
///     AppLocalizationsDelegate(),
///     GlobalMaterialLocalizations.delegate,
///     GlobalWidgetsLocalizations.delegate,
///     GlobalCupertinoLocalizations.delegate,
///   ],
///   supportedLocales: supportedLocales,
/// )
/// ```
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.isSupported(locale);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
