import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/balance/presentation/controllers/balance_controller.dart';

/// Upgrade Journey tab content.
///
/// Displays the user's current level, progress toward the next level,
/// and requirements to upgrade.
class UpgradeJourneyTab extends ConsumerStatefulWidget {
  const UpgradeJourneyTab({super.key});

  @override
  ConsumerState<UpgradeJourneyTab> createState() => _UpgradeJourneyTabState();
}

class _UpgradeJourneyTabState extends ConsumerState<UpgradeJourneyTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(balanceScreenControllerProvider);
    final balance = state.balance;
    final numberFormat = NumberFormat('#,##0', 'ar');

    // Define upgrade levels
    final levels = [
      _UpgradeLevel(
        name: '\u0623\u0633\u0627\u0633\u064A',
        minPurchase: 0,
        maxPurchase: 5000,
        pricePerSms: 0.065,
        color: AppColors.textSecondary,
        icon: Icons.star_outline,
      ),
      _UpgradeLevel(
        name: '\u0641\u0636\u064A',
        minPurchase: 5000,
        maxPurchase: 20000,
        pricePerSms: 0.055,
        color: AppColors.info,
        icon: Icons.star_half,
      ),
      _UpgradeLevel(
        name: '\u0630\u0647\u0628\u064A',
        minPurchase: 20000,
        maxPurchase: 50000,
        pricePerSms: 0.045,
        color: AppColors.warning,
        icon: Icons.star,
      ),
      _UpgradeLevel(
        name: '\u0628\u0644\u0627\u062A\u064A\u0646\u064A',
        minPurchase: 50000,
        maxPurchase: 100000,
        pricePerSms: 0.035,
        color: AppColors.primary,
        icon: Icons.workspace_premium,
      ),
      _UpgradeLevel(
        name: '\u0645\u0627\u0633\u064A',
        minPurchase: 100000,
        maxPurchase: 999999,
        pricePerSms: 0.025,
        color: AppColors.chartPurple,
        icon: Icons.diamond_outlined,
      ),
    ];

    // Determine current level based on totalPurchased
    final totalPurchased = balance?.totalPurchased ?? 0;
    int currentLevelIndex = 0;
    for (int i = levels.length - 1; i >= 0; i--) {
      if (totalPurchased >= levels[i].minPurchase) {
        currentLevelIndex = i;
        break;
      }
    }

    final currentLevel = levels[currentLevelIndex];
    final nextLevel = currentLevelIndex < levels.length - 1
        ? levels[currentLevelIndex + 1]
        : null;

    // Calculate progress
    double progress = 0;
    if (nextLevel != null) {
      final range = nextLevel.minPurchase - currentLevel.minPurchase;
      final achieved = totalPurchased - currentLevel.minPurchase;
      progress = range > 0 ? (achieved / range).clamp(0, 1) : 1;
    } else {
      progress = 1.0; // Max level
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current level card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  currentLevel.color,
                  currentLevel.color.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: currentLevel.color.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  currentLevel.icon,
                  size: 56,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const Text(
                  '\u0645\u0633\u062A\u0648\u0627\u0643 \u0627\u0644\u062D\u0627\u0644\u064A',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentLevel.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\u0633\u0639\u0631 \u0627\u0644\u0631\u0633\u0627\u0644\u0629: ${currentLevel.pricePerSms.toStringAsFixed(3)} \u0631.\u0633',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Progress toward next level
          if (nextLevel != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '\u0627\u0644\u062A\u0642\u062F\u0645 \u0646\u062D\u0648 \u0627\u0644\u0645\u0633\u062A\u0648\u0649 \u0627\u0644\u062A\u0627\u0644\u064A',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: nextLevel.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          nextLevel.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: nextLevel.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        currentLevel.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Progress text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${numberFormat.format(totalPurchased.toInt())} \u0631\u0633\u0627\u0644\u0629',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${numberFormat.format(nextLevel.minPurchase)} \u0631\u0633\u0627\u0644\u0629',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Remaining messages
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.infoSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.infoBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 20,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '\u062A\u062D\u062A\u0627\u062C ${numberFormat.format(nextLevel.minPurchase - totalPurchased.toInt())} \u0631\u0633\u0627\u0644\u0629 \u0625\u0636\u0627\u0641\u064A\u0629 \u0644\u0644\u0648\u0635\u0648\u0644 \u0625\u0644\u0649 \u0627\u0644\u0645\u0633\u062A\u0648\u0649 ${nextLevel.name}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.infoDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // All levels
          const Text(
            '\u0645\u0633\u062A\u0648\u064A\u0627\u062A \u0627\u0644\u062A\u0631\u0642\u064A\u0629',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          ...List.generate(levels.length, (index) {
            final level = levels[index];
            final isCurrentLevel = index == currentLevelIndex;
            final isCompleted = index < currentLevelIndex;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCurrentLevel
                    ? level.color.withValues(alpha: 0.05)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCurrentLevel ? level.color : AppColors.borderLight,
                  width: isCurrentLevel ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Level icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrentLevel
                          ? level.color.withValues(alpha: 0.15)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle
                          : level.icon,
                      size: 24,
                      color: isCompleted || isCurrentLevel
                          ? level.color
                          : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Level info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              level.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isCurrentLevel
                                    ? level.color
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (isCurrentLevel) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: level.color,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '\u062D\u0627\u0644\u064A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\u0645\u0646 ${numberFormat.format(level.minPurchase)} \u0631\u0633\u0627\u0644\u0629',
                          style: TextStyle(
                            fontSize: 12,
                            color: isCurrentLevel
                                ? level.color.withValues(alpha: 0.7)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price per SMS
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '\u0633\u0639\u0631 \u0627\u0644\u0631\u0633\u0627\u0644\u0629',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${level.pricePerSms.toStringAsFixed(3)} \u0631.\u0633',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isCurrentLevel
                              ? level.color
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Internal model for upgrade levels.
class _UpgradeLevel {
  const _UpgradeLevel({
    required this.name,
    required this.minPurchase,
    required this.maxPurchase,
    required this.pricePerSms,
    required this.color,
    required this.icon,
  });

  final String name;
  final int minPurchase;
  final int maxPurchase;
  final double pricePerSms;
  final Color color;
  final IconData icon;
}
