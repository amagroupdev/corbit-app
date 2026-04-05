import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/constants/app_theme.dart';

/// Type of stats card, each with its own gradient and icon.
enum StatsCardType { balance, services, consumedPoints }

/// A gradient stats card used on the dashboard to display key metrics.
///
/// Features:
/// - Full gradient background (varies by [type])
/// - Decorative wave/curve overlay pattern
/// - Icon, title, large value, and a "view all" link at the bottom
/// - RTL-aware layout
class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.type,
    required this.title,
    required this.value,
    this.unit = '',
    this.onTap,
    this.onViewAll,
    this.viewAllLabel,
    this.width,
  });

  /// Determines the gradient colors and icon.
  final StatsCardType type;

  /// Card title text (e.g. "الرصيد الحالي").
  final String title;

  /// Numeric value to display.
  final int value;

  /// Optional unit label (e.g. "رسالة").
  final String unit;

  /// Called when the entire card is tapped.
  final VoidCallback? onTap;

  /// Called when the "view all" link is tapped.
  final VoidCallback? onViewAll;

  /// Custom "view all" label. Defaults to "عرض جميع العمليات".
  final String? viewAllLabel;

  /// Optional fixed width. Defaults to 170.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientForType(type);
    final icon = _iconForType(type);
    final formattedValue = NumberFormat('#,###').format(value);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 170,
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── Decorative wave pattern ──────────────────────────────
            Positioned.fill(
              child: CustomPaint(
                painter: _WavePatternPainter(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.85),
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: AppTheme.spacingXs),

                // Value row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        formattedValue,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'IBMPlexSansArabic',
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.8),
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // View all link
                if (onViewAll != null) ...[
                  GestureDetector(
                    onTap: onViewAll,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          viewAllLabel ?? '',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                            fontFamily: 'IBMPlexSansArabic',
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Type-specific styling ────────────────────────────────────────────

  static LinearGradient _gradientForType(StatsCardType type) {
    switch (type) {
      case StatsCardType.balance:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.balanceOrangeStart,
            AppColors.balanceOrangeEnd,
          ],
        );
      case StatsCardType.services:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.balanceTealStart,
            AppColors.balanceTealEnd,
          ],
        );
      case StatsCardType.consumedPoints:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.balanceBlueStart,
            AppColors.balanceBlueEnd,
          ],
        );
    }
  }

  static IconData _iconForType(StatsCardType type) {
    switch (type) {
      case StatsCardType.balance:
        return Icons.account_balance_wallet_rounded;
      case StatsCardType.services:
        return Icons.miscellaneous_services_rounded;
      case StatsCardType.consumedPoints:
        return Icons.data_usage_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wave Pattern Painter (decorative)
// ─────────────────────────────────────────────────────────────────────────────

class _WavePatternPainter extends CustomPainter {
  _WavePatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Orbital arc stripes inspired by the Corbit logo.
    // Multiple concentric arc strokes emanating from bottom-right corner,
    // creating a partial circular/orbital pattern.
    final center = Offset(w * 1.05, h * 1.1);
    final baseRadius = w * 0.3;

    for (int i = 0; i < 6; i++) {
      final radius = baseRadius + (i * w * 0.11);
      final opacity = (0.18 - i * 0.02).clamp(0.04, 0.2);
      final strokeWidth = (3.5 - i * 0.35).clamp(1.2, 3.5);

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, 3.3, 2.4, false, paint);
    }

    // Second arc group from top-left corner for depth.
    final center2 = Offset(w * -0.1, h * -0.15);
    for (int i = 0; i < 4; i++) {
      final radius = w * 0.35 + (i * w * 0.13);
      final opacity = (0.12 - i * 0.025).clamp(0.03, 0.14);

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(center: center2, radius: radius);
      canvas.drawArc(rect, 0.2, 2.0, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
