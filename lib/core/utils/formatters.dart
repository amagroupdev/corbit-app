import 'package:intl/intl.dart';

/// Formatting utilities for the ORBIT SMS V3 application.
///
/// All methods are static and stateless so they can be called from anywhere
/// without instantiation.
class Formatters {
  const Formatters._();

  // ---------------------------------------------------------------------------
  // Phone
  // ---------------------------------------------------------------------------

  /// Normalises a Saudi phone number to the international format `+966XXXXXXXXX`.
  ///
  /// Accepted inputs:
  /// - `5XXXXXXXX`  -> `+9665XXXXXXXX`
  /// - `05XXXXXXXX` -> `+9665XXXXXXXX`
  /// - `9665XXXXXXXX` -> `+9665XXXXXXXX`
  /// - `+9665XXXXXXXX` -> `+9665XXXXXXXX`
  ///
  /// Returns the cleaned string unchanged if it does not match any known
  /// pattern.
  static String formatPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-()]'), '');

    if (cleaned.startsWith('+966')) {
      return cleaned;
    }
    if (cleaned.startsWith('966')) {
      return '+$cleaned';
    }
    if (cleaned.startsWith('05')) {
      return '+966${cleaned.substring(1)}';
    }
    if (cleaned.startsWith('5') && cleaned.length == 9) {
      return '+966$cleaned';
    }
    // Fallback: return as-is.
    return phone;
  }

  /// Returns a display-friendly Saudi phone: `+966 5X XXX XXXX`.
  static String formatPhoneDisplay(String phone) {
    final normalised = formatPhone(phone);
    if (normalised.length == 13 && normalised.startsWith('+966')) {
      final local = normalised.substring(4); // 9 digits
      return '+966 ${local.substring(0, 2)} ${local.substring(2, 5)} ${local.substring(5)}';
    }
    return normalised;
  }

  // ---------------------------------------------------------------------------
  // Date / Time
  // ---------------------------------------------------------------------------

  /// Formats a [DateTime] as `yyyy/MM/dd` (e.g. `2025/06/15`).
  static String formatDate(DateTime date, {String pattern = 'yyyy/MM/dd'}) {
    return DateFormat(pattern).format(date);
  }

  /// Formats a [DateTime] as `yyyy/MM/dd HH:mm` (e.g. `2025/06/15 14:30`).
  static String formatDateTime(DateTime date,
      {String pattern = 'yyyy/MM/dd HH:mm'}) {
    return DateFormat(pattern).format(date);
  }

  /// Formats a [DateTime] as a time string `HH:mm` (e.g. `14:30`).
  static String formatTime(DateTime date, {String pattern = 'HH:mm'}) {
    return DateFormat(pattern).format(date);
  }

  /// Returns a human-readable relative time string such as "Just now",
  /// "5 minutes ago", "2 hours ago", "Yesterday", etc.
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'الآن';
    }
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'منذ $minutes ${minutes == 1 ? 'دقيقة' : 'دقائق'}';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'منذ $hours ${hours == 1 ? 'ساعة' : 'ساعات'}';
    }
    if (difference.inDays == 1) {
      return 'أمس';
    }
    if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    }
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'منذ $weeks ${weeks == 1 ? 'أسبوع' : 'أسابيع'}';
    }
    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'منذ $months ${months == 1 ? 'شهر' : 'أشهر'}';
    }
    final years = (difference.inDays / 365).floor();
    return 'منذ $years ${years == 1 ? 'سنة' : 'سنوات'}';
  }

  /// English variant of [timeAgo].
  static String timeAgoEn(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) {
      final m = difference.inMinutes;
      return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
    }
    if (difference.inHours < 24) {
      final h = difference.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} ago';
    }
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) {
      final w = (difference.inDays / 7).floor();
      return '$w ${w == 1 ? 'week' : 'weeks'} ago';
    }
    if (difference.inDays < 365) {
      final mo = (difference.inDays / 30).floor();
      return '$mo ${mo == 1 ? 'month' : 'months'} ago';
    }
    final y = (difference.inDays / 365).floor();
    return '$y ${y == 1 ? 'year' : 'years'} ago';
  }

  // ---------------------------------------------------------------------------
  // Currency
  // ---------------------------------------------------------------------------

  /// Formats a monetary amount in Saudi Riyals.
  ///
  /// Examples:
  /// - `formatCurrency(1500)` => `1,500.00 ر.س`
  /// - `formatCurrency(1500, showSymbol: false)` => `1,500.00`
  static String formatCurrency(
    num amount, {
    bool showSymbol = true,
    int decimalDigits = 2,
  }) {
    final formatter = NumberFormat.currency(
      locale: 'ar_SA',
      symbol: '',
      decimalDigits: decimalDigits,
    );
    final formatted = formatter.format(amount).trim();
    return showSymbol ? '$formatted ر.س' : formatted;
  }

  // ---------------------------------------------------------------------------
  // Numbers
  // ---------------------------------------------------------------------------

  /// Formats a number with thousands separators.
  ///
  /// `formatNumber(12500)` => `12,500`
  static String formatNumber(num value) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(value);
  }

  /// Formats a percentage value.
  ///
  /// `formatPercentage(0.85)` => `85%`
  static String formatPercentage(double value, {int decimalDigits = 0}) {
    return '${(value * 100).toStringAsFixed(decimalDigits)}%';
  }

  // ---------------------------------------------------------------------------
  // SMS-Specific
  // ---------------------------------------------------------------------------

  /// Returns the number of SMS segments required for a message of the given
  /// [length] using the standard GSM-7 encoding rules.
  ///
  /// - 1 SMS  : up to 160 characters
  /// - 2+ SMS : 153 characters per segment (7-char UDH header)
  ///
  /// For Arabic / Unicode messages:
  /// - 1 SMS  : up to 70 characters
  /// - 2+ SMS : 67 characters per segment
  static int smsSegmentCount(int length, {bool isUnicode = true}) {
    if (length == 0) return 0;
    if (isUnicode) {
      return length <= 70 ? 1 : (length / 67).ceil();
    }
    return length <= 160 ? 1 : (length / 153).ceil();
  }

  /// Formats the SMS count as a human-readable string:
  /// `"3 رسائل (450 حرف)"`.
  static String formatSmsCount(int charCount, {bool isUnicode = true}) {
    final segments = smsSegmentCount(charCount, isUnicode: isUnicode);
    final maxPerSegment = isUnicode
        ? (segments == 1 ? 70 : 67)
        : (segments == 1 ? 160 : 153);
    final remaining = (maxPerSegment * segments) - charCount;
    return '$segments ${segments == 1 ? 'رسالة' : 'رسائل'} '
        '($charCount حرف، متبقي $remaining)';
  }

  // ---------------------------------------------------------------------------
  // File Size
  // ---------------------------------------------------------------------------

  /// Converts bytes into a human-readable file size string.
  ///
  /// `formatFileSize(1536)` => `1.5 KB`
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
