import 'package:flutter/material.dart';
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';

/// A centered empty-state placeholder shown when a list or page has no data.
///
/// Displays a large icon, a title, an optional description, and an
/// optional action button to guide the user.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.icon,
    required this.title,
    this.description,
    this.actionText,
    this.onAction,
    this.iconSize = 80,
    this.iconColor,
    this.padding = const EdgeInsets.all(32),
    super.key,
  });

  /// The large icon displayed in the center (e.g. `Icons.inbox_outlined`).
  final IconData icon;

  /// Headline text below the icon.
  final String title;

  /// An optional supporting description.
  final String? description;

  /// Label for the optional action button.
  final String? actionText;

  /// Callback when the action button is pressed.
  final VoidCallback? onAction;

  /// Icon size. Defaults to 80.
  final double iconSize;

  /// Icon color override. Defaults to a light gray.
  final Color? iconColor;

  /// Outer padding. Defaults to 32 on all sides.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon ─────────────────────────────────────────
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? AppColors.textHint.withOpacity(0.5),
            ),
            const SizedBox(height: 24),

            // ── Title ────────────────────────────────────────
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            // ── Description ──────────────────────────────────
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // ── Action Button ────────────────────────────────
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              AppButton.primary(
                text: actionText!,
                onPressed: onAction,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
