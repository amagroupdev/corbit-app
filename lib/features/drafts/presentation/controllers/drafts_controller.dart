import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/features/drafts/data/models/draft_model.dart';
import 'package:orbit_app/features/drafts/data/repositories/drafts_repository.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

// ═══════════════════════════════════════════════════════════════════════════
// LIST STATE
// ═══════════════════════════════════════════════════════════════════════════

/// Immutable state for the drafts list screen.
class DraftsListState {
  const DraftsListState({
    this.drafts = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.errorMessage,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
  });

  /// Loaded drafts (across all loaded pages).
  final List<DraftModel> drafts;

  /// Whether the first page is still loading.
  final bool isLoading;

  /// Whether the next page is being appended.
  final bool isLoadingMore;

  /// User-facing error message, or null on success.
  final String? errorMessage;

  /// The most-recently loaded page (1-based).
  final int currentPage;

  /// Total number of pages reported by the server.
  final int lastPage;

  /// Total drafts available on the server.
  final int total;

  /// Whether more pages can be fetched.
  bool get hasMore => currentPage < lastPage;

  DraftsListState copyWith({
    List<DraftModel>? drafts,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    int? currentPage,
    int? lastPage,
    int? total,
    bool clearError = false,
  }) {
    return DraftsListState(
      drafts: drafts ?? this.drafts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LIST CONTROLLER
// ═══════════════════════════════════════════════════════════════════════════

/// Controller that drives the drafts list screen — load, refresh,
/// load-more, optimistic delete.
class DraftsListController extends StateNotifier<DraftsListState> {
  DraftsListController(this._repo) : super(const DraftsListState()) {
    // Load the first page eagerly; UI shows skeleton while we wait.
    refresh();
  }

  final DraftsRepository _repo;

  /// Reloads the first page from scratch.
  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );
    try {
      final page = await _repo.listDrafts(page: 1);
      state = state.copyWith(
        drafts: page.data,
        isLoading: false,
        currentPage: page.currentPage,
        lastPage: page.lastPage,
        total: page.total,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _readError(e),
      );
    }
  }

  /// Loads the next page if available; appends to [drafts].
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page = await _repo.listDrafts(page: state.currentPage + 1);
      state = state.copyWith(
        drafts: [...state.drafts, ...page.data],
        isLoadingMore: false,
        currentPage: page.currentPage,
        lastPage: page.lastPage,
        total: page.total,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: _readError(e),
      );
    }
  }

  /// Removes a draft locally before the server confirms — falls back to
  /// a refresh if the API call fails.
  Future<bool> deleteDraft(int id) async {
    final previous = state.drafts;
    state = state.copyWith(
      drafts: previous.where((d) => d.id != id).toList(),
      total: state.total > 0 ? state.total - 1 : 0,
    );
    try {
      await _repo.deleteDraft(id);
      return true;
    } catch (e) {
      // Restore the previous list on failure so nothing is lost visually.
      state = state.copyWith(
        drafts: previous,
        errorMessage: _readError(e),
      );
      return false;
    }
  }

  /// Inserts a freshly-saved draft at the top of the list (for the
  /// "saved as draft" flow on the send screen).
  void prependDraft(DraftModel draft) {
    state = state.copyWith(
      drafts: [draft, ...state.drafts],
      total: state.total + 1,
    );
  }

  /// Replaces an existing draft with an updated copy.
  void replaceDraft(DraftModel draft) {
    state = state.copyWith(
      drafts: [
        for (final d in state.drafts)
          if (d.id == draft.id) draft else d,
      ],
    );
  }

  String _readError(Object e) => e.toString();
}

/// Provider for the drafts list controller.
final draftsListControllerProvider =
    StateNotifierProvider<DraftsListController, DraftsListState>((ref) {
  return DraftsListController(ref.watch(draftsRepositoryProvider));
});

// ═══════════════════════════════════════════════════════════════════════════
// SINGLE DRAFT PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Loads a single draft by id (for the detail screen).
final draftDetailProvider =
    FutureProvider.autoDispose.family<DraftModel, int>((ref, id) async {
  final repo = ref.watch(draftsRepositoryProvider);
  return repo.getDraft(id);
});

// ═══════════════════════════════════════════════════════════════════════════
// PAGINATED HELPER (for callers that need the raw response)
// ═══════════════════════════════════════════════════════════════════════════

/// Convenience provider that returns the first page directly, useful
/// for non-stateful screens.
final draftsFirstPageProvider =
    FutureProvider.autoDispose<PaginatedResponse<DraftModel>>((ref) async {
  final repo = ref.watch(draftsRepositoryProvider);
  return repo.listDrafts(page: 1);
});
