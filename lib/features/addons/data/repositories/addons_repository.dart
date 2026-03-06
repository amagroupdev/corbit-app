import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/addons/data/models/addon_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository for managing addon/service subscriptions.
class AddonsRepository {
  const AddonsRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Fetches a paginated list of available addons.
  ///
  /// API returns: `{success, message, data: {data: [...], meta: {current_page, last_page, per_page, total}}}`
  Future<PaginatedResponse<AddonModel>> getAddons({
    int page = 1,
    String? search,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.addons}/list',
        data: {
          'page': page,
          'per_page': ApiConstants.defaultPerPage,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final json = response.data as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>? ?? json;

      // Remap meta to top-level pagination fields if needed.
      final meta = data['meta'] as Map<String, dynamic>?;
      final remapped = <String, dynamic>{
        'data': data['data'] ?? [],
        ...?meta,
      };

      return PaginatedResponse<AddonModel>.fromJson(
        remapped,
        itemFromJson: (item) =>
            AddonModel.fromJson(item as Map<String, dynamic>),
      );
    } on ApiException {
      rethrow;
    }
  }

  /// Fetches details of a specific addon by [id].
  Future<AddonModel> getAddon(int id) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.addonShow(id),
      );

      final apiResponse = ApiResponse<AddonModel>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) =>
            AddonModel.fromJson(data as Map<String, dynamic>),
      );

      return apiResponse.data!;
    } on ApiException {
      rethrow;
    }
  }

  /// Activates a free trial for addon [id].
  Future<void> activateTrial(int id) async {
    try {
      await _apiClient.post(
        ApiConstants.addonActivateTrial(id),
      );
    } on ApiException {
      rethrow;
    }
  }

  /// Initiates payment for addon [id] with subscription plan [planId].
  ///
  /// Returns a payment URL or confirmation depending on the payment flow.
  Future<Map<String, dynamic>> initiatePayment({
    required int addonId,
    required int planId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.addonInitiatePayment(addonId),
        data: {'plan_id': planId},
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
      );

      return apiResponse.data ?? {};
    } on ApiException {
      rethrow;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

final addonsRepositoryProvider = Provider<AddonsRepository>((ref) {
  return AddonsRepository(ref.watch(apiClientProvider));
});

final addonsListProvider = FutureProvider.family<
    PaginatedResponse<AddonModel>, ({int page, String? search})>(
  (ref, params) {
    final repository = ref.watch(addonsRepositoryProvider);
    return repository.getAddons(page: params.page, search: params.search);
  },
);

final addonDetailProvider =
    FutureProvider.family<AddonModel, int>((ref, id) {
  final repository = ref.watch(addonsRepositoryProvider);
  return repository.getAddon(id);
});
