import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/features/drafts/data/models/draft_data_model.dart';
import 'package:orbit_app/features/drafts/data/models/draft_model.dart';
import 'package:orbit_app/features/drafts/data/repositories/drafts_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
// FORM STATE
// ═══════════════════════════════════════════════════════════════════════════

/// Editing state for a single draft on the detail screen.
///
/// Wraps the underlying [DraftDataModel] together with the original draft id
/// (so the form can call PUT) and basic save/load flags.
class DraftFormState {
  const DraftFormState({
    this.draftId,
    this.messageType = DraftMessageType.toNumber,
    this.draftData = const DraftDataModel(),
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.savedAt,
  });

  /// Database id, set after the draft is loaded.
  final int? draftId;

  /// Variant of the draft (locked once loaded — a draft cannot
  /// switch type from the detail screen).
  final DraftMessageType messageType;

  /// Editable payload.
  final DraftDataModel draftData;

  /// Whether the initial fetch is in progress.
  final bool isLoading;

  /// Whether a save (PUT) is in flight.
  final bool isSaving;

  /// Last error message from a load or save call.
  final String? errorMessage;

  /// Timestamp of the most recent successful save (for "saved" toast).
  final DateTime? savedAt;

  DraftFormState copyWith({
    int? draftId,
    DraftMessageType? messageType,
    DraftDataModel? draftData,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    DateTime? savedAt,
    bool clearError = false,
  }) {
    return DraftFormState(
      draftId: draftId ?? this.draftId,
      messageType: messageType ?? this.messageType,
      draftData: draftData ?? this.draftData,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedAt: savedAt ?? this.savedAt,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FORM CONTROLLER
// ═══════════════════════════════════════════════════════════════════════════

/// Controller for the draft detail / edit screen.
///
/// Exposes mutators for the editable fields plus [load] and [save].
class DraftFormController extends StateNotifier<DraftFormState> {
  DraftFormController(this._repo) : super(const DraftFormState());

  final DraftsRepository _repo;

  /// Loads a draft from the server and seeds the form state.
  Future<void> load(int id) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );
    try {
      final draft = await _repo.getDraft(id);
      state = state.copyWith(
        draftId: draft.id,
        messageType: draft.messageType,
        draftData: draft.draftData,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Updates the message body.
  void setMessageBody(String body) {
    state = state.copyWith(
      draftData: state.draftData.copyWith(messageBody: body),
    );
  }

  /// Updates the active sender id.
  void setSenderId(int? id) {
    state = state.copyWith(
      draftData: id == null
          ? state.draftData.copyWith(clearSenderId: true)
          : state.draftData.copyWith(senderId: id),
    );
  }

  /// Replaces the list of direct numbers.
  void setNumbers(List<String> numbers) {
    state = state.copyWith(
      draftData: state.draftData.copyWith(numbers: numbers),
    );
  }

  /// Replaces the list of selected groups.
  void setGroupIds(List<int> ids) {
    state = state.copyWith(
      draftData: state.draftData.copyWith(groupIds: ids),
    );
  }

  /// Replaces the list of individual number ids.
  void setNumberIds(List<int> ids) {
    state = state.copyWith(
      draftData: state.draftData.copyWith(numberIds: ids),
    );
  }

  /// Updates the schedule literal (`now` / `later`) and optional ISO time.
  void setSchedule(String schedule, {String? scheduleAt}) {
    state = state.copyWith(
      draftData: state.draftData.copyWith(
        schedule: schedule,
        scheduleAt: scheduleAt,
        clearScheduleAt: schedule == 'now',
      ),
    );
  }

  /// Persists the current state to the server (PUT). Returns the new model
  /// on success, or `null` if no draft id is loaded.
  Future<DraftModel?> save() async {
    final id = state.draftId;
    if (id == null) return null;

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _repo.updateDraft(
        id: id,
        draftData: state.draftData,
      );
      state = state.copyWith(
        isSaving: false,
        draftData: updated.draftData,
        messageType: updated.messageType,
        savedAt: DateTime.now(),
      );
      return updated;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }
}

/// Provider for the draft form controller.
final draftFormControllerProvider =
    StateNotifierProvider.autoDispose<DraftFormController, DraftFormState>(
  (ref) => DraftFormController(ref.watch(draftsRepositoryProvider)),
);
