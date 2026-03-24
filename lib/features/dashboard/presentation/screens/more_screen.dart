import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/constants/app_strings.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/core/utils/helpers.dart';
import 'package:orbit_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:orbit_app/features/settings/presentation/controllers/settings_controller.dart';
import 'package:orbit_app/shared/widgets/app_confirmation_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

/// A single menu row inside the "More" screen.
///
/// When [externalUrl] is provided, tapping the item opens the URL in the
/// default browser instead of navigating to [route].
class _MoreMenuItem {
  const _MoreMenuItem({
    required this.icon,
    required this.title,
    this.route,
    this.externalUrl,
    this.iconColor,
  }) : assert(
          route != null || externalUrl != null,
          'Either route or externalUrl must be provided',
        );

  final IconData icon;
  final String title;
  final String? route;
  final String? externalUrl;
  final Color? iconColor;

  /// Whether this item opens an external URL.
  bool get isExternal => externalUrl != null;
}

/// A group of menu items under a shared category label.
class _MoreMenuGroup {
  const _MoreMenuGroup({
    required this.label,
    required this.items,
  });

  final String label;
  final List<_MoreMenuItem> items;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

/// The "More" tab screen listing every secondary section that is not
/// present in the bottom navigation bar.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  // ── Menu structure ────────────────────────────────────────────

  static List<_MoreMenuGroup> _buildGroups(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return [
      // ── Section 1: الرسائل (Messages) ─────────────────────────
      _MoreMenuGroup(
        label: t.translate('messagesSection'),
        items: [
          _MoreMenuItem(
            icon: Icons.mail_outlined,
            title: t.translate('messageCenter'),
            route: '/messages',
            iconColor: AppColors.primary,
          ),
          _MoreMenuItem(
            icon: Icons.archive_outlined,
            title: t.translate('archivedMessages'),
            route: '/archive',
            iconColor: AppColors.info,
          ),
          _MoreMenuItem(
            icon: Icons.verified_outlined,
            title: t.translate('studentCertificates'),
            route: '/certifications',
            iconColor: AppColors.success,
          ),
          _MoreMenuItem(
            icon: Icons.event_busy_outlined,
            title: t.translate('absenceMessages'),
            route: '/absence-messages',
            iconColor: AppColors.warning,
          ),
          _MoreMenuItem(
            icon: Icons.quiz_outlined,
            title: t.translate('questionnaires'),
            route: '/questionnaires',
            iconColor: AppColors.chartIndigo,
          ),
          _MoreMenuItem(
            icon: Icons.question_answer_outlined,
            title: t.translate('statements'),
            route: '/statements',
            iconColor: AppColors.chartTeal,
          ),
        ],
      ),

      // ── Section 2: أدوات الرسائل (Message Tools) ──────────────
      _MoreMenuGroup(
        label: t.translate('messageTools'),
        items: [
          _MoreMenuItem(
            icon: Icons.description_outlined,
            title: t.translate('templates'),
            route: '/templates',
            iconColor: AppColors.chartPurple,
          ),
          _MoreMenuItem(
            icon: Icons.person_outlined,
            title: t.translate('senderNames'),
            route: '/sender-names',
            iconColor: AppColors.chartBlue,
          ),
          _MoreMenuItem(
            icon: Icons.link_rounded,
            title: t.translate('shortenLinks'),
            route: '/short-links',
            iconColor: AppColors.chartTeal,
          ),
        ],
      ),

      // ── Section 3: الخدمات والإحصائيات ─────────────────────────
      _MoreMenuGroup(
        label: t.translate('servicesAndStatistics'),
        items: [
          _MoreMenuItem(
            icon: Icons.extension_outlined,
            title: t.translate('services'),
            route: '/services',
            iconColor: AppColors.chartOrange,
          ),
          _MoreMenuItem(
            icon: Icons.bar_chart_rounded,
            title: t.translate('statistics'),
            route: '/statistics',
            iconColor: AppColors.chartGreen,
          ),
        ],
      ),

      // ── Section 4: الحساب (Account) ───────────────────────────
      _MoreMenuGroup(
        label: t.translate('account'),
        items: [
          _MoreMenuItem(
            icon: Icons.settings_outlined,
            title: t.translate('settings'),
            route: '/settings',
            iconColor: AppColors.textSecondary,
          ),
          _MoreMenuItem(
            icon: Icons.notifications_outlined,
            title: t.translate('notifications'),
            route: '/notifications',
            iconColor: AppColors.warning,
          ),
        ],
      ),

      // ── Section 5: المساعدة (Help) ────────────────────────────
      _MoreMenuGroup(
        label: t.translate('helpSection'),
        items: [
          _MoreMenuItem(
            icon: Icons.menu_book_outlined,
            title: t.translate('userGuide'),
            externalUrl: 'https://orbit-sms.com/user-guide',
            iconColor: AppColors.chartBlue,
          ),
          _MoreMenuItem(
            icon: Icons.bug_report_outlined,
            title: t.translate('reportProblem'),
            route: '/contact-me',
            iconColor: AppColors.chartOrange,
          ),
          _MoreMenuItem(
            icon: Icons.help_outline_rounded,
            title: t.translate('helpAndSupport'),
            externalUrl: 'https://orbit-sms.com/help',
            iconColor: AppColors.chartGreen,
          ),
        ],
      ),

      // ── Section 6: القانونية (Legal) ──────────────────────
      _MoreMenuGroup(
        label: t.translate('legal'),
        items: [
          _MoreMenuItem(
            icon: Icons.gavel_outlined,
            title: t.translate('termsAndConditions'),
            externalUrl: AppStrings.urlTermsOfService,
            iconColor: AppColors.chartIndigo,
          ),
          _MoreMenuItem(
            icon: Icons.privacy_tip_outlined,
            title: t.translate('privacyPolicy'),
            externalUrl: AppStrings.urlPrivacyPolicy,
            iconColor: AppColors.chartPurple,
          ),
          _MoreMenuItem(
            icon: Icons.security_outlined,
            title: t.translate('regulatoryRules'),
            externalUrl: AppStrings.urlSpamRegulation,
            iconColor: AppColors.chartRed,
          ),
          _MoreMenuItem(
            icon: Icons.description_outlined,
            title: t.translate('usagePolicy'),
            route: '/terms-pdf',
            iconColor: AppColors.chartTeal,
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final groups = _buildGroups(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          t.translate('more'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ── User Card ──────────────────────────────────────
          const _UserInfoCard(),
          const SizedBox(height: 8),

          // ── Menu Groups ────────────────────────────────────
          for (final group in groups) ...[
            _GroupHeader(label: group.label),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (int i = 0; i < group.items.length; i++) ...[
                    _MenuItemTile(
                      item: group.items[i],
                      isFirst: i == 0,
                      isLast: i == group.items.length - 1,
                    ),
                    if (i < group.items.length - 1)
                      const Divider(
                        height: 0,
                        indent: 56,
                        endIndent: 16,
                        color: AppColors.divider,
                      ),
                  ],
                ],
              ),
            ),
          ],

          // ── Logout Button ──────────────────────────────────
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _LogoutButton(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal widgets
// ─────────────────────────────────────────────────────────────────────────────

/// User info card with avatar, name, and email.
/// Reads the authenticated user from [currentUserProvider], with fallback
/// to [profileProvider] for session-restore scenarios where the user
/// data hasn't been populated from a login response.
class _UserInfoCard extends ConsumerWidget {
  const _UserInfoCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    // Fallback: when currentUserProvider is null (session restore),
    // use profileProvider data from /auth/me.
    final profileAsync = ref.watch(profileProvider);
    final profileData = profileAsync.valueOrNull;

    final displayName = user?.name ??
        user?.username ??
        (profileData?['name'] as String? ?? '');
    final displayEmail = user?.email ??
        user?.phone ??
        (profileData?['email'] as String? ??
            profileData?['phone'] as String? ??
            '');
    final photoUrl = user?.profilePhotoUrl ??
        (profileData?['profile_photo_url'] as String? ?? '');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.dropShadow,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: photoUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      photoUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.person_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
          ),
          const SizedBox(width: 16),

          // Name & email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  displayEmail,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Profile arrow
          IconButton(
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white70,
              size: 28,
            ),
            onPressed: () => context.push('/profile'),
            splashRadius: 24,
          ),
        ],
      ),
    );
  }
}

/// Section header label.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// A single menu row.
class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  final _MoreMenuItem item;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (item.isExternal) {
            AppHelpers.launchURL(context, url: item.externalUrl!);
          } else {
            context.push(item.route!);
          }
        },
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(12) : Radius.zero,
          bottom: isLast ? const Radius.circular(12) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      (item.iconColor ?? AppColors.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  size: 20,
                  color: item.iconColor ?? AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (item.isExternal)
                Icon(
                  Icons.open_in_new_rounded,
                  color: AppColors.textHint,
                  size: 18,
                )
              else
                Icon(
                  isRtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Red logout button at the bottom of the list.
class _LogoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _handleLogout(context, ref),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: Text(
          t.translate('logout'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context)!;

    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: t.translate('logout'),
      message: t.translate('logoutConfirmMessage'),
      confirmText: t.translate('logout'),
      isDestructive: true,
      icon: Icons.logout_rounded,
    );

    if (confirmed && context.mounted) {
      // Clear token, user state, and auth state.
      await ref.read(logoutControllerProvider).logout();

      if (context.mounted) {
        // Navigate to login and clear the route stack.
        context.go('/login');
      }
    }
  }
}
