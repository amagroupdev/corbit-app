import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// General-purpose helper utilities for the ORBIT SMS V3 application.
///
/// Most helpers accept a [BuildContext] because they interact with the overlay
/// layer (snackbars, dialogs, bottom sheets).
class AppHelpers {
  const AppHelpers._();

  // ---------------------------------------------------------------------------
  // Snackbar
  // ---------------------------------------------------------------------------

  /// Shows a themed [SnackBar] at the bottom of the screen.
  ///
  /// [type] controls the background color:
  /// - [SnackBarType.success] green
  /// - [SnackBarType.error] red
  /// - [SnackBarType.info] blue
  /// - [SnackBarType.warning] orange
  static void showAppSnackBar(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final Color backgroundColor;
    final IconData icon;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = const Color(0xFF4CAF50);
        icon = Icons.check_circle_outline;
      case SnackBarType.error:
        backgroundColor = const Color(0xFFF44336);
        icon = Icons.error_outline;
      case SnackBarType.warning:
        backgroundColor = const Color(0xFFFF9800);
        icon = Icons.warning_amber_outlined;
      case SnackBarType.info:
        backgroundColor = const Color(0xFF2196F3);
        icon = Icons.info_outline;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          duration: duration,
          action: action,
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // Dialog
  // ---------------------------------------------------------------------------

  /// Shows a standard confirmation dialog and returns `true` if the user
  /// taps the confirm button.
  static Future<bool?> showAppDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    Color? confirmColor,
    bool isDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText ?? 'إلغاء',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              confirmText ?? 'تأكيد',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Sheet
  // ---------------------------------------------------------------------------

  /// Shows a modal bottom sheet with rounded top corners.
  static Future<T?> showAppBottomSheet<T>(
    BuildContext context, {
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = true,
    double? maxHeight,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      constraints: maxHeight != null
          ? BoxConstraints(maxHeight: maxHeight)
          : null,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight:
              maxHeight ?? MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Loading Dialog
  // ---------------------------------------------------------------------------

  static bool _isLoadingVisible = false;

  /// Shows a non-dismissible loading indicator overlay.
  static void showLoadingDialog(BuildContext context, {String? message}) {
    if (_isLoadingVisible) return;
    _isLoadingVisible = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hides the loading dialog shown by [showLoadingDialog].
  static void hideLoadingDialog(BuildContext context) {
    if (!_isLoadingVisible) return;
    _isLoadingVisible = false;
    Navigator.of(context, rootNavigator: true).pop();
  }

  // ---------------------------------------------------------------------------
  // Clipboard
  // ---------------------------------------------------------------------------

  /// Copies [text] to the system clipboard and optionally shows a snackbar
  /// confirmation.
  static Future<void> copyToClipboard(
    BuildContext context, {
    required String text,
    String? successMessage,
    bool showSnackBar = true,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (showSnackBar && context.mounted) {
      showAppSnackBar(
        context,
        message: successMessage ?? 'تم النسخ',
        type: SnackBarType.success,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // URL Launcher
  // ---------------------------------------------------------------------------

  /// Opens [url] in the platform's default browser or app.
  ///
  /// Shows an error snackbar when the URL cannot be launched.
  static Future<void> launchURL(
    BuildContext context, {
    required String url,
    LaunchMode mode = LaunchMode.externalApplication,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: 'رابط غير صالح',
          type: SnackBarType.error,
        );
      }
      return;
    }

    try {
      final launched = await launchUrl(uri, mode: mode);
      if (!launched && context.mounted) {
        showAppSnackBar(
          context,
          message: 'تعذر فتح الرابط',
          type: SnackBarType.error,
        );
      }
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: 'تعذر فتح الرابط',
          type: SnackBarType.error,
        );
      }
    }
  }

  /// Convenience method to open a phone dialer.
  static Future<void> launchPhone(BuildContext context, String phone) {
    return launchURL(context, url: 'tel:$phone');
  }

  /// Convenience method to compose an email.
  static Future<void> launchEmail(BuildContext context, String email) {
    return launchURL(context, url: 'mailto:$email');
  }

  /// Convenience method to open WhatsApp with an optional message.
  static Future<void> launchWhatsApp(
    BuildContext context, {
    required String phone,
    String? message,
  }) {
    final encoded = message != null ? Uri.encodeComponent(message) : '';
    final url = 'https://wa.me/$phone${encoded.isNotEmpty ? '?text=$encoded' : ''}';
    return launchURL(context, url: url);
  }

  // ---------------------------------------------------------------------------
  // File Utilities
  // ---------------------------------------------------------------------------

  /// Returns a human-readable file size string.
  ///
  /// ```dart
  /// getFileSize(2048) // => '2.0 KB'
  /// ```
  static String getFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (math.log(bytes) / math.log(1024)).floor().clamp(0, 4);
    final size = bytes / math.pow(1024, i);
    return '${size.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
  }

  /// Extracts the file extension (without the dot) from a file path or name.
  ///
  /// ```dart
  /// getFileExtension('report.pdf') // => 'pdf'
  /// getFileExtension('archive.tar.gz') // => 'gz'
  /// ```
  static String getFileExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) return '';
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  /// Returns an appropriate [IconData] for common file extensions.
  static IconData getFileIcon(String fileName) {
    final ext = getFileExtension(fileName);
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'svg':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.folder_zip;
      case 'txt':
        return Icons.text_snippet;
      case 'json':
      case 'xml':
      case 'yaml':
      case 'yml':
        return Icons.code;
      default:
        return Icons.insert_drive_file;
    }
  }

  // ---------------------------------------------------------------------------
  // Miscellaneous
  // ---------------------------------------------------------------------------

  /// Generates a random hex colour string (e.g. `#A3C1AD`).
  static Color randomColor() {
    final random = math.Random();
    return Color.fromARGB(
      255,
      random.nextInt(200) + 55,
      random.nextInt(200) + 55,
      random.nextInt(200) + 55,
    );
  }

  /// Unfocuses the current input field by removing focus from the tree.
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Returns `true` when the current platform text direction is RTL.
  static bool isRtl(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl;
  }
}

/// Classifies snackbar intent so [AppHelpers.showAppSnackBar] can pick the
/// appropriate colour and icon.
enum SnackBarType {
  success,
  error,
  warning,
  info,
}
