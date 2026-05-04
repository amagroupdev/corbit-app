import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/common/data/datasources/common_remote_datasource.dart';
import 'package:orbit_app/features/common/data/models/city_model.dart';
import 'package:orbit_app/features/common/data/models/organization_type_model.dart';
import 'package:orbit_app/features/common/data/models/region_model.dart';

/// Repository for the V3 `/common` and `/utils` endpoints.
///
/// Acts as a thin pass-through over [CommonRemoteDataSource]; methods
/// rethrow [ApiException] subtypes so the controller / FutureProvider
/// layer can render localized error states.
class CommonRepository {
  const CommonRepository(this._datasource);

  final CommonRemoteDataSource _datasource;

  // ---------------------------------------------------------------------------
  // Lookups
  // ---------------------------------------------------------------------------

  /// Lists organization types (lookup table).
  Future<List<OrganizationTypeModel>> getOrganizationTypes() async {
    try {
      return await _datasource.getOrganizationTypes();
    } on ApiException {
      rethrow;
    }
  }

  /// Lists Saudi regions (lookup table).
  Future<List<RegionModel>> getRegions() async {
    try {
      return await _datasource.getRegions();
    } on ApiException {
      rethrow;
    }
  }

  /// Lists cities, optionally scoped to a [regionId].
  Future<List<CityModel>> getCities({int? regionId}) async {
    try {
      return await _datasource.getCities(regionId: regionId);
    } on ApiException {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Availability checks
  // ---------------------------------------------------------------------------

  /// Returns `true` when [email] is not already in use.
  Future<bool> checkEmail(String email) async {
    try {
      return await _datasource.checkEmail(email);
    } on ApiException {
      rethrow;
    }
  }

  /// Returns `true` when [username] is not already in use.
  Future<bool> checkUsername(String username) async {
    try {
      return await _datasource.checkUsername(username);
    } on ApiException {
      rethrow;
    }
  }

  /// Returns `true` when [phone] is not already in use.
  Future<bool> checkPhone(String phone) async {
    try {
      return await _datasource.checkPhone(phone);
    } on ApiException {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Hijri date helper
  // ---------------------------------------------------------------------------

  /// Returns the formatted Hijri-date string for the given Gregorian [date].
  Future<String> getHijriDate({DateTime? date}) async {
    try {
      return await _datasource.getHijriDate(date: date);
    } on ApiException {
      rethrow;
    }
  }
}

// =============================================================================
// Provider
// =============================================================================

/// Riverpod provider for [CommonRepository].
final commonRepositoryProvider = Provider<CommonRepository>((ref) {
  return CommonRepository(ref.watch(commonRemoteDataSourceProvider));
});
