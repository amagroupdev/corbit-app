import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/questionnaires/data/models/questionnaire_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository for managing questionnaires.
class QuestionnairesRepository {
  const QuestionnairesRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Fetches a paginated list of sent questionnaires.
  Future<PaginatedResponse<QuestionnaireModel>> getSentQuestionnaires({
    int page = 1,
    String? search,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.questionnaires}/list',
        data: {
          'page': page,
          'per_page': ApiConstants.defaultPerPage,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final apiResponse =
          ApiResponse<PaginatedResponse<QuestionnaireModel>>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) => PaginatedResponse<QuestionnaireModel>.fromJson(
          data as Map<String, dynamic>,
          itemFromJson: (item) =>
              QuestionnaireModel.fromJson(item as Map<String, dynamic>),
        ),
      );

      return apiResponse.data ??
          PaginatedResponse<QuestionnaireModel>.empty();
    } on ApiException {
      rethrow;
    }
  }

  /// Fetches a paginated list of unsent questionnaires.
  Future<PaginatedResponse<QuestionnaireModel>> getUnsentQuestionnaires({
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.questionnaires}/unsent',
        data: {
          'page': page,
          'per_page': ApiConstants.defaultPerPage,
        },
      );

      final apiResponse =
          ApiResponse<PaginatedResponse<QuestionnaireModel>>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) => PaginatedResponse<QuestionnaireModel>.fromJson(
          data as Map<String, dynamic>,
          itemFromJson: (item) =>
              QuestionnaireModel.fromJson(item as Map<String, dynamic>),
        ),
      );

      return apiResponse.data ??
          PaginatedResponse<QuestionnaireModel>.empty();
    } on ApiException {
      rethrow;
    }
  }

  /// Sends a questionnaire to recipients.
  Future<void> sendQuestionnaire({
    required int questionnaireId,
    required List<int> groupIds,
    List<String>? numbers,
  }) async {
    try {
      await _apiClient.post(
        '${ApiConstants.questionnaires}/send',
        data: {
          'questionnaire_id': questionnaireId,
          if (groupIds.isNotEmpty) 'group_ids': groupIds,
          if (numbers != null && numbers.isNotEmpty) 'numbers': numbers,
        },
      );
    } on ApiException {
      rethrow;
    }
  }

  /// Sends a questionnaire with an SMS notification.
  Future<void> sendWithSms({
    required int questionnaireId,
    required int senderId,
    required String messageBody,
    required List<int> groupIds,
    List<String>? numbers,
  }) async {
    try {
      await _apiClient.post(
        '${ApiConstants.questionnaires}/send-with-sms',
        data: {
          'questionnaire_id': questionnaireId,
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

  /// Deletes a questionnaire by [id].
  Future<void> deleteQuestionnaire(int id) async {
    try {
      await _apiClient.delete(
        ApiConstants.questionnaireDelete(id),
      );
    } on ApiException {
      rethrow;
    }
  }

  /// Fetches responses for a specific questionnaire.
  Future<PaginatedResponse<Map<String, dynamic>>> getResponses(
    int id, {
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.questionnaires}/$id/responses',
        data: {'page': page, 'per_page': ApiConstants.defaultPerPage},
      );

      final apiResponse =
          ApiResponse<PaginatedResponse<Map<String, dynamic>>>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) =>
            PaginatedResponse<Map<String, dynamic>>.fromJson(
          data as Map<String, dynamic>,
          itemFromJson: (item) => item as Map<String, dynamic>,
        ),
      );

      return apiResponse.data ??
          PaginatedResponse<Map<String, dynamic>>.empty();
    } on ApiException {
      rethrow;
    }
  }

  /// Fetches recipients who have not filled a questionnaire.
  Future<PaginatedResponse<Map<String, dynamic>>> getNotFilled(
    int id, {
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.questionnaires}/$id/not-filled',
        data: {'page': page, 'per_page': ApiConstants.defaultPerPage},
      );

      final apiResponse =
          ApiResponse<PaginatedResponse<Map<String, dynamic>>>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) =>
            PaginatedResponse<Map<String, dynamic>>.fromJson(
          data as Map<String, dynamic>,
          itemFromJson: (item) => item as Map<String, dynamic>,
        ),
      );

      return apiResponse.data ??
          PaginatedResponse<Map<String, dynamic>>.empty();
    } on ApiException {
      rethrow;
    }
  }

  /// Fetches recipients list for a questionnaire.
  Future<PaginatedResponse<Map<String, dynamic>>> getRecipients(
    int id, {
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.questionnaires}/$id/recipients',
        data: {'page': page, 'per_page': ApiConstants.defaultPerPage},
      );

      final apiResponse =
          ApiResponse<PaginatedResponse<Map<String, dynamic>>>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) =>
            PaginatedResponse<Map<String, dynamic>>.fromJson(
          data as Map<String, dynamic>,
          itemFromJson: (item) => item as Map<String, dynamic>,
        ),
      );

      return apiResponse.data ??
          PaginatedResponse<Map<String, dynamic>>.empty();
    } on ApiException {
      rethrow;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

final questionnairesRepositoryProvider =
    Provider<QuestionnairesRepository>((ref) {
  return QuestionnairesRepository(ref.watch(apiClientProvider));
});
