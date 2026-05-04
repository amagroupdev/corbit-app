import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/features/voice_messages/data/models/voice_message_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Low-level network access for the voice messages feature.
///
/// Maps directly onto the V3 endpoints:
/// - `POST /voices/upload` (multipart)
/// - `POST /voices/list`
/// - `DELETE /voices/{id}`
class VoiceMessagesRemoteDatasource {
  const VoiceMessagesRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// Uploads a voice file from disk.
  ///
  /// [filePath] is the absolute path to the recorded audio file.
  /// [name] is an optional display name; the server will fall back to
  /// the file name when omitted.
  Future<VoiceMessageModel> upload({
    required String filePath,
    String? name,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final fileName = filePath.split('/').last;
    final multipartFile = await MultipartFile.fromFile(
      filePath,
      filename: fileName,
    );

    final response = await _apiClient.upload(
      ApiConstants.voicesUpload,
      file: multipartFile,
      data: {
        if (name != null && name.isNotEmpty) 'name': name,
      },
      onSendProgress: onSendProgress,
    );

    final apiResponse = ApiResponse<VoiceMessageModel>.fromJson(
      response.data as Map<String, dynamic>,
      fromJsonT: (data) =>
          VoiceMessageModel.fromJson(data as Map<String, dynamic>),
    );

    final value = apiResponse.data;
    if (value == null) {
      throw StateError('voicesUpload returned a null payload.');
    }
    return value;
  }

  /// Returns a paginated list of the user's saved voice messages.
  Future<PaginatedResponse<VoiceMessageModel>> list({
    int perPage = 15,
    String? search,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.voicesList,
      data: {
        'per_page': perPage,
        'search': search,
      },
    );

    final apiResponse =
        ApiResponse<PaginatedResponse<VoiceMessageModel>>.fromJson(
      response.data as Map<String, dynamic>,
      fromJsonT: (data) => PaginatedResponse<VoiceMessageModel>.fromJson(
        data as Map<String, dynamic>,
        itemFromJson: (item) =>
            VoiceMessageModel.fromJson(item as Map<String, dynamic>),
      ),
    );

    return apiResponse.data ?? PaginatedResponse<VoiceMessageModel>.empty();
  }

  /// Deletes a voice message by [id].
  Future<void> delete(int id) async {
    await _apiClient.delete(ApiConstants.voiceDelete(id));
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

final voiceMessagesRemoteDatasourceProvider =
    Provider<VoiceMessagesRemoteDatasource>((ref) {
  return VoiceMessagesRemoteDatasource(ref.watch(apiClientProvider));
});
