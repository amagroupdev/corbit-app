import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/features/occasion_cards/data/models/occasion_card_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Remote data source for the V3 occasion-cards endpoints.
///
/// Endpoints:
/// - `GET  /occasion-cards/templates`
/// - `POST /occasion-cards/send`
/// - `POST /occasion-cards/preview`
/// - `POST /occasion-cards/list`
///
/// The legacy [OccasionCardsRepository] kept all of this inline; the
/// datasource now centralises HTTP shape and parsing so the repository
/// becomes a thin pass-through.
class OccasionCardsRemoteDataSource {
  const OccasionCardsRemoteDataSource(this._client);

  final ApiClient _client;

  // ─── Templates ───────────────────────────────────────────────────────

  Future<List<OccasionCardTemplateModel>> fetchTemplates() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.occasionCardsTemplates,
    );

    final apiResponse =
        ApiResponse<List<OccasionCardTemplateModel>>.fromJson(
      response.data ?? const {},
      fromJsonT: (data) => (data as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(OccasionCardTemplateModel.fromJson)
          .toList(),
    );
    return apiResponse.data ?? const [];
  }

  // ─── Send ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> send({
    required int templateId,
    required String message,
    List<int> groupIds = const [],
    List<String> numbers = const [],
    int? senderId,
    DateTime? scheduledAt,
  }) async {
    final body = <String, dynamic>{
      'template_id': templateId,
      'message': message,
      if (groupIds.isNotEmpty) 'group_ids': groupIds,
      if (numbers.isNotEmpty) 'numbers': numbers,
      if (senderId != null) 'sender_id': senderId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt.toIso8601String(),
    };

    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.occasionCardsSend,
      data: body,
    );
    return response.data ?? const {};
  }

  // ─── Preview ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> preview({
    required int templateId,
    required String message,
    List<int> groupIds = const [],
    List<String> numbers = const [],
  }) async {
    final body = <String, dynamic>{
      'template_id': templateId,
      'message': message,
      if (groupIds.isNotEmpty) 'group_ids': groupIds,
      if (numbers.isNotEmpty) 'numbers': numbers,
    };

    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.occasionCardsPreview,
      data: body,
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data ?? const {},
    );
    return apiResponse.data ?? const {};
  }

  // ─── List (archive) ──────────────────────────────────────────────────

  Future<PaginatedResponse<OccasionCardModel>> fetchArchive({
    int page = 1,
    int perPage = ApiConstants.defaultPerPage,
    String? search,
  }) async {
    final body = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };

    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.occasionCardsList,
      data: body,
    );

    final apiResponse =
        ApiResponse<PaginatedResponse<OccasionCardModel>>.fromJson(
      response.data ?? const {},
      fromJsonT: (data) => PaginatedResponse<OccasionCardModel>.fromJson(
        data as Map<String, dynamic>,
        itemFromJson: (item) =>
            OccasionCardModel.fromJson(item as Map<String, dynamic>),
      ),
    );
    return apiResponse.data ?? PaginatedResponse<OccasionCardModel>.empty();
  }
}

/// Riverpod provider for [OccasionCardsRemoteDataSource].
final occasionCardsRemoteDataSourceProvider =
    Provider<OccasionCardsRemoteDataSource>((ref) {
  final client = ref.watch(apiClientProvider);
  return OccasionCardsRemoteDataSource(client);
});
