import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/constants/app_theme.dart';
import 'package:orbit_app/routing/route_names.dart';
import 'package:orbit_app/features/dashboard/data/models/dashboard_model.dart';
import 'package:orbit_app/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:orbit_app/features/dashboard/presentation/widgets/dashboard_app_bar.dart';
import 'package:orbit_app/features/dashboard/presentation/widgets/stats_card.dart';
import 'package:orbit_app/features/dashboard/presentation/widgets/quick_action_card.dart';
import 'package:orbit_app/features/dashboard/presentation/widgets/new_message_button.dart';

/// The main dashboard screen of the ORBIT SMS V3 application.
///
/// Displays:
/// 1. Custom app bar with avatar, notifications, and language toggle
/// 2. Welcome section with title and description
/// 3. Action buttons (New Message dropdown + Advanced Send)
/// 4. Promotional banner carousel with page indicators
/// 5. Horizontal-scroll stats cards (Balance, Services, Points)
/// 6. Quick-access grid (Groups, Sub Accounts)
///
/// Supports pull-to-refresh, shimmer loading states, and error with retry.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final PageController _carouselController;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _carouselController = PageController();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_carouselController.hasClients) return;
      final banners = ref.read(dashboardBannersProvider).valueOrNull ?? [];
      if (banners.isEmpty) return;

      final currentPage = ref.read(carouselIndexProvider);
      final nextPage = (currentPage + 1) % banners.length;

      _carouselController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(refreshDashboardProvider)();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: statsAsync.when(
        loading: () => _buildShimmerLoading(),
        error: (error, _) => _buildErrorState(error),
        data: (stats) => _buildContent(stats),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MAIN CONTENT
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildContent(DashboardStats stats) {
    return Column(
      children: [
        // ── App Bar ────────────────────────────────────────────────
        DashboardAppBar(
          userName: stats.userName,
          userAvatar: stats.userAvatar,
          notificationCount: stats.unreadNotifications,
        ),

        // ── Scrollable body ────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // Welcome section
                _buildWelcomeSection(),

                // Action buttons
                _buildActionButtons(),

                // Banner carousel
                _buildBannerCarousel(),

                // Stats cards
                _buildStatsRow(stats),

                // Balance summary section (matching new portal)
                _buildBalanceSummarySection(stats),

                // Recent messages section (matching new portal)
                if (stats.recentMessages.isNotEmpty)
                  _buildRecentMessagesSection(stats),

                // Account level section (matching new portal)
                if (stats.accountLevel.isNotEmpty)
                  _buildAccountLevelSection(stats),

                // Quick access section title
                _buildSectionTitle(
                  '\u0625\u062C\u0631\u0627\u0621\u0627\u062A \u0633\u0631\u064A\u0639\u0629', // إجراءات سريعة
                ),

                // Quick access cards
                _buildQuickAccessCards(stats),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Welcome Section ────────────────────────────────────────────────

  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingLg,
        AppTheme.spacingLg,
        AppTheme.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '\u0644\u0648\u062D\u0629 \u0627\u0644\u062A\u062D\u0643\u0645', // لوحة التحكم
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\u0645\u0631\u062D\u0628\u0627\u064B \u0628\u0643 \u0641\u064A \u0644\u0648\u062D\u0629 \u062A\u062D\u0643\u0645 \u0627\u0648\u0631\u0628\u062A SMS\u060C \u064A\u0645\u0643\u0646\u0643 \u0625\u062F\u0627\u0631\u0629 \u062D\u0633\u0627\u0628\u0643 \u0648\u0625\u0631\u0633\u0627\u0644 \u0631\u0633\u0627\u0626\u0644\u0643 \u0628\u0643\u0644 \u0633\u0647\u0648\u0644\u0629', // مرحباً بك في لوحة تحكم اوربت SMS، يمكنك إدارة حسابك وإرسال رسائلك بكل سهولة
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Action Buttons ─────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          // New Message dropdown button
          const NewMessageButton(),

          const SizedBox(width: AppTheme.spacingMd),

          // Advanced Send outlined button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.pushNamed(
                RouteNames.sendMessage,
                extra: {'message_type': 'advanced'},
              ),
              icon: const Icon(Icons.send_outlined, size: 16),
              label: const Text(
                '\u0625\u0631\u0633\u0627\u0644 \u0645\u062A\u0642\u062F\u0645', // إرسال متقدم
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Banner Carousel ────────────────────────────────────────────────

  Widget _buildBannerCarousel() {
    final bannersAsync = ref.watch(dashboardBannersProvider);

    return bannersAsync.when(
      loading: () => _buildCarouselShimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();
        return _buildCarouselContent(banners);
      },
    );
  }

  Widget _buildCarouselContent(List<BannerItem> banners) {
    final currentIndex = ref.watch(carouselIndexProvider);

    return Column(
      children: [
        const SizedBox(height: AppTheme.spacingSm),

        // Carousel
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: banners.length,
            onPageChanged: (index) {
              ref.read(carouselIndexProvider.notifier).state = index;
            },
            itemBuilder: (context, index) {
              final banner = banners[index];
              return _BannerCard(banner: banner);
            },
          ),
        ),

        const SizedBox(height: AppTheme.spacingSm),

        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (index) {
            final isActive = index == currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isActive ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),

        const SizedBox(height: AppTheme.spacingSm),
      ],
    );
  }

  Widget _buildCarouselShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingSm,
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      ),
    );
  }

  // ─── Stats Row ──────────────────────────────────────────────────────

  Widget _buildStatsRow(DashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          '\u0625\u062D\u0635\u0627\u0626\u064A\u0627\u062A \u0627\u0644\u062D\u0633\u0627\u0628', // إحصائيات الحساب
        ),

        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            children: [
              // Balance card
              StatsCard(
                type: StatsCardType.balance,
                title: '\u0627\u0644\u0631\u0635\u064A\u062F \u0627\u0644\u062D\u0627\u0644\u064A', // الرصيد الحالي
                value: stats.currentBalance,
                unit: '\u0631\u0633\u0627\u0644\u0629', // رسالة
                onTap: () => context.pushNamed(RouteNames.transactions),
                onViewAll: () => context.pushNamed(RouteNames.transactions),
                viewAllLabel: '\u0639\u0631\u0636 \u062C\u0645\u064A\u0639 \u0627\u0644\u0639\u0645\u0644\u064A\u0627\u062A', // عرض جميع العمليات
              ),
              const SizedBox(width: AppTheme.spacingMd),

              // Services card
              StatsCard(
                type: StatsCardType.services,
                title: '\u0627\u0644\u062E\u062F\u0645\u0627\u062A', // الخدمات
                value: stats.servicesCount,
                onTap: () => context.pushNamed(RouteNames.services),
                onViewAll: () => context.pushNamed(RouteNames.services),
                viewAllLabel: '\u0639\u0631\u0636 \u062C\u0645\u064A\u0639 \u0627\u0644\u062E\u062F\u0645\u0627\u062A', // عرض جميع الخدمات
              ),
              const SizedBox(width: AppTheme.spacingMd),

              // Consumed points card
              StatsCard(
                type: StatsCardType.consumedPoints,
                title: '\u0627\u0644\u0631\u0635\u064A\u062F \u0627\u0644\u0645\u0633\u062A\u0647\u0644\u0643', // الرصيد المستهلك
                value: stats.consumedPoints,
                unit: '\u0631\u0633\u0627\u0644\u0629', // رسالة
              ),
              const SizedBox(width: AppTheme.spacingLg),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Quick Access Cards ─────────────────────────────────────────────

  Widget _buildQuickAccessCards(DashboardStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        children: [
          // Groups card
          QuickActionCard(
            icon: Icons.people_rounded,
            title: '\u0627\u0644\u0645\u062C\u0645\u0648\u0639\u0627\u062A', // المجموعات
            count: stats.groupsCount,
            subtitle:
                '${stats.groupsCount} \u0645\u062C\u0645\u0648\u0639\u0629', // مجموعة
            iconColor: AppColors.success,
            onTap: () => context.pushNamed(RouteNames.groups),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Sub Accounts card
          QuickActionCard(
            icon: Icons.manage_accounts_rounded,
            title: '\u0627\u0644\u062D\u0633\u0627\u0628\u0627\u062A \u0627\u0644\u0641\u0631\u0639\u064A\u0629', // الحسابات الفرعية
            count: stats.subAccountsCount,
            subtitle:
                '${stats.subAccountsCount} \u062D\u0633\u0627\u0628', // حساب
            iconColor: AppColors.info,
            onTap: () => context.pushNamed(RouteNames.subAccounts),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Add Balance card
          QuickActionCard(
            icon: Icons.account_balance_wallet_rounded,
            title: '\u0625\u0636\u0627\u0641\u0629 \u0631\u0635\u064A\u062F', // إضافة رصيد
            subtitle: '\u0634\u0631\u0627\u0621 \u0631\u0635\u064A\u062F \u062C\u062F\u064A\u062F', // شراء رصيد جديد
            iconColor: AppColors.warning,
            onTap: () => context.pushNamed(RouteNames.buyBalance),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Statistics card
          QuickActionCard(
            icon: Icons.bar_chart_rounded,
            title: '\u0627\u0644\u0625\u062D\u0635\u0627\u0626\u064A\u0627\u062A', // الإحصائيات
            subtitle: '\u062A\u0642\u0627\u0631\u064A\u0631 \u0627\u0644\u0625\u0631\u0633\u0627\u0644', // تقارير الإرسال
            iconColor: AppColors.balancePurpleStart,
            onTap: () => context.pushNamed(RouteNames.statistics),
          ),
        ],
      ),
    );
  }

  // ─── Balance Summary Section ────────────────────────────────────────

  Widget _buildBalanceSummarySection(DashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('\u0627\u0644\u0631\u0635\u064A\u062F'), // الرصيد

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                // 4 balance metric cards in a 2x2 grid
                Row(
                  children: [
                    Expanded(
                      child: _BalanceMetricCard(
                        label: '\u0627\u0644\u0625\u062C\u0645\u0627\u0644\u064A', // الإجمالي
                        value: stats.totalBalance,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BalanceMetricCard(
                        label: '\u0627\u0644\u0645\u062A\u0628\u0642\u064A', // المتبقي
                        value: stats.remainingBalance,
                        color: const Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _BalanceMetricCard(
                        label: '\u0627\u0644\u0645\u0633\u062A\u0647\u0644\u0643', // المستهلك
                        value: stats.consumedBalance,
                        color: const Color(0xFFFF9800),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BalanceMetricCard(
                        label: '\u062A\u0645 \u062A\u062D\u0648\u064A\u0644\u0647', // تم تحويله
                        value: stats.transferredBalance,
                        color: const Color(0xFFF44336),
                      ),
                    ),
                  ],
                ),

                // Countdown timer
                if (stats.balanceExpiryDate != null) ...[
                  const SizedBox(height: 16),
                  _BalanceCountdownTimer(expiryDate: stats.balanceExpiryDate!),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Recent Messages Section ──────────────────────────────────────

  Widget _buildRecentMessagesSection(DashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingLg,
            AppTheme.spacingLg,
            AppTheme.spacingLg,
            AppTheme.spacingMd,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '\u0623\u062D\u062F\u062B \u0627\u0644\u0631\u0633\u0627\u0626\u0644', // أحدث الرسائل
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
              GestureDetector(
                onTap: () => context.pushNamed(RouteNames.balance),
                child: const Text(
                  '\u0639\u0631\u0636 \u0627\u0644\u0643\u0644', // عرض الكل
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                for (int i = 0; i < stats.recentMessages.length; i++) ...[
                  _RecentMessageRow(message: stats.recentMessages[i]),
                  if (i < stats.recentMessages.length - 1)
                    Divider(height: 1, color: AppColors.border.withOpacity(0.3)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Account Level Section ────────────────────────────────────────

  Widget _buildAccountLevelSection(DashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('\u0645\u0633\u062A\u0648\u0627\u0643 \u0627\u0644\u062D\u0627\u0644\u064A'), // مستواك الحالي

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppColors.primary.withOpacity(0.08),
                  AppColors.primary.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                // Level icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),

                // Level name
                Text(
                  stats.accountLevel,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 16),

                // Progress bar
                if (stats.accountLevelProgress > 0 || stats.nextLevelName.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: stats.accountLevelProgress.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(stats.accountLevelProgress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],

                // Next level info
                if (stats.nextLevelName.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      '\u0644\u0644\u062A\u0631\u0642\u064A\u0629 \u0625\u0644\u0649 "${stats.nextLevelName}"\u060C \u064A\u062C\u0628 \u0634\u062D\u0646 \u0631\u0635\u064A\u062F \u0628\u0642\u064A\u0645\u0629 ${NumberFormat('#,###').format(stats.nextLevelRequirement)} \u0631\u064A\u0627\u0644',
                      // للترقية إلى "البرونزي"، يجب شحن رصيد بقيمة 3,500 ريال
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Section Title ──────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingLg,
        AppTheme.spacingLg,
        AppTheme.spacingMd,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHIMMER LOADING STATE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildShimmerLoading() {
    return Column(
      children: [
        // Shimmer app bar
        _buildAppBarShimmer(),

        Expanded(
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            children: [
              // Title shimmer
              _shimmerBox(width: 140, height: 24),
              const SizedBox(height: 8),
              _shimmerBox(width: double.infinity, height: 14),
              const SizedBox(height: 4),
              _shimmerBox(width: 220, height: 14),
              const SizedBox(height: 20),

              // Action buttons shimmer
              Row(
                children: [
                  _shimmerBox(width: 140, height: 40, radius: 8),
                  const SizedBox(width: 12),
                  Expanded(child: _shimmerBox(width: double.infinity, height: 40, radius: 8)),
                ],
              ),
              const SizedBox(height: 20),

              // Banner shimmer
              _shimmerBox(width: double.infinity, height: 160, radius: 12),
              const SizedBox(height: 20),

              // Stats shimmer
              _shimmerBox(width: 120, height: 18),
              const SizedBox(height: 12),
              SizedBox(
                height: 190,
                child: Row(
                  children: [
                    Expanded(child: _shimmerBox(width: 170, height: 190, radius: 16)),
                    const SizedBox(width: 12),
                    Expanded(child: _shimmerBox(width: 170, height: 190, radius: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick access shimmer
              _shimmerBox(width: 100, height: 18),
              const SizedBox(height: 12),
              _shimmerBox(width: double.infinity, height: 74, radius: 12),
              const SizedBox(height: 12),
              _shimmerBox(width: double.infinity, height: 74, radius: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBarShimmer() {
    return Container(
      color: AppColors.surface,
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
                _shimmerBox(width: 40, height: 40, radius: 20),
                const SizedBox(width: 12),
                _shimmerBox(width: 100, height: 18),
                const Spacer(),
                _shimmerBox(width: 56, height: 30, radius: 15),
                const SizedBox(width: 8),
                _shimmerBox(width: 40, height: 40, radius: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    double radius = 6,
  }) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ERROR STATE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            const Text(
              '\u062D\u062F\u062B \u062E\u0637\u0623 \u0641\u064A \u062A\u062D\u0645\u064A\u0644 \u0627\u0644\u0628\u064A\u0627\u0646\u0627\u062A', // حدث خطأ في تحميل البيانات
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            SizedBox(
              width: 180,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(dashboardStatsProvider);
                  ref.invalidate(dashboardBannersProvider);
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text(
                  '\u0625\u0639\u0627\u062F\u0629 \u0627\u0644\u0645\u062D\u0627\u0648\u0644\u0629', // إعادة المحاولة
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BANNER CARD (used inside carousel)
// ═══════════════════════════════════════════════════════════════════════════

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});

  final BannerItem banner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFDF6235),
              Color(0xFFC54E20),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image (if available)
              if (banner.imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: banner.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox.shrink(),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),

              // Decorative pattern overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: _BannerPatternPainter(),
                ),
              ),

              // Text overlay
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (banner.title.isNotEmpty)
                      Text(
                        banner.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (banner.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        banner.description,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.9),
                          fontFamily: 'Cairo',
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
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
// Banner Pattern Painter (decorative circles)
// ─────────────────────────────────────────────────────────────────────────────

class _BannerPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    // Large circle bottom-right
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.8),
      size.height * 0.5,
      paint,
    );

    // Small circle top-right
    canvas.drawCircle(
      Offset(size.width * 0.75, -size.height * 0.1),
      size.height * 0.35,
      Paint()..color = Colors.white.withOpacity(0.04),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// BALANCE METRIC CARD
// ═══════════════════════════════════════════════════════════════════════════

class _BalanceMetricCard extends StatelessWidget {
  const _BalanceMetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mail_outline_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${NumberFormat('#,###').format(value)} \u0631\u0633\u0627\u0644\u0629', // رسالة
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BALANCE COUNTDOWN TIMER
// ═══════════════════════════════════════════════════════════════════════════

class _BalanceCountdownTimer extends StatefulWidget {
  const _BalanceCountdownTimer({required this.expiryDate});

  final DateTime expiryDate;

  @override
  State<_BalanceCountdownTimer> createState() => _BalanceCountdownTimerState();
}

class _BalanceCountdownTimerState extends State<_BalanceCountdownTimer> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    setState(() {
      _remaining = widget.expiryDate.isAfter(now)
          ? widget.expiryDate.difference(now)
          : Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          const Text(
            '\u0633\u064A\u0646\u062A\u0647\u064A \u0627\u0644\u0631\u0635\u064A\u062F \u062E\u0644\u0627\u0644', // سينتهي الرصيد خلال
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CountdownUnit(value: days, label: '\u0623\u064A\u0627\u0645'), // أيام
              _countdownSeparator(),
              _CountdownUnit(value: hours, label: '\u0633\u0627\u0639\u0627\u062A'), // ساعات
              _countdownSeparator(),
              _CountdownUnit(value: minutes, label: '\u062F\u0642\u0627\u0626\u0642'), // دقائق
              _countdownSeparator(),
              _CountdownUnit(value: seconds, label: '\u062B\u0648\u0627\u0646\u064A'), // ثواني
            ],
          ),
        ],
      ),
    );
  }

  Widget _countdownSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  const _CountdownUnit({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RECENT MESSAGE ROW
// ═══════════════════════════════════════════════════════════════════════════

class _RecentMessageRow extends StatelessWidget {
  const _RecentMessageRow({required this.message});

  final RecentMessage message;

  @override
  Widget build(BuildContext context) {
    // Display description: prefer note, then senderName (which maps to bank for transactions).
    final description = message.note.isNotEmpty
        ? message.note
        : message.senderName.isNotEmpty
            ? message.senderName
            : '\u063A\u064A\u0631 \u0645\u0639\u0631\u0648\u0641'; // غير معروف

    // Display amount if present.
    final hasAmount = message.amount.isNotEmpty && message.amount != '0';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Status badge
          _StatusBadge(status: message.status),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (hasAmount) ...[
                      Text(
                        '${message.amount} \u0631\u0633\u0627\u0644\u0629', // رسالة
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: double.tryParse(message.amount) != null &&
                                  double.parse(message.amount) < 0
                              ? const Color(0xFFC62828)
                              : const Color(0xFF2E7D32),
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (message.messageType.isNotEmpty)
                      Text(
                        message.messageType,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Time
          if (message.sentAt != null)
            Text(
              DateFormat('yyyy/M/d').format(message.sentAt!),
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label = status;

    switch (status.toLowerCase()) {
      case 'accepted':
      case 'sent':
      case 'delivered':
      case 'approved':
      case 'مقبولة':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        label = '\u0645\u0642\u0628\u0648\u0644\u0629'; // مقبولة
        break;
      case 'rejected':
      case 'failed':
      case 'مرفوضة':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        label = '\u0645\u0631\u0641\u0648\u0636\u0629'; // مرفوضة
        break;
      case 'pending':
      case 'waiting':
      case 'under_review':
      case 'تحت المراجعة':
      case 'قيد الانتظار':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        label = '\u0642\u064A\u062F \u0627\u0644\u0627\u0646\u062A\u0638\u0627\u0631'; // قيد الانتظار
        break;
      case 'expired':
      case 'منتهي':
        bgColor = const Color(0xFFF3E5F5);
        textColor = const Color(0xFF6A1B9A);
        label = '\u0645\u0646\u062A\u0647\u064A'; // منتهي
        break;
      default:
        bgColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF616161);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}
