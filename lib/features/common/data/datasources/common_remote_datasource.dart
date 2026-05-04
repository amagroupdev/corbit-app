import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/features/common/data/models/city_model.dart';
import 'package:orbit_app/features/common/data/models/organization_type_model.dart';
import 'package:orbit_app/features/common/data/models/region_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';

/// Remote data source for the V3 `/common` and `/utils` endpoints.
///
/// All methods throw [ApiException] subtypes on failure; the repository
/// layer is responsible for wrapping them in a unified [Result].
class CommonRemoteDataSource {
  const CommonRemoteDataSource(this._client);

  final ApiClient _client;

  // ---------------------------------------------------------------------------
  // Lookups (organization types, regions, cities)
  // ---------------------------------------------------------------------------

  /// `GET /common/organization-types`
  Future<List<OrganizationTypeModel>> getOrganizationTypes() async {
    final response = await _client.get(ApiConstants.commonOrganizationTypes);
    final list = _extractList(response.data);
    return list
        .map((e) =>
            OrganizationTypeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /common/regions`
  Future<List<RegionModel>> getRegions() async {
    final response = await _client.get(ApiConstants.commonRegions);
    final list = _extractList(response.data);
    return list
        .map((e) => RegionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /common/cities` (optionally scoped to a [regionId]).
  Future<List<CityModel>> getCities({int? regionId}) async {
    final response = await _client.get(
      ApiConstants.commonCities,
      queryParameters:
          regionId != null ? <String, dynamic>{'region_id': regionId} : null,
    );
    final list = _extractList(response.data);
    return list
        .map((e) => CityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Availability checks (email / username / phone)
  // ---------------------------------------------------------------------------

  /// `POST /common/check-email` — returns `true` when [email] is available
  /// for registration (i.e. not already in use).
  Future<bool> checkEmail(String email) async {
    final response = await _client.post(
      ApiConstants.commonCheckEmail,
      data: {'email': email},
    );
    return _extractAvailability(response.data);
  }

  /// `POST /common/check-username` — returns `true` when [username] is available.
  Future<bool> checkUsername(String username) async {
    final response = await _client.post(
      ApiConstants.commonCheckUsername,
      data: {'username': username},
    );
    return _extractAvailability(response.data);
  }

  /// `POST /common/check-phone` — returns `true` when [phone] is available.
  Future<bool> checkPhone(String phone) async {
    final response = await _client.post(
      ApiConstants.commonCheckPhone,
      data: {'phone': phone},
    );
    return _extractAvailability(response.data);
  }

  // ---------------------------------------------------------------------------
  // Hijri date utility
  // ---------------------------------------------------------------------------

  /// `GET /utils/hijri-date` — returns the localized Hijri-date string for
  /// the given Gregorian [date] (defaults to today on the server side).
  ///
  /// Example: `"12 رمضان 1447 هـ"`.
  Future<String> getHijriDate({DateTime? date}) async {
    final response = await _client.get(
      ApiConstants.utilsHijriDate,
      queryParameters: date != null
          ? <String, dynamic>{
              'date':
                  '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            }
          : null,
    );
    final data = _extractMap(response.data);
    return data['hijri_date'] as String? ??
        data['hijri'] as String? ??
        data['formatted'] as String? ??
        '';
  }

  // ---------------------------------------------------------------------------
  // Private response helpers
  // ---------------------------------------------------------------------------

  /// Extracts a list from the API response, handling all common envelopes:
  ///   - `{ "data": [...] }`
  ///   - `{ "data": { "items": [...] } }`
  ///   - `{ "data": { "regions"|"cities"|"organization_types": [...] } }`
  ///   - `[...]` (raw array)
  static List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is! Map<String, dynamic>) return const <dynamic>[];

    final api = ApiResponse<dynamic>.fromJson(raw);
    final payload = api.data;

    if (payload is List) return payload;
    if (payload is Map<String, dynamic>) {
      // Try common nested keys.
      for (final key in const [
        'items',
        'list',
        'regions',
        'cities',
        'organization_types',
        'organizationTypes',
        'governorates',
      ]) {
        final value = payload[key];
        if (value is List) return value;
      }
    }

    // Some endpoints skip the envelope.
    final fallback = raw['data'] ?? raw['items'] ?? raw['list'];
    if (fallback is List) return fallback;

    return const <dynamic>[];
  }

  /// Extracts a map from the API response, handling envelopes.
  static Map<String, dynamic> _extractMap(dynamic raw) {
    if (raw is! Map<String, dynamic>) return const <String, dynamic>{};

    final api = ApiResponse<dynamic>.fromJson(raw);
    final payload = api.data;
    if (payload is Map<String, dynamic>) return payload;

    return raw;
  }

  /// Normalizes the response of an availability check endpoint to a single
  /// boolean. Accepts every common server shape:
  ///   - `{ "available": true }`
  ///   - `{ "exists": false }`
  ///   - `{ "data": { "available": true } }`
  ///   - `{ "success": true }` (assume available)
  static bool _extractAvailability(dynamic raw) {
    final data = _extractMap(raw);
    if (data['available'] is bool) return data['available'] as bool;
    if (data['is_available'] is bool) return data['is_available'] as bool;
    if (data['exists'] is bool) return !(data['exists'] as bool);
    if (data['taken'] is bool) return !(data['taken'] as bool);

    // Fall back to the wrapper's success flag if present.
    if (raw is Map<String, dynamic> && raw['success'] == true) return true;
    return false;
  }
}

// =============================================================================
// Provider
// =============================================================================

/// Riverpod provider for [CommonRemoteDataSource].
final commonRemoteDataSourceProvider =
    Provider<CommonRemoteDataSource>((ref) {
  return CommonRemoteDataSource(ref.watch(apiClientProvider));
});
