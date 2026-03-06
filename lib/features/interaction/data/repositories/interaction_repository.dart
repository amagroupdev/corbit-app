import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/interaction/data/models/interaction_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository for interaction (two-way messaging) operations.
class InteractionRepository {
  const InteractionRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Checks if the root URL is available for interaction.
  Future<bool> checkRoot(String rootUrl) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.interactions}/check-root',
        data: {'root_url': rootUrl},
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
      );

      return apiResponse.data?['available'] as bool? ?? false;
    } on ApiException {
      rethrow;
    }
  }

  /// Sends an interaction message.
  Future<void> send({
    required String message,
    required int senderId,
    required List<int> groupIds,
    List<String>? numbers,
  }) async {
    try {
      await _apiClient.post(
        '${ApiConstants.interactions}/send',
        data: {
          'message': message,
          'sender_id': senderId,
          if (groupIds.isNotEmpty) 'group_ids': groupIds,
          if (numbers != null && numbers.isNotEmpty) 'numbers': numbers,
        },
      );
    } on ApiException {
      rethrow;
    }
  }

  /// Previews an interaction before sending.
  Future<Map<String, dynamic>> preview({
    required String message,
    required int senderId,
    required List<int> groupIds,
    List<String>? numbers,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.interactions}/preview',
        data: {
          'message': message,
          'sender_id': senderId,
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

  /// Fetches replies for all interactions.
  Future<PaginatedResponse<InteractionReply>> getReplies({
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.interactions}/replies',
        data: {
          'page': page,
          'per_page': ApiConstants.defaultPerPage,
        },
      );

      final apiResponse =
          ApiResponse<PaginatedResponse<InteractionReply>>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) => PaginatedResponse<InteractionReply>.fromJson(
          data as Map<String, dynamic>,
          itemFromJson: (item) =>
              InteractionReply.fromJson(item as Map<String, dynamic>),
        ),
      );

      return apiResponse.data ??
          PaginatedResponse<InteractionReply>.empty();
    } on ApiException {
      rethrow;
    }
  }

  /// Fetches replies for a specific interaction.
  Future<PaginatedResponse<InteractionReply>> getInteractionReplies(
    int id, {
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.interactions}/replies/$id',
      );

      final apiResponse =
          ApiResponse<PaginatedResponse<InteractionReply>>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) => PaginatedResponse<InteractionReply>.fromJson(
          data as Map<String, dynamic>,
          itemFromJson: (item) =>
              InteractionReply.fromJson(item as Map<String, dynamic>),
        ),
      );

      return apiResponse.data ??
          PaginatedResponse<InteractionReply>.empty();
    } on ApiException {
      rethrow;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

final interactionRepositoryProvider = Provider<InteractionRepository>((ref) {
  return InteractionRepository(ref.watch(apiClientProvider));
});
