import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/constants/app_theme.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/core/providers/locale_provider.dart';
import 'package:orbit_app/routing/route_names.dart';

/// Custom app bar for the dashboard screen.
///
/// Displays the user avatar with an online status indicator, a notification
/// bell with an unread-count badge, and a language toggle button.
class DashboardAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const DashboardAppBar({
    super.key,
    this.userName = '',
    this.userAvatar = '',
    this.notificationCount = 0,
  });

  final String userName;
  final String userAvatar;
  final int notificationCount;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
          ),
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                // ── User Avatar ──────────────────────────────────────
                _UserAvatar(
                  imageUrl: userAvatar,
                  userName: userName,
                  onTap: () => context.pushNamed(RouteNames.profile),
                ),

                const SizedBox(width: AppTheme.spacingMd),

                // ── App Logo ──────────────────────────────────────
                Expanded(
                  child: Image.asset(
                    'assets/images/orbit-logo.png',
                    height: 40,
                    alignment: AlignmentDirectional.centerStart,
                  ),
                ),

                // ── Language Toggle ──────────────────────────────────
                _LanguageToggle(
                  isArabic: isArabic,
                  onTap: () {
                    ref.read(localeProvider.notifier).toggleLocale();
                  },
                ),

                const SizedBox(width: AppTheme.spacingXs),

                // ── Notification Bell ────────────────────────────────
                _NotificationBell(
                  count: notificationCount,
                  onTap: () => context.pushNamed(RouteNames.notifications),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User Avatar with Online Indicator
// ─────────────────────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.imageUrl,
    required this.userName,
    required this.onTap,
  });

  final String imageUrl;
  final String userName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          children: [
            // Avatar circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border,
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _avatarPlaceholder(),
                        errorWidget: (_, __, ___) => _avatarPlaceholder(),
                      )
                    : _avatarPlaceholder(),
              ),
            ),

            // Online dot
            Positioned(
              bottom: 1,
              right: 1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Image.asset(
      'assets/images/avatar.png',
      fit: BoxFit.cover,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification Bell with Badge
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_outlined,
                size: 26,
                color: AppColors.textPrimary,
              ),
              if (count > 0)
                Positioned(
                  top: 4,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    constraints: const BoxConstraints(minWidth: 18),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.surface,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Language Toggle
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({
    required this.isArabic,
    required this.onTap,
  });

  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                isArabic ? 'En' : (AppLocalizations.of(context)?.translate('langToggleAr') ?? 'Ar'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
