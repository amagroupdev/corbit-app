import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/features/messages/data/models/message_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Remote data source for message operations.
///
/// All calls target the messages API and use the shared [ApiClient]
/// which already handles Bearer token injection, language headers,
/// and error mapping.
class MessagesRemoteDatasource {
  const MessagesRemoteDatasource(this._client);

  final ApiClient _client;

  // ─── Send ────────────────────────────────────────────────────────────

  /// Sends a message through POST /messages/send.
  ///
  /// Returns the API response wrapping the created message data.
  Future<ApiResponse<Map<String, dynamic>>> sendMessage(
    SendMessageRequest request,
  ) async {
    final response = await _client.post(
      ApiConstants.messagesSend,
      data: request.toJson(),
    );
    return ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ─── Preview ─────────────────────────────────────────────────────────

  /// Previews a message to get cost estimate and recipient count
  /// without actually sending it.
  Future<MessagePreview> previewMessage(SendMessageRequest request) async {
    final response = await _client.post(
      ApiConstants.messagesPreview,
      data: request.toJson(),
    );
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
    );
    return MessagePreview.fromJson(apiResponse.data ?? {});
  }

  // ─── SMS Count ───────────────────────────────────────────────────────

  /// Calculates the number of SMS segments a message body will require.
  Future<SmsCountResult> calculateSmsCount(String message) async {
    final response = await _client.post(
      ApiConstants.messagesCalculateSmsCount,
      data: {'message': message},
    );
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
    );
    return SmsCountResult.fromJson(apiResponse.data ?? {});
  }

  // ─── Blocked Links ──────────────────────────────────────────────────

  /// Validates whether the message body contains blocked links.
  ///
  /// Returns `true` if the message is clean (no blocked links).
  Future<bool> validateBlockedLinks(String message) async {
    final response = await _client.post(
      ApiConstants.messagesValidateBlockedLinks,
      data: {'message': message},
    );
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
    );
    return apiResponse.data?['is_valid'] as bool? ?? false;
  }

  // ─── Duplicate Check ────────────────────────────────────────────────

  /// Checks whether a message with the same sender, number, and body
  /// has already been sent recently (duplicate guard).
  ///
  /// Returns `true` if a duplicate exists.
  Future<bool> checkDuplicate({
    required int senderId,
    required String number,
    required String message,
  }) async {
    final response = await _client.post(
      ApiConstants.messagesCheckDuplicate,
      data: {
        'sender_id': senderId,
        'number': number,
        'message': message,
      },
    );
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
    );
    return apiResponse.data?['is_duplicate'] as bool? ?? false;
  }

  // ─── Message List (Archive) ──────────────────────────────────────────

  /// Fetches a paginated list of sent messages, optionally filtered by type.
  ///
  /// Uses POST /archive/list which returns:
  /// `{success, message, data: {messages: [...], pagination: {...}}}`
  Future<PaginatedResponse<SentMessageModel>> listMessages({
    MessageType? type,
    String? search,
    int page = 1,
    int perPage = 15,
  }) async {
    final body = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      'archive_type': type?.apiValue ?? 'general',
      if (search != null && search.isNotEmpty) 'search': search,
    };

    // Use POST /archive/list (GET /archive does not exist).
    final response = await _client.post(
      '${ApiConstants.archive}/list',
      data: body,
    );

    final json = response.data as Map<String, dynamic>;
    final dataPayload = json['data'] as Map<String, dynamic>? ?? json;

    // The API returns {messages: [...], pagination: {...}}.
    // PaginatedResponse expects {data: [...], ...pagination}.
    // Remap if needed.
    if (dataPayload.containsKey('messages') && !dataPayload.containsKey('data')) {
      final remapped = <String, dynamic>{
        'data': dataPayload['messages'],
        ...?dataPayload['pagination'] as Map<String, dynamic>?,
      };
      return PaginatedResponse<SentMessageModel>.fromJson(
        remapped,
        itemFromJson: (item) => SentMessageModel.fromJson(item as Map<String, dynamic>),
      );
    }

    return PaginatedResponse<SentMessageModel>.fromJson(
      dataPayload,
      itemFromJson: (item) => SentMessageModel.fromJson(item as Map<String, dynamic>),
    );
  }

  // ─── Message Detail ──────────────────────────────────────────────────

  /// Fetches the detail of a single sent message by its ID.
  Future<SentMessageModel> getMessageDetail(int id) async {
    final response = await _client.get('${ApiConstants.archive}/$id');
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
    );
    return SentMessageModel.fromJson(apiResponse.data ?? {});
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final messagesRemoteDatasourceProvider = Provider<MessagesRemoteDatasource>((ref) {
  final client = ref.watch(apiClientProvider);
  return MessagesRemoteDatasource(client);
});
