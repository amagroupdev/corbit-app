import 'dart:io';

import 'package:dio/dio.dart' show MultipartFile;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/features/messages/data/models/dlr_report_model.dart';
import 'package:orbit_app/features/messages/data/models/dynamic_text_model.dart';
import 'package:orbit_app/features/messages/data/models/message_model.dart';
import 'package:orbit_app/features/messages/data/models/receipt_report_model.dart';
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
  /// For the [SendVariant.fromExcel] variant the request is uploaded as
  /// multipart/form-data with the [excelFile] attached under the `file`
  /// field. For all other variants a regular JSON POST is performed.
  ///
  /// Returns the API response wrapping the created message data.
  Future<ApiResponse<Map<String, dynamic>>> sendMessage(
    SendMessageRequest request, {
    File? excelFile,
  }) async {
    if (request.variant == SendVariant.fromExcel && excelFile != null) {
      final filename = excelFile.path.split(Platform.pathSeparator).last;
      final multipart = await MultipartFile.fromFile(
        excelFile.path,
        filename: filename,
      );
      // Send the JSON shape as flat form fields alongside the file.
      final flatData = <String, dynamic>{};
      request.toJson().forEach((key, value) {
        if (value is List) {
          flatData[key] = value.join(',');
        } else {
          flatData[key] = value;
        }
      });

      final response = await _client.upload(
        ApiConstants.messagesSend,
        file: multipart,
        fileFieldName: 'file',
        data: flatData,
      );
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
      );
    }

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

  // ─── Dynamic Texts (V3) ──────────────────────────────────────────────

  /// Loads the list of variable placeholders supported by the gateway
  /// (e.g. `{student_name}`, `{group}`, `{link}`, `{number_name}`).
  ///
  /// Endpoint: `GET /messages/dynamic-texts`.
  Future<List<DynamicTextModel>> listDynamicTexts() async {
    final response = await _client.get(ApiConstants.messagesDynamicTexts);
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
    );

    final raw = apiResponse.data;
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(DynamicTextModel.fromJson)
          .toList();
    }
    if (raw is Map<String, dynamic>) {
      // Some V3 builds wrap the list under a `texts` or `variables` key.
      final list = (raw['texts'] ?? raw['variables'] ?? raw['data'])
          as List<dynamic>?;
      if (list != null) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(DynamicTextModel.fromJson)
            .toList();
      }
    }
    return const [];
  }

  // ─── AI Generate (V3) ────────────────────────────────────────────────

  /// Calls the server-side text-generation endpoint to improve, shorten,
  /// formalise or expand the provided [text].
  ///
  /// Endpoint: `POST /messages/ai-generate`
  /// Body: `{text, action: improve|shorten|formal|expand}`
  /// Returns the generated text via `data.generated_text`.
  Future<String> aiGenerate({
    required String text,
    required String action,
  }) async {
    final response = await _client.post(
      ApiConstants.messagesAiGenerate,
      data: {
        'text': text,
        'action': action,
      },
    );
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
    );
    final data = apiResponse.data ?? const <String, dynamic>{};
    final generated = (data['generated_text'] as String?)?.trim() ??
        (data['text'] as String?)?.trim() ??
        (data['result'] as String?)?.trim() ??
        '';
    return generated;
  }

  // ─── DLR by Number (V3) ──────────────────────────────────────────────

  /// Fetches the per-message DLR history for a given phone number.
  ///
  /// Endpoint: `POST /messages/dlr-by-number`.
  Future<List<DlrReportEntry>> dlrByNumber(String number) async {
    final response = await _client.post(
      ApiConstants.messagesDlrByNumber,
      data: {'number': number},
    );
    final apiResponse = ApiResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
    );
    final raw = apiResponse.data;
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(DlrReportEntry.fromJson)
          .toList();
    }
    if (raw is Map<String, dynamic>) {
      final list = (raw['messages'] ?? raw['records'] ?? raw['data'])
          as List<dynamic>?;
      if (list != null) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(DlrReportEntry.fromJson)
            .toList();
      }
    }
    return const [];
  }

  // ─── Receipt Report (V3) ─────────────────────────────────────────────

  /// Fetches the comprehensive receipt report for a single sent message.
  ///
  /// Endpoint: `GET /messages/{uuid}/receipt-report`.
  Future<ReceiptReportModel> getReceiptReport(String uuid) async {
    final response =
        await _client.get(ApiConstants.messageReceiptReport(uuid));
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
    );
    return ReceiptReportModel.fromJson(apiResponse.data ?? const {});
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final messagesRemoteDatasourceProvider = Provider<MessagesRemoteDatasource>((ref) {
  final client = ref.watch(apiClientProvider);
  return MessagesRemoteDatasource(client);
});
