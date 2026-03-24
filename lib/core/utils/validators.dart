import 'package:orbit_app/core/localization/app_localizations.dart';

/// Form-validation functions for the ORBIT SMS V3 application.
///
/// Every validator returns `null` when the value is valid and an error message
/// [String] otherwise, making them directly usable with Flutter's
/// `TextFormField.validator` parameter.
class Validators {
  const Validators._();

  // ---------------------------------------------------------------------------
  // Helper to get translated string
  // ---------------------------------------------------------------------------

  static String _t(String key) => AppLocalizations.instance.translate(key);

  static String _tParams(String key, Map<String, String> params) =>
      AppLocalizations.instance.translateWithParams(key, params);

  // ---------------------------------------------------------------------------
  // Regular expressions
  // ---------------------------------------------------------------------------

  /// Matches a standard email address.
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}'
    r'[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$',
  );

  /// Matches Saudi phone numbers in the following formats:
  /// - +966 5XXXXXXXX
  /// - 966 5XXXXXXXX
  /// - 05XXXXXXXX
  /// - 5XXXXXXXX
  static final RegExp _saudiPhoneRegex = RegExp(
    r'^(?:\+?966|0)?5[0-9]{8}$',
  );

  /// At least one uppercase ASCII letter.
  static final RegExp _upperCaseRegex = RegExp(r'[A-Z]');

  /// At least one lowercase ASCII letter.
  static final RegExp _lowerCaseRegex = RegExp(r'[a-z]');

  /// At least one digit.
  static final RegExp _digitRegex = RegExp(r'[0-9]');

  /// At least one special character.
  static final RegExp _specialCharRegex =
      RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~;]');

  /// Alphanumeric username with optional underscores/hyphens, 3-30 chars.
  static final RegExp _usernameRegex = RegExp(r'^[a-zA-Z0-9_-]{3,30}$');

  /// Matches a numeric value (integer or decimal, optionally negative).
  static final RegExp _numberRegex = RegExp(r'^-?\d+(\.\d+)?$');

  // ---------------------------------------------------------------------------
  // Validators
  // ---------------------------------------------------------------------------

  /// Ensures the field is not empty or whitespace-only.
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      if (fieldName != null) {
        return _tParams('fieldNameRequired', {'field': fieldName});
      }
      return _t('requiredField');
    }
    return null;
  }

  /// Validates a standard email address.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _t('emailRequired');
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return _t('emailInvalid');
    }
    return null;
  }

  /// Validates a Saudi mobile number (with or without country code).
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _t('phoneRequired');
    }
    // Strip spaces and dashes before testing.
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (!_saudiPhoneRegex.hasMatch(cleaned)) {
      return _t('phoneInvalid');
    }
    return null;
  }

  /// Validates a password with the following rules:
  /// - Minimum 8 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one digit
  /// - At least one special character
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return _t('passwordRequired');
    }
    if (value.length < 8) {
      return _t('passwordTooShortMsg');
    }
    if (!_upperCaseRegex.hasMatch(value)) {
      return _t('passwordNeedsUppercase');
    }
    if (!_lowerCaseRegex.hasMatch(value)) {
      return _t('passwordNeedsLowercase');
    }
    if (!_digitRegex.hasMatch(value)) {
      return _t('passwordNeedsDigit');
    }
    if (!_specialCharRegex.hasMatch(value)) {
      return _t('passwordNeedsSpecial');
    }
    return null;
  }

  /// Ensures [value] matches [password].
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return _t('confirmPasswordRequired');
    }
    if (value != password) {
      return _t('passwordMismatch');
    }
    return null;
  }

  /// Validates a username: 3-30 alphanumeric characters, underscores, or
  /// hyphens.
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _t('usernameRequired');
    }
    if (!_usernameRegex.hasMatch(value.trim())) {
      return _t('usernameInvalid');
    }
    return null;
  }

  /// Validates that [value] has at least [min] characters.
  static String? validateMinLength(String? value, int min, {String? fieldName}) {
    if (value == null || value.length < min) {
      final label = fieldName ?? _t('defaultFieldName');
      return _tParams('valueTooShort', {'field': label, 'min': '$min'});
    }
    return null;
  }

  /// Validates that [value] does not exceed [max] characters.
  static String? validateMaxLength(String? value, int max, {String? fieldName}) {
    if (value != null && value.length > max) {
      final label = fieldName ?? _t('defaultFieldName');
      return _tParams('valueTooLong', {'field': label, 'max': '$max'});
    }
    return null;
  }

  /// Validates that [value] is a valid number (integer or decimal).
  static String? validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _t('numberRequired');
    }
    if (!_numberRegex.hasMatch(value.trim())) {
      return _t('numberInvalid');
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Utility combinators
  // ---------------------------------------------------------------------------

  /// Composes multiple validators and returns the first error found, or `null`
  /// if all pass.
  ///
  /// ```dart
  /// TextFormField(
  ///   validator: Validators.compose([
  ///     (v) => Validators.validateRequired(v),
  ///     (v) => Validators.validateEmail(v),
  ///   ]),
  /// )
  /// ```
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
