import 'dart:async' as async;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/voice_messages/data/datasources/voice_messages_remote_datasource.dart';
import 'package:orbit_app/features/voice_messages/data/models/voice_message_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository for the voice messages feature.
///
/// Wraps [VoiceMessagesRemoteDatasource] with timeout handling and a
/// uniform [ApiException] surface so the controllers don't have to
/// duplicate that boilerplate.
class VoiceMessagesRepository {
  const VoiceMessagesRepository(this._datasource);

  final VoiceMessagesRemoteDatasource _datasource;

  /// Uploads the recorded audio file and returns the persisted record.
  Future<VoiceMessageModel> upload({
    required String filePath,
    String? name,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    return _guard(() => _datasource.upload(
          filePath: filePath,
          name: name,
          onSendProgress: onSendProgress,
        ));
  }

  /// Loads the user's voice messages.
  Future<PaginatedResponse<VoiceMessageModel>> list({
    int perPage = 15,
    String? search,
  }) async {
    return _guard(() => _datasource.list(perPage: perPage, search: search));
  }

  /// Deletes a voice message by [id].
  Future<void> delete(int id) async {
    return _guard(() => _datasource.delete(id));
  }

  /// Wraps [action] with a 30-second timeout and rethrows [ApiException]
  /// while converting [async.TimeoutException]s to a friendly message.
  ///
  /// Note: [async.TimeoutException] is the platform exception thrown by
  /// [Future.timeout]; we alias the import to avoid collision with our
  /// own [TimeoutException] subtype of [ApiException].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(const Duration(seconds: 30));
    } on async.TimeoutException {
      throw const ApiException(message: 'انتهت مهلة الاتصال. حاول مرة أخرى.');
    } on ApiException {
      rethrow;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

final voiceMessagesRepositoryProvider =
    Provider<VoiceMessagesRepository>((ref) {
  return VoiceMessagesRepository(
    ref.watch(voiceMessagesRemoteDatasourceProvider),
  );
});
