import 'package:flutter/material.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/constants/app_theme.dart';

/// Animated typing indicator with three bouncing dots.
///
/// Displayed in the chat when the AI assistant is generating a response.
class AiTypingIndicator extends StatefulWidget {
  const AiTypingIndicator({super.key});

  @override
  State<AiTypingIndicator> createState() => _AiTypingIndicatorState();
}

class _AiTypingIndicatorState extends State<AiTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingXs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar ─────────────────────────────────────────────────
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primarySurface,
            child: const Icon(
              Icons.smart_toy_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),

          // ── Dots bubble ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: AppTheme.spacingMd,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusLg),
                topRight: Radius.circular(AppTheme.radiusLg),
                bottomLeft: Radius.circular(AppTheme.radiusXs),
                bottomRight: Radius.circular(AppTheme.radiusLg),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    // Stagger each dot by 0.2 of the animation cycle.
                    final delay = index * 0.2;
                    final progress =
                        ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);

                    // Bounce curve: sin produces a smooth up-down motion.
                    final offset = -4.0 * _bounceCurve(progress);

                    return Padding(
                      padding: EdgeInsets.only(
                        left: index > 0 ? 4.0 : 0.0,
                      ),
                      child: Transform.translate(
                        offset: Offset(0, offset),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.textHint.withValues(
                              alpha: 0.5 + 0.5 * _bounceCurve(progress),
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Returns a bounce value between 0 and 1 for the given progress.
  double _bounceCurve(double t) {
    // Only bounce in the first half of the cycle.
    if (t < 0.5) {
      return (t * 2.0); // 0 → 1
    } else {
      return (1.0 - (t - 0.5) * 2.0); // 1 → 0
    }
  }
}
