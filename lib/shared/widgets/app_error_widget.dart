import 'package:flutter/material.dart';
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';

/// A full-width, centered error display with an icon, message, and
/// optional retry button.
///
/// Intended for inline error states (e.g. failed API responses) rather
/// than full-screen error pages, though it works fine for both.
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
    this.retryText,
    this.iconSize = 64,
    this.padding = const EdgeInsets.all(32),
    super.key,
  });

  /// The error message to display.
  final String message;

  /// Callback when the retry button is pressed. If null the retry button
  /// is hidden.
  final VoidCallback? onRetry;

  /// Icon displayed above the message. Defaults to a rounded error icon.
  final IconData icon;

  /// Text for the retry button. Defaults to a generic Arabic label.
  final String? retryText;

  /// Icon size. Defaults to 64.
  final double iconSize;

  /// Outer padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Error Icon ───────────────────────────────────
            Icon(
              icon,
              size: iconSize,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),

            // ── Message ──────────────────────────────────────
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            // ── Retry Button ─────────────────────────────────
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton.secondary(
                text: retryText ??
                    AppLocalizations.instance.translate('retry'),
                onPressed: onRetry,
                icon: Icons.refresh_rounded,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
