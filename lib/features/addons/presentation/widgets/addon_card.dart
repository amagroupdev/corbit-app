import 'package:flutter/material.dart';
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/addons/data/models/addon_model.dart';

/// A card widget that displays an addon/service summary.
///
/// Shows the addon name, price, banner image, and activation status
/// with optional "recommended" badge and action button.
class AddonCard extends StatelessWidget {
  const AddonCard({
    required this.addon,
    required this.onTap,
    super.key,
  });

  final AddonModel addon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Banner image ─────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: addon.bannerUrl != null
                        ? Image.network(
                            addon.bannerUrl!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildPlaceholderBanner(),
                          )
                        : _buildPlaceholderBanner(),
                  ),

                  // Status badge
                  if (addon.isActive || addon.isFree || addon.isComingSoon)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildStatusBadge(),
                    ),
                ],
              ),

              // ── Content ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      addon.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      addon.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _buildPriceRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderBanner() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryLight, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.extension_outlined,
        color: Colors.white54,
        size: 48,
      ),
    );
  }

  Widget _buildStatusBadge() {
    String label;
    Color bgColor;
    Color textColor;

    if (addon.isActive) {
      label = '\u0645\u0641\u0639\u0644'; // مفعل
      bgColor = AppColors.successSurface;
      textColor = AppColors.success;
    } else if (addon.isFree) {
      label = '\u0645\u062C\u0627\u0646\u064A'; // مجاني
      bgColor = AppColors.infoSurface;
      textColor = AppColors.info;
    } else if (addon.isComingSoon) {
      label = '\u0642\u0631\u064A\u0628\u0627\u064B'; // قريباً
      bgColor = AppColors.warningSurface;
      textColor = AppColors.warning;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPriceRow() {
    if (addon.isFree) {
      return const Text(
        '\u0645\u062C\u0627\u0646\u064A', // مجاني
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.success,
        ),
      );
    }

    final cheapest = addon.cheapestPlan;
    if (cheapest == null) return const SizedBox.shrink();

    return Row(
      children: [
        Text(
          '\u064A\u0628\u062F\u0623 \u0645\u0646 ', // يبدأ من
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '${cheapest.price.toStringAsFixed(0)} \u0631.\u0633', // ر.س
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
