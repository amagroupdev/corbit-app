import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/drafts/data/datasources/drafts_remote_datasource.dart';
import 'package:orbit_app/features/drafts/data/models/draft_data_model.dart';
import 'package:orbit_app/features/drafts/data/models/draft_model.dart';
import 'package:orbit_app/features/messages/data/models/message_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Single entry point for the Drafts feature presentation layer.
///
/// Wraps [DraftsRemoteDatasource] and applies the same `_guard` style
/// error mapping used elsewhere in the app: any unexpected exception
/// is normalized to an [ApiException] so the UI only has one type to
/// handle.
class DraftsRepository {
  const DraftsRepository(this._remote);

  final DraftsRemoteDatasource _remote;

  // ─── Save ────────────────────────────────────────────────────────────────

  /// Saves a new draft.
  ///
  /// [messageType] selects the variant; [draftData] carries the payload.
  Future<DraftModel> saveDraft({
    required DraftMessageType messageType,
    required DraftDataModel draftData,
  }) async {
    return _guard(() => _remote.storeDraft(
          messageType: messageType,
          draftData: draftData,
        ));
  }

  /// Convenience: saves a draft directly from a `messages` form state.
  ///
  /// The [SendMessageRequest] from the existing send-message screen is
  /// translated into the closest matching draft variant:
  /// - selected groups → `to_group`
  /// - direct numbers (no groups) → `to_number`
  /// Voice/vip-card variants are not produced from this helper since the
  /// existing send screen does not yet drive those flows.
  Future<DraftModel> saveDraftFromSendRequest(
    SendMessageRequest request, {
    String? scheduleAt,
  }) async {
    final hasGroups = request.groupIds.isNotEmpty;
    final type =
        hasGroups ? DraftMessageType.toGroup : DraftMessageType.toNumber;
    final schedule = request.sendAtOption == SendAtOption.later ? 'later' : 'now';

    final data = DraftDataModel(
      numbers: hasGroups ? const [] : request.numbers,
      groupIds: hasGroups ? request.groupIds : const [],
      numberIds: const [],
      senderId: request.senderId == 0 ? null : request.senderId,
      msgType: 'sms',
      schedule: schedule,
      scheduleAt: schedule == 'later'
          ? (scheduleAt ?? request.sendAt?.toIso8601String())
          : null,
      templateId: request.templateId,
      messageBody: request.messageBody,
    );

    return saveDraft(messageType: type, draftData: data);
  }

  // ─── List ────────────────────────────────────────────────────────────────

  /// Returns a paginated list of drafts.
  Future<PaginatedResponse<DraftModel>> listDrafts({
    int page = 1,
    int perPage = 15,
  }) async {
    return _guard(() => _remote.listDrafts(page: page, perPage: perPage));
  }

  // ─── Show ────────────────────────────────────────────────────────────────

  /// Fetches a single draft by [id].
  Future<DraftModel> getDraft(int id) {
    return _guard(() => _remote.getDraft(id));
  }

  // ─── Update ──────────────────────────────────────────────────────────────

  /// Updates the `draft_data` of an existing draft.
  Future<DraftModel> updateDraft({
    required int id,
    required DraftDataModel draftData,
  }) {
    return _guard(() => _remote.updateDraft(id: id, draftData: draftData));
  }

  // ─── Delete ──────────────────────────────────────────────────────────────

  /// Deletes a draft by [id].
  Future<void> deleteDraft(int id) {
    return _guard(() => _remote.deleteDraft(id));
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Wraps any datasource call so that non-API errors are normalized
  /// to an [ApiException]. Mirrors the pattern used in
  /// `MessagesRepository._guard()`.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

/// Provider exposing the [DraftsRepository].
final draftsRepositoryProvider = Provider<DraftsRepository>((ref) {
  final remote = ref.watch(draftsRemoteDatasourceProvider);
  return DraftsRepository(remote);
});
