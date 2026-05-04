import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/banners/data/datasources/banners_remote_datasource.dart';
import 'package:orbit_app/features/banners/data/models/banner_model.dart';

/// Thin repository over [BannersRemoteDataSource].
///
/// Banners are non-critical UI: any failure (offline, 5xx, schema drift)
/// resolves to an empty list so the UI simply collapses the carousel.
class BannersRepository {
  const BannersRepository(this._remote);

  final BannersRemoteDataSource _remote;

  Future<List<BannerModel>> getLoginBanners() async {
    try {
      return await _remote.fetchLoginBanners();
    } on ApiException {
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<List<BannerModel>> getDashboardBanners() async {
    try {
      return await _remote.fetchDashboardBanners();
    } on ApiException {
      return const [];
    } catch (_) {
      return const [];
    }
  }
}

/// Riverpod provider for [BannersRepository].
final bannersRepositoryProvider = Provider<BannersRepository>((ref) {
  final remote = ref.watch(bannersRemoteDataSourceProvider);
  return BannersRepository(remote);
});

// ─── Async data providers ─────────────────────────────────────────────

/// Login carousel — fetched lazily on the login screen.
final loginBannersProvider = FutureProvider<List<BannerModel>>((ref) async {
  return ref.watch(bannersRepositoryProvider).getLoginBanners();
});

/// Dashboard carousel — fetched lazily on the dashboard.
final dashboardBannersV3Provider =
    FutureProvider<List<BannerModel>>((ref) async {
  return ref.watch(bannersRepositoryProvider).getDashboardBanners();
});
