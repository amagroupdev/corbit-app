import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/notifications/data/models/notification_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository for push notification operations.
class NotificationsRepository {
  const NotificationsRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Sends a push notification.
  Future<void> sendNotification({
    required String message,
    required List<int> groupIds,
    List<String>? numbers,
  }) async {
    try {
      await _apiClient.post(
        '${ApiConstants.notifications}/send',
        data: {
          'message': message,
          if (groupIds.isNotEmpty) 'group_ids': groupIds,
          if (numbers != null && numbers.isNotEmpty) 'numbers': numbers,
        },
      );
    } on ApiException {
      rethrow;
    }
  }

  /// Gets a preview/cost estimate before sending.
  Future<Map<String, dynamic>> preview({
    required String message,
    required List<int> groupIds,
    List<String>? numbers,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.notifications}/preview',
        data: {
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

  /// Fetches the notification archive list.
  ///
  /// API returns: `{success, message, data: {data: [...], pagination: {...}}}`
  Future<PaginatedResponse<NotificationModel>> getArchive({
    int page = 1,
    String? search,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.notifications}/archive/list',
        data: {
          'page': page,
          'per_page': ApiConstants.defaultPerPage,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final json = response.data as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>? ?? json;

      // Remap pagination to top-level fields for PaginatedResponse.
      final pagination = data['pagination'] as Map<String, dynamic>?;
      final remapped = <String, dynamic>{
        'data': data['data'] ?? [],
        ...?pagination,
      };

      return PaginatedResponse<NotificationModel>.fromJson(
        remapped,
        itemFromJson: (item) =>
            NotificationModel.fromJson(item as Map<String, dynamic>),
      );
    } on ApiException {
      rethrow;
    }
  }

  /// Gets the count of archived notifications.
  Future<int> getArchiveCount() async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.notifications}/archive/count',
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
      );

      return apiResponse.data?['count'] as int? ?? 0;
    } on ApiException {
      rethrow;
    }
  }

  /// Deletes an archived notification.
  Future<void> deleteArchiveItem(int id) async {
    try {
      await _apiClient.post(
        '${ApiConstants.notifications}/archive/delete',
        data: {'id': id},
      );
    } on ApiException {
      rethrow;
    }
  }

  /// Exports the notification archive.
  Future<String> exportArchive() async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.notifications}/archive/export',
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
      );

      return apiResponse.data?['download_url'] as String? ?? '';
    } on ApiException {
      rethrow;
    }
  }

  /// Fetches replies for a specific notification.
  Future<PaginatedResponse<Map<String, dynamic>>> getReplies(int id) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.notifications}/$id/replies',
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

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});
