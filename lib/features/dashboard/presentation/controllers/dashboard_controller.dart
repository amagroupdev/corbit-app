import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/features/dashboard/data/models/dashboard_model.dart';
import 'package:orbit_app/features/dashboard/data/repositories/dashboard_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
// DASHBOARD STATS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Async notifier that loads and caches the main dashboard statistics.
///
/// Exposes [refresh] so the UI can trigger a pull-to-refresh.
class DashboardStatsNotifier extends AsyncNotifier<DashboardStats> {
  @override
  Future<DashboardStats> build() async {
    return _fetch();
  }

  Future<DashboardStats> _fetch() async {
    final repo = ref.read(dashboardRepositoryProvider);
    return repo.fetchDashboardStats();
  }

  /// Refresh the dashboard data (e.g. on pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }
}

final dashboardStatsProvider =
    AsyncNotifierProvider<DashboardStatsNotifier, DashboardStats>(
  DashboardStatsNotifier.new,
);

// ═══════════════════════════════════════════════════════════════════════════
// BANNERS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Async notifier that loads promotional banners for the carousel.
class DashboardBannersNotifier extends AsyncNotifier<List<BannerItem>> {
  @override
  Future<List<BannerItem>> build() async {
    return _fetch();
  }

  Future<List<BannerItem>> _fetch() async {
    final repo = ref.read(dashboardRepositoryProvider);
    return repo.fetchBanners();
  }

  /// Refresh banners.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }
}

final dashboardBannersProvider =
    AsyncNotifierProvider<DashboardBannersNotifier, List<BannerItem>>(
  DashboardBannersNotifier.new,
);

// ═══════════════════════════════════════════════════════════════════════════
// CAROUSEL INDEX PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Tracks the currently visible page in the promotional carousel.
final carouselIndexProvider = StateProvider<int>((ref) => 0);

// ═══════════════════════════════════════════════════════════════════════════
// CONVENIENCE: Refresh entire dashboard
// ═══════════════════════════════════════════════════════════════════════════

/// Invalidates and refetches all dashboard-related providers.
///
/// Usage inside a widget:
/// ```dart
/// await ref.read(refreshDashboardProvider)();
/// ```
final refreshDashboardProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await Future.wait([
      ref.read(dashboardStatsProvider.notifier).refresh(),
      ref.read(dashboardBannersProvider.notifier).refresh(),
    ]);
  };
});
