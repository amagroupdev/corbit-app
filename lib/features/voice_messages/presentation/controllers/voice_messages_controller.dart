import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/voice_messages/data/models/voice_message_model.dart';
import 'package:orbit_app/features/voice_messages/data/repositories/voice_messages_repository.dart';

/// State for the voice messages list screen.
class VoiceMessagesListState {
  const VoiceMessagesListState({
    this.items = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.error,
    this.search = '',
    this.total = 0,
  });

  final List<VoiceMessageModel> items;
  final bool isLoading;
  final bool isUploading;
  final double uploadProgress;
  final String? error;
  final String search;
  final int total;

  bool get isEmpty => items.isEmpty && !isLoading;

  VoiceMessagesListState copyWith({
    List<VoiceMessageModel>? items,
    bool? isLoading,
    bool? isUploading,
    double? uploadProgress,
    String? error,
    bool clearError = false,
    String? search,
    int? total,
  }) {
    return VoiceMessagesListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: clearError ? null : (error ?? this.error),
      search: search ?? this.search,
      total: total ?? this.total,
    );
  }
}

/// Controller responsible for fetching, uploading and deleting voice
/// messages.
class VoiceMessagesController extends StateNotifier<VoiceMessagesListState> {
  VoiceMessagesController(this._repository)
      : super(const VoiceMessagesListState());

  final VoiceMessagesRepository _repository;

  /// Loads the latest list of voice messages from the server.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.list(
        search: state.search.isEmpty ? null : state.search,
      );
      state = state.copyWith(
        items: response.data,
        isLoading: false,
        total: response.total,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'voiceMessagesGenericError',
      );
    }
  }

  /// Updates the search query and reloads.
  Future<void> updateSearch(String query) async {
    state = state.copyWith(search: query);
    await load();
  }

  /// Uploads a recording and prepends it to the list on success.
  ///
  /// Returns the persisted [VoiceMessageModel] on success, otherwise
  /// `null` (the [error] field on state is set in that case).
  Future<VoiceMessageModel?> upload({
    required String filePath,
    String? name,
  }) async {
    state = state.copyWith(
      isUploading: true,
      uploadProgress: 0.0,
      clearError: true,
    );
    try {
      final created = await _repository.upload(
        filePath: filePath,
        name: name,
        onSendProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(uploadProgress: sent / total);
          }
        },
      );
      state = state.copyWith(
        items: [created, ...state.items],
        isUploading: false,
        uploadProgress: 1.0,
        total: state.total + 1,
      );
      return created;
    } on ApiException catch (e) {
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: e.message,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: 'voiceMessagesUploadFailed',
      );
      return null;
    }
  }

  /// Deletes a voice message by [id]. Returns whether the operation
  /// succeeded.
  Future<bool> delete(int id) async {
    try {
      await _repository.delete(id);
      state = state.copyWith(
        items: state.items.where((v) => v.id != id).toList(),
        total: state.total > 0 ? state.total - 1 : 0,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

final voiceMessagesControllerProvider = StateNotifierProvider<
    VoiceMessagesController, VoiceMessagesListState>((ref) {
  return VoiceMessagesController(
    ref.watch(voiceMessagesRepositoryProvider),
  );
});
