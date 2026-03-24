import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/balance/data/models/balance_model.dart';
import 'package:orbit_app/features/balance/presentation/controllers/balance_controller.dart';
import 'package:orbit_app/features/balance/presentation/widgets/balance_log_tab.dart';
import 'package:orbit_app/features/balance/presentation/widgets/bank_info_tab.dart';
import 'package:orbit_app/features/balance/presentation/widgets/packages_tab.dart';
import 'package:orbit_app/features/balance/presentation/widgets/transfer_balance_tab.dart';
import 'package:orbit_app/features/balance/presentation/widgets/upgrade_journey_tab.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/routing/route_names.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';

/// Main balance overview screen with a tabbed layout.
///
/// Structure (matching the web portal):
/// - Top section: Title, action buttons, 4 balance summary cards, expiry countdown
/// - 5 tabs below the summary:
///   1. سجل الرصيد (Balance Log)
///   2. الباقات (Packages)
///   3. معلومات البنك (Bank Info)
///   4. تحويل الرصيد (Transfer Balance)
///   5. رحلة الترقية (Upgrade Journey)
class BalanceScreen extends ConsumerStatefulWidget {
  const BalanceScreen({super.key});

  @override
  ConsumerState<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends ConsumerState<BalanceScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  Timer? _countdownTimer;

  // Countdown state
  int _countdownDays = 0;
  int _countdownHours = 0;
  int _countdownMinutes = 0;
  int _countdownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(balanceScreenControllerProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(DateTime? expiredAt) {
    _countdownTimer?.cancel();

    if (expiredAt == null) return;

    _updateCountdown(expiredAt);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown(expiredAt);
    });
  }

  void _updateCountdown(DateTime expiredAt) {
    final now = DateTime.now();
    final diff = expiredAt.difference(now);

    if (diff.isNegative) {
      _countdownTimer?.cancel();
      setState(() {
        _countdownDays = 0;
        _countdownHours = 0;
        _countdownMinutes = 0;
        _countdownSeconds = 0;
      });
      return;
    }

    setState(() {
      _countdownDays = diff.inDays;
      _countdownHours = diff.inHours.remainder(24);
      _countdownMinutes = diff.inMinutes.remainder(60);
      _countdownSeconds = diff.inSeconds.remainder(60);
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(balanceScreenControllerProvider.notifier).loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(balanceScreenControllerProvider);
    final balance = state.balance ?? const BalanceModel();

    // Start countdown when balance data is available
    if (state.balance?.expiredAt != null && _countdownTimer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startCountdown(state.balance!.expiredAt);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('balance'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : state.error != null && state.balance == null
              ? _buildErrorState(state.error!)
              : NestedScrollView(
                  headerSliverBuilder:
                      (BuildContext context, bool innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: _buildTopSection(balance),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverTabBarDelegate(
                          tabBar: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: AppColors.textSecondary,
                            labelStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            indicatorColor: AppColors.primary,
                            indicatorWeight: 3,
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: AppColors.borderLight,
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            tabs: [
                              Tab(text: AppLocalizations.of(context)!.translate('balanceLog')),
                              Tab(text: AppLocalizations.of(context)!.translate('packages')),
                              Tab(text: AppLocalizations.of(context)!.translate('bankInfo')),
                              Tab(text: AppLocalizations.of(context)!.translate('transferBalance')),
                              Tab(text: AppLocalizations.of(context)!.translate('upgradeJourney')),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: const [
                      BalanceLogTab(),
                      PackagesTab(),
                      BankInfoTab(),
                      TransferBalanceTab(),
                      UpgradeJourneyTab(),
                    ],
                  ),
                ),
    );
  }

  /// Builds the always-visible top section with action buttons,
  /// balance summary cards, and expiry countdown.
  Widget _buildTopSection(BalanceModel balance) {
    final t = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat('#,##0', 'ar');

    return Container(
      color: AppColors.scaffoldBackground,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action buttons row
          Row(
            children: [
              Expanded(
                child: AppButton.primary(
                  text: t.translate('addBalance'),
                  onPressed: () =>
                      context.pushNamed(RouteNames.buyBalance),
                  icon: Icons.add_circle_outline,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton.secondary(
                  text: t.translate('requestContractProof'),
                  onPressed: () =>
                      context.pushNamed(RouteNames.contracts),
                  icon: Icons.description_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4 balance summary cards in a 2x2 grid
          Row(
            children: [
              Expanded(
                child: _BalanceMiniCard(
                  title: t.translate('balanceTotal'),
                  value: numberFormat.format(balance.totalPurchased.toInt()),
                  icon: Icons.account_balance_wallet_outlined,
                  gradient: AppColors.balanceGradient('blue'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BalanceMiniCard(
                  title: t.translate('balanceRemaining'),
                  value: numberFormat.format(balance.balance.toInt()),
                  icon: Icons.savings_outlined,
                  gradient: AppColors.balanceGradient('green'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _BalanceMiniCard(
                  title: t.translate('balanceConsumed'),
                  value: numberFormat.format(balance.totalSent),
                  icon: Icons.trending_up_outlined,
                  gradient: AppColors.balanceGradient('orange'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BalanceMiniCard(
                  title: t.translate('balanceTransferred'),
                  value: numberFormat.format(balance.totalTransferred),
                  icon: Icons.swap_horiz_outlined,
                  gradient: AppColors.balanceGradient('purple'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Expiry countdown
          if (balance.expiredAt != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.warningSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warningBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 20,
                    color: AppColors.warningDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.translate('balanceExpiresIn'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.warningDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_countdownDays ${t.translate('day')} : $_countdownHours ${t.translate('hour')} : $_countdownMinutes ${t.translate('minute')} : $_countdownSeconds ${t.translate('second')}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warningDark,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.translate('retry')),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// BALANCE MINI CARD
// ═══════════════════════════════════════════════════════════════════════

/// A compact card for the 2x2 balance summary grid.
class _BalanceMiniCard extends StatelessWidget {
  const _BalanceMiniCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  final String title;
  final String value;
  final IconData icon;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SLIVER TAB BAR DELEGATE
// ═══════════════════════════════════════════════════════════════════════

/// A persistent header delegate that pins the [TabBar] at the top
/// when scrolling within the [NestedScrollView].
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate({required this.tabBar});

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
