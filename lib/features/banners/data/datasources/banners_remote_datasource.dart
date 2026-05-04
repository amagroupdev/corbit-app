import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/features/banners/data/models/banner_model.dart';

/// Remote data source for the V3 promotional banners endpoints.
///
/// - `GET /banners/login`     — public (no auth header required)
/// - `GET /banners/dashboard` — authenticated
///
/// Both endpoints respond with the standard envelope:
/// `{ success, message, data: [ BannerModel, ... ] }`.
class BannersRemoteDataSource {
  const BannersRemoteDataSource(this._client);

  final ApiClient _client;

  /// Fetches the carousel shown on the login screen (no auth).
  Future<List<BannerModel>> fetchLoginBanners() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.bannersLogin,
    );
    return _parseList(response.data);
  }

  /// Fetches the carousel embedded in the dashboard (auth required).
  Future<List<BannerModel>> fetchDashboardBanners() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.bannersDashboard,
    );
    return _parseList(response.data);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  List<BannerModel> _parseList(Map<String, dynamic>? body) {
    if (body == null) return const [];
    final raw = body['data'];
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(BannerModel.fromJson)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    return const [];
  }
}

/// Riverpod provider for [BannersRemoteDataSource].
final bannersRemoteDataSourceProvider =
    Provider<BannersRemoteDataSource>((ref) {
  final client = ref.watch(apiClientProvider);
  return BannersRemoteDataSource(client);
});
