import 'package:flutter/material.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/constants/app_theme.dart';

/// A compact card used in the dashboard's quick-access grid.
///
/// Shows an icon inside a colored circle, a title, an optional
/// count / subtitle, and a chevron arrow to indicate navigation.
class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.count,
    this.subtitle,
    this.iconColor = AppColors.primary,
    this.iconBackgroundColor,
    this.onTap,
  });

  /// Leading icon.
  final IconData icon;

  /// Primary label.
  final String title;

  /// Optional numeric count displayed under the title.
  final int? count;

  /// Optional subtitle text (shown instead of count when provided).
  final String? subtitle;

  /// Tint color for the icon.
  final Color iconColor;

  /// Background of the icon circle. Defaults to [iconColor] at 12% opacity.
  final Color? iconBackgroundColor;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        iconBackgroundColor ?? iconColor.withValues(alpha: 0.12);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              // ── Icon Circle ──────────────────────────────────────
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: iconColor,
                ),
              ),

              const SizedBox(width: AppTheme.spacingMd),

              // ── Text Content ─────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (count != null || (subtitle != null && subtitle!.isNotEmpty)) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle ?? '$count',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // ── Arrow ────────────────────────────────────────────
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
