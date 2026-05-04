import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/features/common/data/models/city_model.dart';
import 'package:orbit_app/features/common/data/models/organization_type_model.dart';
import 'package:orbit_app/features/common/data/models/region_model.dart';
import 'package:orbit_app/features/common/data/repositories/common_repository.dart';

// =============================================================================
// Cached lookups
// =============================================================================
//
// These FutureProviders cache the result for the lifetime of the provider —
// they only re-fetch when explicitly invalidated via:
// `ref.invalidate(regionsProvider)`.
// =============================================================================

/// `GET /common/regions` — list of Saudi regions.
final regionsProvider = FutureProvider<List<RegionModel>>((ref) async {
  return ref.watch(commonRepositoryProvider).getRegions();
});

/// `GET /common/cities` — list of Saudi cities, optionally scoped to a
/// region id (`null` returns all cities).
///
/// Usage:
/// ```dart
/// final citiesAsync = ref.watch(citiesProvider(_selectedRegionId));
/// ```
final citiesProvider =
    FutureProvider.family<List<CityModel>, int?>((ref, regionId) async {
  return ref.watch(commonRepositoryProvider).getCities(regionId: regionId);
});

/// `GET /common/organization-types` — list of organization categories.
final organizationTypesProvider =
    FutureProvider<List<OrganizationTypeModel>>((ref) async {
  return ref.watch(commonRepositoryProvider).getOrganizationTypes();
});

// =============================================================================
// One-shot helpers (not cached; useful for inline async work).
// =============================================================================

/// Returns the formatted Hijri-date string for [date] (defaults to today).
Future<String> fetchHijriDate(Ref ref, {DateTime? date}) {
  return ref.read(commonRepositoryProvider).getHijriDate(date: date);
}

/// Returns `true` when [email] is available for registration.
Future<bool> checkEmailAvailable(Ref ref, String email) {
  return ref.read(commonRepositoryProvider).checkEmail(email);
}

/// Returns `true` when [username] is available for registration.
Future<bool> checkUsernameAvailable(Ref ref, String username) {
  return ref.read(commonRepositoryProvider).checkUsername(username);
}

/// Returns `true` when [phone] is available for registration.
Future<bool> checkPhoneAvailable(Ref ref, String phone) {
  return ref.read(commonRepositoryProvider).checkPhone(phone);
}
