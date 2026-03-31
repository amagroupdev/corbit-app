import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/constants/app_theme.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
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

                // Balance countdown timer (at top, per user request)
                _buildBalanceSummarySection(stats),

                // Banner carousel
                _buildBannerCarousel(),

                // Stats cards
                _buildStatsRow(stats),

                // Recent messages section (matching new portal)
                if (stats.recentMessages.isNotEmpty)
                  _buildRecentMessagesSection(stats),

                // Account level section (matching new portal)
                if (stats.accountLevel.isNotEmpty)
                  _buildAccountLevelSection(stats),

                // Quick access section title
                _buildSectionTitle(
                  AppLocalizations.of(context)?.translate('quickActions') ?? 'Quick Actions',
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
    final t = AppLocalizations.of(context);
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
          Text(
            t?.translate('dashboard') ?? 'Dashboard',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t?.translate('dashboardWelcomeDesc') ?? '',
            style: const TextStyle(
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
              label: Text(
                AppLocalizations.of(context)?.translate('advancedSend') ?? 'Advanced Send',
                style: const TextStyle(
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
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          t?.translate('accountStats') ?? 'Account Statistics',
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
                title: t?.translate('currentBalance') ?? 'Current Balance',
                value: stats.currentBalance,
                unit: t?.translate('messagesUnit') ?? 'messages',
                onTap: () => context.pushNamed(RouteNames.transactions),
                onViewAll: () => context.pushNamed(RouteNames.transactions),
                viewAllLabel: t?.translate('viewAllOperations') ?? 'View All Operations',
              ),
              const SizedBox(width: AppTheme.spacingMd),

              // Services card
              StatsCard(
                type: StatsCardType.services,
                title: t?.translate('services') ?? 'Services',
                value: stats.servicesCount,
                onTap: () => context.pushNamed(RouteNames.services),
                onViewAll: () => context.pushNamed(RouteNames.services),
                viewAllLabel: t?.translate('viewAllServices') ?? 'View All Services',
              ),
              const SizedBox(width: AppTheme.spacingMd),

              // Consumed points card
              StatsCard(
                type: StatsCardType.consumedPoints,
                title: t?.translate('consumedPoints') ?? 'Consumed Points',
                value: stats.consumedPoints,
                unit: t?.translate('messagesUnit') ?? 'messages',
              ),
              const SizedBox(width: AppTheme.spacingMd),

              // Groups card
              StatsCard(
                type: StatsCardType.services,
                title: t?.translate('groups') ?? 'Groups',
                value: stats.groupsCount,
                onTap: () => context.pushNamed(RouteNames.groups),
                onViewAll: () => context.pushNamed(RouteNames.groups),
                viewAllLabel: t?.translate('manageGroups') ?? 'Manage Groups',
              ),
              const SizedBox(width: AppTheme.spacingMd),

              // Sub accounts card
              StatsCard(
                type: StatsCardType.consumedPoints,
                title: t?.translate('subAccounts') ?? 'Sub Accounts',
                value: stats.subAccountsCount,
                onTap: () => context.pushNamed(RouteNames.subAccounts),
                onViewAll: () => context.pushNamed(RouteNames.subAccounts),
                viewAllLabel: t?.translate('manageAccounts') ?? 'Manage Accounts',
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
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        children: [
          // Groups card
          QuickActionCard(
            icon: Icons.people_rounded,
            title: t?.translate('groups') ?? 'Groups',
            count: stats.groupsCount,
            subtitle:
                '${stats.groupsCount} ${t?.translate('groupUnit') ?? 'group'}',
            iconColor: AppColors.success,
            onTap: () => context.pushNamed(RouteNames.groups),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Sub Accounts card
          QuickActionCard(
            icon: Icons.manage_accounts_rounded,
            title: t?.translate('subAccounts') ?? 'Sub Accounts',
            count: stats.subAccountsCount,
            subtitle:
                '${stats.subAccountsCount} ${t?.translate('accountUnit') ?? 'account'}',
            iconColor: AppColors.info,
            onTap: () => context.pushNamed(RouteNames.subAccounts),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Add Balance card
          QuickActionCard(
            icon: Icons.account_balance_wallet_rounded,
            title: t?.translate('addBalance') ?? 'Add Balance',
            subtitle: t?.translate('buyNewBalance') ?? 'Buy New Balance',
            iconColor: AppColors.warning,
            onTap: () => context.pushNamed(RouteNames.buyBalance),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Statistics card
          QuickActionCard(
            icon: Icons.bar_chart_rounded,
            title: t?.translate('statistics') ?? 'Statistics',
            subtitle: t?.translate('sendingReports') ?? 'Sending Reports',
            iconColor: AppColors.balancePurpleStart,
            onTap: () => context.pushNamed(RouteNames.statistics),
          ),
        ],
      ),
    );
  }

  // ─── Balance Summary Section ────────────────────────────────────────

  Widget _buildBalanceSummarySection(DashboardStats stats) {
    // Only show countdown timer (balance cards removed per user request)
    if (stats.balanceExpiryDate == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(AppLocalizations.of(context)?.translate('balance') ?? 'Balance'),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: _BalanceCountdownTimer(expiryDate: stats.balanceExpiryDate!),
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
              Text(
                AppLocalizations.of(context)?.translate('recentMessages') ?? 'Recent Messages',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
              GestureDetector(
                onTap: () => context.pushNamed(RouteNames.archive),
                child: Text(
                  AppLocalizations.of(context)?.translate('seeAll') ?? 'See All',
                  style: const TextStyle(
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
        _buildSectionTitle(AppLocalizations.of(context)?.translate('currentLevel') ?? 'Your Current Level'),

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
                  AppLocalizations.of(context)?.translate(stats.accountLevel) ?? stats.accountLevel,
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
                    child: Builder(builder: (ctx) {
                      final t = AppLocalizations.of(ctx);
                      final translatedNextLevel = t?.translate(stats.nextLevelName) ?? stats.nextLevelName;
                      final formattedAmount = NumberFormat('#,###').format(stats.nextLevelRequirement);
                      return Text(
                      t?.translateWithParams('upgradeToLevel', {
                        'level': translatedNextLevel,
                        'amount': formattedAmount,
                      }) ?? 'To upgrade to "$translatedNextLevel", you need to recharge $formattedAmount SAR',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                        height: 1.5,
                      ),
                    );
                    }),
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
            Text(
              AppLocalizations.of(context)?.translate('loadingDataError') ?? 'Error loading data',
              style: const TextStyle(
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
                label: Text(
                  AppLocalizations.of(context)?.translate('retry') ?? 'Retry',
                  style: const TextStyle(
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

class _BannerCard extends StatefulWidget {
  const _BannerCard({required this.banner});

  final BannerItem banner;

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard> {
  bool _imageLoadFailed = false;

  bool get _showFallback => widget.banner.imageUrl.isEmpty || _imageLoadFailed;

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
              // Background image (if available and not failed)
              if (widget.banner.imageUrl.isNotEmpty && !_imageLoadFailed)
                CachedNetworkImage(
                  imageUrl: widget.banner.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) {
                    // Mark image as failed so fallback shows
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _imageLoadFailed = true);
                    });
                    return const SizedBox.shrink();
                  },
                ),

              // Show fallback design when no image or image failed
              if (_showFallback) ...[
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
                      if (widget.banner.title.isNotEmpty)
                        Text(
                          AppLocalizations.of(context)?.translate(widget.banner.title) ?? widget.banner.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (widget.banner.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          AppLocalizations.of(context)?.translate(widget.banner.description) ?? widget.banner.description,
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
            '${NumberFormat('#,###').format(value)} ${AppLocalizations.of(context)?.translate('messagesUnit') ?? 'messages'}',
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
          Text(
            AppLocalizations.of(context)?.translate('balanceExpiresIn') ?? 'Balance expires in',
            style: const TextStyle(
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
              _CountdownUnit(value: days, label: AppLocalizations.of(context)?.translate('days') ?? 'days'),
              _countdownSeparator(),
              _CountdownUnit(value: hours, label: AppLocalizations.of(context)?.translate('hours') ?? 'hours'),
              _countdownSeparator(),
              _CountdownUnit(value: minutes, label: AppLocalizations.of(context)?.translate('minutes') ?? 'minutes'),
              _countdownSeparator(),
              _CountdownUnit(value: seconds, label: AppLocalizations.of(context)?.translate('seconds') ?? 'seconds'),
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

  String _translateMessageType(BuildContext context, String type) {
    final t = AppLocalizations.of(context);
    final key = 'archive_type_$type';
    final translated = t?.translate(key);
    // If translation key doesn't exist, it returns the key itself
    if (translated != null && translated != key) return translated;
    // Fallback: make it human-readable
    return type.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    // Title: sender name first, fallback to message type
    final title = message.senderName.isNotEmpty
        ? message.senderName
        : _translateMessageType(context, message.messageType);

    // Subtitle: message body
    final subtitle = message.note.isNotEmpty
        ? message.note
        : null;

    // Translated type label
    final typeLabel = message.messageType.isNotEmpty
        ? _translateMessageType(context, message.messageType)
        : null;

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
                // Sender name
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Message body preview
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'Cairo',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 2),
                // Type + recipient count
                Row(
                  children: [
                    if (typeLabel != null && message.senderName.isNotEmpty)
                      Text(
                        typeLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    if (typeLabel != null &&
                        message.senderName.isNotEmpty &&
                        message.recipientCount > 0)
                      const Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    if (message.recipientCount > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 12,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${message.recipientCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
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
              style: const TextStyle(
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
    final t = AppLocalizations.of(context);
    Color bgColor;
    Color textColor;
    String label = status;

    switch (status.toLowerCase()) {
      case 'sent':
      case 'مرسلة':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
        label = t?.translate('statusSent_') ?? 'Sent';
        break;
      case 'delivered':
      case 'تم التسليم':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        label = t?.translate('statusDelivered_') ?? 'Delivered';
        break;
      case 'accepted':
      case 'approved':
      case 'queued':
      case 'مقبولة':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        label = t?.translate('statusSent_') ?? 'Sent';
        break;
      case 'rejected':
      case 'مرفوضة':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        label = t?.translate('statusRejected_') ?? 'Rejected';
        break;
      case 'failed':
      case 'فشلت':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        label = t?.translate('statusFailed_') ?? 'Failed';
        break;
      case 'pending':
      case 'waiting':
      case 'under_review':
      case 'قيد الانتظار':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        label = t?.translate('statusPending__') ?? 'Pending';
        break;
      case 'scheduled':
      case 'مجدولة':
        bgColor = const Color(0xFFE8EAF6);
        textColor = const Color(0xFF283593);
        label = t?.translate('statusScheduled_') ?? 'Scheduled';
        break;
      case 'cancelled':
      case 'ملغاة':
        bgColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF616161);
        label = t?.translate('statusCancelled_') ?? 'Cancelled';
        break;
      case 'expired':
      case 'منتهية':
        bgColor = const Color(0xFFF3E5F5);
        textColor = const Color(0xFF6A1B9A);
        label = t?.translate('statusExpired__') ?? 'Expired';
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
