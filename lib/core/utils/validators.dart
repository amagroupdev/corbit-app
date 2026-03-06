/// Form-validation functions for the ORBIT SMS V3 application.
///
/// Every validator returns `null` when the value is valid and an error message
/// [String] otherwise, making them directly usable with Flutter's
/// `TextFormField.validator` parameter.
class Validators {
  const Validators._();

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
      return fieldName != null ? '$fieldName مطلوب' : 'هذا الحقل مطلوب';
    }
    return null;
  }

  /// Validates a standard email address.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'البريد الإلكتروني غير صالح';
    }
    return null;
  }

  /// Validates a Saudi mobile number (with or without country code).
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الجوال مطلوب';
    }
    // Strip spaces and dashes before testing.
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (!_saudiPhoneRegex.hasMatch(cleaned)) {
      return 'رقم الجوال غير صالح';
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
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 8) {
      return 'كلمة المرور قصيرة جداً (8 أحرف على الأقل)';
    }
    if (!_upperCaseRegex.hasMatch(value)) {
      return 'يجب أن تحتوي على حرف كبير واحد على الأقل';
    }
    if (!_lowerCaseRegex.hasMatch(value)) {
      return 'يجب أن تحتوي على حرف صغير واحد على الأقل';
    }
    if (!_digitRegex.hasMatch(value)) {
      return 'يجب أن تحتوي على رقم واحد على الأقل';
    }
    if (!_specialCharRegex.hasMatch(value)) {
      return 'يجب أن تحتوي على رمز خاص واحد على الأقل';
    }
    return null;
  }

  /// Ensures [value] matches [password].
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'تأكيد كلمة المرور مطلوب';
    }
    if (value != password) {
      return 'كلمات المرور غير متطابقة';
    }
    return null;
  }

  /// Validates a username: 3-30 alphanumeric characters, underscores, or
  /// hyphens.
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'اسم المستخدم مطلوب';
    }
    if (!_usernameRegex.hasMatch(value.trim())) {
      return 'اسم المستخدم غير صالح (3-30 حرف، أرقام، _ أو -)';
    }
    return null;
  }

  /// Validates that [value] has at least [min] characters.
  static String? validateMinLength(String? value, int min, {String? fieldName}) {
    if (value == null || value.length < min) {
      final label = fieldName ?? 'القيمة';
      return '$label يجب أن لا يقل عن $min أحرف';
    }
    return null;
  }

  /// Validates that [value] does not exceed [max] characters.
  static String? validateMaxLength(String? value, int max, {String? fieldName}) {
    if (value != null && value.length > max) {
      final label = fieldName ?? 'القيمة';
      return '$label يجب أن لا يزيد عن $max حرف';
    }
    return null;
  }

  /// Validates that [value] is a valid number (integer or decimal).
  static String? validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال رقم';
    }
    if (!_numberRegex.hasMatch(value.trim())) {
      return 'الرجاء إدخال رقم صحيح';
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
