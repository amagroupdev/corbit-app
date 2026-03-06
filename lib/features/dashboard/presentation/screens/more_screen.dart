import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/constants/app_strings.dart';
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

  static final List<_MoreMenuGroup> _groups = [
    // ── Section 1: الرسائل (Messages) ─────────────────────────
    _MoreMenuGroup(
      label: '\u0627\u0644\u0631\u0633\u0627\u0626\u0644', // الرسائل
      items: [
        _MoreMenuItem(
          icon: Icons.mail_outlined,
          title: '\u0645\u0631\u0643\u0632 \u0627\u0644\u0631\u0633\u0627\u0626\u0644', // مركز الرسائل
          route: '/messages',
          iconColor: AppColors.primary,
        ),
        _MoreMenuItem(
          icon: Icons.archive_outlined,
          title: '\u0627\u0644\u0631\u0633\u0627\u0626\u0644 \u0627\u0644\u0645\u0624\u0631\u0634\u0641\u0629', // الرسائل المؤرشفة
          route: '/archive',
          iconColor: AppColors.info,
        ),
        _MoreMenuItem(
          icon: Icons.verified_outlined,
          title: '\u0634\u0647\u0627\u062F\u0627\u062A \u0627\u0644\u0637\u0644\u0627\u0628', // شهادات الطلاب
          route: '/certifications',
          iconColor: AppColors.success,
        ),
        _MoreMenuItem(
          icon: Icons.event_busy_outlined,
          title: '\u0631\u0633\u0627\u0626\u0644 \u0627\u0644\u063A\u064A\u0627\u0628 \u0648\u0627\u0644\u062A\u0623\u062E\u0631', // رسائل الغياب والتأخر
          route: '/absence-messages',
          iconColor: AppColors.warning,
        ),
        _MoreMenuItem(
          icon: Icons.quiz_outlined,
          title: '\u0627\u0644\u0627\u0633\u062A\u0628\u064A\u0627\u0646\u0627\u062A', // الاستبيانات
          route: '/questionnaires',
          iconColor: AppColors.chartIndigo,
        ),
        _MoreMenuItem(
          icon: Icons.question_answer_outlined,
          title: '\u0627\u0644\u0625\u0641\u0627\u062F\u0627\u062A \u0648\u0627\u0644\u0631\u062F\u0648\u062F', // الإفادات والردود
          route: '/statements',
          iconColor: AppColors.chartTeal,
        ),
      ],
    ),

    // ── Section 2: أدوات الرسائل (Message Tools) ──────────────
    _MoreMenuGroup(
      label: '\u0623\u062F\u0648\u0627\u062A \u0627\u0644\u0631\u0633\u0627\u0626\u0644', // أدوات الرسائل
      items: [
        _MoreMenuItem(
          icon: Icons.description_outlined,
          title: '\u0627\u0644\u0642\u0648\u0627\u0644\u0628', // القوالب
          route: '/templates',
          iconColor: AppColors.chartPurple,
        ),
        _MoreMenuItem(
          icon: Icons.person_outlined,
          title: '\u0623\u0633\u0645\u0627\u0621 \u0627\u0644\u0645\u0631\u0633\u0644\u064A\u0646', // أسماء المرسلين
          route: '/sender-names',
          iconColor: AppColors.chartBlue,
        ),
        _MoreMenuItem(
          icon: Icons.link_rounded,
          title: '\u0627\u062E\u062A\u0635\u0627\u0631 \u0627\u0644\u0631\u0648\u0627\u0628\u0637', // اختصار الروابط
          route: '/short-links',
          iconColor: AppColors.chartTeal,
        ),
      ],
    ),

    // ── Section 3: الخدمات والإحصائيات ─────────────────────────
    _MoreMenuGroup(
      label: '\u0627\u0644\u062E\u062F\u0645\u0627\u062A \u0648\u0627\u0644\u0625\u062D\u0635\u0627\u0626\u064A\u0627\u062A', // الخدمات والإحصائيات
      items: [
        _MoreMenuItem(
          icon: Icons.extension_outlined,
          title: '\u0627\u0644\u062E\u062F\u0645\u0627\u062A', // الخدمات
          route: '/services',
          iconColor: AppColors.chartOrange,
        ),
        _MoreMenuItem(
          icon: Icons.bar_chart_rounded,
          title: '\u0627\u0644\u0625\u062D\u0635\u0627\u0626\u064A\u0627\u062A', // الإحصائيات
          route: '/statistics',
          iconColor: AppColors.chartGreen,
        ),
      ],
    ),

    // ── Section 4: الحساب (Account) ───────────────────────────
    _MoreMenuGroup(
      label: '\u0627\u0644\u062D\u0633\u0627\u0628', // الحساب
      items: [
        _MoreMenuItem(
          icon: Icons.settings_outlined,
          title: '\u0627\u0644\u0625\u0639\u062F\u0627\u062F\u0627\u062A', // الإعدادات
          route: '/settings',
          iconColor: AppColors.textSecondary,
        ),
        _MoreMenuItem(
          icon: Icons.notifications_outlined,
          title: '\u0627\u0644\u0625\u0634\u0639\u0627\u0631\u0627\u062A', // الإشعارات
          route: '/notifications',
          iconColor: AppColors.warning,
        ),
      ],
    ),

    // ── Section 5: المساعدة (Help) ────────────────────────────
    _MoreMenuGroup(
      label: '\u0627\u0644\u0645\u0633\u0627\u0639\u062F\u0629', // المساعدة
      items: [
        _MoreMenuItem(
          icon: Icons.menu_book_outlined,
          title: '\u062F\u0644\u064A\u0644 \u0627\u0644\u0645\u0633\u062A\u062E\u062F\u0645', // دليل المستخدم
          externalUrl: 'https://orbit-sms.com/user-guide',
          iconColor: AppColors.chartBlue,
        ),
        _MoreMenuItem(
          icon: Icons.bug_report_outlined,
          title: '\u0627\u0644\u0625\u0628\u0644\u0627\u063A \u0639\u0646 \u0645\u0634\u0643\u0644\u0629', // الإبلاغ عن مشكلة
          route: '/contact-me',
          iconColor: AppColors.chartOrange,
        ),
        _MoreMenuItem(
          icon: Icons.help_outline_rounded,
          title: '\u0627\u0644\u0645\u0633\u0627\u0639\u062F\u0629 \u0648\u0627\u0644\u062F\u0639\u0645', // المساعدة والدعم
          externalUrl: 'https://orbit-sms.com/help',
          iconColor: AppColors.chartGreen,
        ),
      ],
    ),

    // ── Section 6: القانونية (Legal) ──────────────────────
    _MoreMenuGroup(
      label: '\u0627\u0644\u0642\u0627\u0646\u0648\u0646\u064A\u0629', // القانونية
      items: [
        _MoreMenuItem(
          icon: Icons.gavel_outlined,
          title: '\u0627\u0644\u0634\u0631\u0648\u0637 \u0648\u0627\u0644\u0623\u062D\u0643\u0627\u0645', // الشروط والأحكام
          externalUrl: AppStrings.urlTermsOfService,
          iconColor: AppColors.chartIndigo,
        ),
        _MoreMenuItem(
          icon: Icons.privacy_tip_outlined,
          title: '\u0633\u064A\u0627\u0633\u0629 \u0627\u0644\u062E\u0635\u0648\u0635\u064A\u0629', // سياسة الخصوصية
          externalUrl: AppStrings.urlPrivacyPolicy,
          iconColor: AppColors.chartPurple,
        ),
        _MoreMenuItem(
          icon: Icons.security_outlined,
          title: '\u0636\u0648\u0627\u0628\u0637 \u0627\u0644\u0647\u064A\u0626\u0629', // ضوابط الهيئة
          externalUrl: AppStrings.urlSpamRegulation,
          iconColor: AppColors.chartRed,
        ),
        _MoreMenuItem(
          icon: Icons.description_outlined,
          title: '\u0634\u0631\u0648\u0637 \u0627\u0644\u0627\u0633\u062A\u062E\u062F\u0627\u0645 - Corbit', // شروط الاستخدام - Corbit
          route: '/terms-pdf',
          iconColor: AppColors.chartTeal,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          '\u0627\u0644\u0645\u0632\u064A\u062F', // المزيد
          style: TextStyle(
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
          for (final group in _groups) ...[
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
              color: Colors.white.withValues(alpha: 0.2),
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
                      (item.iconColor ?? AppColors.primary).withValues(alpha: 0.1),
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
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _handleLogout(context, ref),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: Text(
          '\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062E\u0631\u0648\u062C', // تسجيل الخروج
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
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title:
          '\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062E\u0631\u0648\u062C', // تسجيل الخروج
      message:
          '\u0647\u0644 \u0623\u0646\u062A \u0645\u062A\u0623\u0643\u062F \u0645\u0646 \u0631\u063A\u0628\u062A\u0643 \u0641\u064A \u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062E\u0631\u0648\u062C\u061F', // هل أنت متأكد من رغبتك في تسجيل الخروج؟
      confirmText:
          '\u062E\u0631\u0648\u062C', // خروج
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
