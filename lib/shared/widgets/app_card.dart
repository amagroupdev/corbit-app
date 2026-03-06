import 'package:flutter/material.dart';
import 'package:orbit_app/core/constants/app_colors.dart';

/// A reusable card widget with consistent styling across the ORBIT app.
///
/// Provides:
/// - White surface background
/// - Rounded corners (16)
/// - Subtle elevation shadow
/// - Optional header row with title and action button
/// - Optional [onTap] for interactive cards
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.headerTitle,
    this.headerAction,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16,
    this.elevation,
    this.backgroundColor,
    this.border,
    super.key,
  });

  /// The main body content of the card.
  final Widget child;

  /// If provided, the card becomes tappable.
  final VoidCallback? onTap;

  /// Title shown in the header row (top of card).
  final String? headerTitle;

  /// An optional trailing widget in the header (e.g. "See all" button).
  final Widget? headerAction;

  /// Inner padding. Defaults to 16 on all sides.
  final EdgeInsetsGeometry padding;

  /// Outer margin around the card.
  final EdgeInsetsGeometry? margin;

  /// Corner radius. Defaults to 16.
  final double borderRadius;

  /// Shadow elevation override.
  final double? elevation;

  /// Background color override.
  final Color? backgroundColor;

  /// Optional border for the card.
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final hasHeader = headerTitle != null || headerAction != null;

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header ──────────────────────────────────────────
        if (hasHeader) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (headerTitle != null)
                Expanded(
                  child: Text(
                    headerTitle!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (headerAction != null) headerAction!,
            ],
          ),
          const SizedBox(height: 12),
        ],

        // ── Body ────────────────────────────────────────────
        child,
      ],
    );

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: elevation ?? 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: cardContent,
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.primarySurface,
          highlightColor: AppColors.primarySurface.withValues(alpha: 0.3),
          child: card,
        ),
      );
    }

    return card;
  }
}
