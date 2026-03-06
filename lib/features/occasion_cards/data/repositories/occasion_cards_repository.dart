import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/occasion_cards/data/models/occasion_card_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository for occasion card operations.
class OccasionCardsRepository {
  const OccasionCardsRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Fetches available occasion card templates.
  Future<List<OccasionCardTemplateModel>> getTemplates() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.occasionCardTemplates,
      );

      final apiResponse =
          ApiResponse<List<OccasionCardTemplateModel>>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) => (data as List<dynamic>)
            .map((item) => OccasionCardTemplateModel.fromJson(
                item as Map<String, dynamic>))
            .toList(),
      );

      return apiResponse.data ?? [];
    } on ApiException {
      rethrow;
    }
  }

  /// Sends an occasion card.
  Future<void> sendCard({
    required int templateId,
    required String message,
    required List<int> groupIds,
    List<String>? numbers,
    int? senderId,
  }) async {
    try {
      await _apiClient.post(
        '${ApiConstants.occasionCards}/send',
        data: {
          'template_id': templateId,
          'message': message,
          if (groupIds.isNotEmpty) 'group_ids': groupIds,
          if (numbers != null && numbers.isNotEmpty) 'numbers': numbers,
          if (senderId != null) 'sender_id': senderId,
        },
      );
    } on ApiException {
      rethrow;
    }
  }

  /// Previews an occasion card before sending.
  Future<Map<String, dynamic>> preview({
    required int templateId,
    required String message,
    required List<int> groupIds,
    List<String>? numbers,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.occasionCards}/preview',
        data: {
          'template_id': templateId,
          'message': message,
          if (groupIds.isNotEmpty) 'group_ids': groupIds,
          if (numbers != null && numbers.isNotEmpty) 'numbers': numbers,
        },
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
      );

      return apiResponse.data ?? {};
    } on ApiException {
      rethrow;
    }
  }

  /// Fetches the archive of sent occasion cards.
  Future<PaginatedResponse<OccasionCardModel>> getArchive({
    int page = 1,
    String? search,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.occasionCards}/list',
        data: {
          'page': page,
          'per_page': ApiConstants.defaultPerPage,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final apiResponse =
          ApiResponse<PaginatedResponse<OccasionCardModel>>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) => PaginatedResponse<OccasionCardModel>.fromJson(
          data as Map<String, dynamic>,
          itemFromJson: (item) =>
              OccasionCardModel.fromJson(item as Map<String, dynamic>),
        ),
      );

      return apiResponse.data ?? PaginatedResponse<OccasionCardModel>.empty();
    } on ApiException {
      rethrow;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

final occasionCardsRepositoryProvider =
    Provider<OccasionCardsRepository>((ref) {
  return OccasionCardsRepository(ref.watch(apiClientProvider));
});
