import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/absence/data/models/absence_message_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Remote data source for absence & tardiness message operations.
class AbsenceRemoteDatasource {
  const AbsenceRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// Fetches a paginated list of absence/tardiness messages.
  ///
  /// Supports filtering by [search], [messageType], [status],
  /// [senderName], [classification], [dateFrom], and [dateTo].
  Future<PaginatedResponse<AbsenceMessageModel>> getMessages({
    int page = 1,
    String? search,
    String? messageType,
    String? status,
    String? senderName,
    String? classification,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.absenceMessages}/list',
        data: {
          'page': page,
          'per_page': ApiConstants.defaultPerPage,
          if (search != null && search.isNotEmpty) 'search': search,
          if (messageType != null && messageType.isNotEmpty)
            'message_type': messageType,
          if (status != null && status.isNotEmpty) 'status': status,
          if (senderName != null && senderName.isNotEmpty)
            'sender_name': senderName,
          if (classification != null && classification.isNotEmpty)
            'classification': classification,
          if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
          if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
        },
      );

      final apiResponse =
          ApiResponse<PaginatedResponse<AbsenceMessageModel>>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) =>
            PaginatedResponse<AbsenceMessageModel>.fromJson(
          data as Map<String, dynamic>,
          itemFromJson: (item) =>
              AbsenceMessageModel.fromJson(item as Map<String, dynamic>),
        ),
      );

      return apiResponse.data ??
          PaginatedResponse<AbsenceMessageModel>.empty();
    } on ApiException {
      rethrow;
    }
  }

  /// Sends an absence message to parents/guardians.
  Future<void> sendAbsenceMessage({
    required int senderId,
    required String messageBody,
    required String messageType,
    required List<int> groupIds,
    List<String>? numbers,
  }) async {
    try {
      await _apiClient.post(
        '${ApiConstants.absenceMessages}/send',
        data: {
          'sender_id': senderId,
          'message_body': messageBody,
          'message_type': messageType,
          if (groupIds.isNotEmpty) 'group_ids': groupIds,
          if (numbers != null && numbers.isNotEmpty) 'numbers': numbers,
        },
      );
    } on ApiException {
      rethrow;
    }
  }

  /// Fetches details of a specific absence message by [id].
  Future<AbsenceMessageModel> getMessageDetail(int id) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.absenceMessageShow(id),
      );

      final apiResponse =
          ApiResponse<AbsenceMessageModel>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) =>
            AbsenceMessageModel.fromJson(data as Map<String, dynamic>),
      );

      return apiResponse.data!;
    } on ApiException {
      rethrow;
    }
  }

  /// Fetches the delivery report for a specific absence message.
  Future<PaginatedResponse<Map<String, dynamic>>> getReport(
    int id, {
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.absenceMessages}/$id/report',
        data: {
          'page': page,
          'per_page': ApiConstants.defaultPerPage,
        },
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

final absenceRemoteDatasourceProvider =
    Provider<AbsenceRemoteDatasource>((ref) {
  return AbsenceRemoteDatasource(ref.watch(apiClientProvider));
});
