import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/vip_cards/data/models/vip_card_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository for VIP card operations.
///
/// VIP cards are sent via the messages/send endpoint with
/// message_type=vip_cards. This repository handles the archive.
class VipCardsRepository {
  const VipCardsRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Sends VIP cards via the messages send endpoint.
  Future<void> sendVipCards({
    required int senderId,
    required String messageBody,
    required List<int> groupIds,
    List<String>? numbers,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.messagesSend,
        data: {
          'message_type': 'vip_cards',
          'sender_id': senderId,
          'message_body': messageBody,
          if (groupIds.isNotEmpty) 'group_ids': groupIds,
          if (numbers != null && numbers.isNotEmpty) 'numbers': numbers,
        },
      );
    } on ApiException {
      rethrow;
    }
  }

  /// Fetches the VIP cards archive.
  Future<PaginatedResponse<VipCardModel>> getArchive({
    int page = 1,
    String? search,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.archive}',
        data: {
          'page': page,
          'per_page': ApiConstants.defaultPerPage,
          'message_type': 'vip_cards',
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final apiResponse =
          ApiResponse<PaginatedResponse<VipCardModel>>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) => PaginatedResponse<VipCardModel>.fromJson(
          data as Map<String, dynamic>,
          itemFromJson: (item) =>
              VipCardModel.fromJson(item as Map<String, dynamic>),
        ),
      );

      return apiResponse.data ?? PaginatedResponse<VipCardModel>.empty();
    } on ApiException {
      rethrow;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

final vipCardsRepositoryProvider = Provider<VipCardsRepository>((ref) {
  return VipCardsRepository(ref.watch(apiClientProvider));
});
