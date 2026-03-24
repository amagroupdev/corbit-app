import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/archive/data/models/archive_model.dart';
import 'package:orbit_app/features/archive/data/repositories/archive_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ARCHIVE LIST STATE
// ═══════════════════════════════════════════════════════════════════════════════

/// Holds the complete state of an archive list including items, pagination
/// metadata, loading flags, and error state.
class ArchiveListState {
  const ArchiveListState({
    this.items = const [],
    this.currentPage = 0,
    this.lastPage = 1,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasLoadedOnce = false,
  });

  final List<ArchiveItem> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasLoadedOnce;

  bool get hasMore => currentPage < lastPage;
  bool get isEmpty => items.isEmpty && hasLoadedOnce && !isLoading;
  bool get hasError => error != null;

  ArchiveListState copyWith({
    List<ArchiveItem>? items,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    bool? hasLoadedOnce,
  }) {
    return ArchiveListState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SELECTED TAB PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Tracks the currently selected archive tab (ArchiveType).
final archiveSelectedTabProvider =
    StateProvider<ArchiveType>((ref) => ArchiveType.general);

// ═══════════════════════════════════════════════════════════════════════════════
// FILTER PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Holds the current archive filter state.
final archiveFilterProvider = StateProvider<ArchiveFilter>((ref) {
  return const ArchiveFilter();
});

// ═══════════════════════════════════════════════════════════════════════════════
// MULTI-SELECT PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Whether multi-select mode is currently active.
final archiveMultiSelectModeProvider = StateProvider<bool>((ref) => false);

/// Set of currently selected archive item IDs.
final archiveSelectedIdsProvider = StateProvider<Set<int>>((ref) => {});

// ═══════════════════════════════════════════════════════════════════════════════
// SEARCH QUERY PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Local search query for filtering archive items client-side.
final archiveSearchQueryProvider = StateProvider<String>((ref) => '');

// ═══════════════════════════════════════════════════════════════════════════════
// ARCHIVE LIST NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════════

/// Main controller for the archive list with pagination, refresh, and
/// append-on-scroll support.
class ArchiveListNotifier extends StateNotifier<ArchiveListState> {
  ArchiveListNotifier(this._repository) : super(const ArchiveListState());

  final ArchiveRepository _repository;

  static const int _perPage = 15;

  /// Fetches the first page of archive messages, replacing any existing data.
  Future<void> fetchArchive({
    required ArchiveType archiveType,
    ArchiveFilter? filter,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repository.getArchiveList(
        archiveType: archiveType,
        page: 1,
        perPage: _perPage,
        filter: filter,
      );

      state = ArchiveListState(
        items: result.data,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        total: result.total,
        isLoading: false,
        hasLoadedOnce: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        hasLoadedOnce: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        hasLoadedOnce: true,
      );
    }
  }

  /// Loads the next page and appends items to the existing list.
  Future<void> loadMore({
    required ArchiveType archiveType,
    ArchiveFilter? filter,
  }) async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final result = await _repository.getArchiveList(
        archiveType: archiveType,
        page: nextPage,
        perPage: _perPage,
        filter: filter,
      );

      state = state.copyWith(
        items: [...state.items, ...result.data],
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        total: result.total,
        isLoadingMore: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// Refreshes the entire list (pull-to-refresh).
  Future<void> refresh({
    required ArchiveType archiveType,
    ArchiveFilter? filter,
  }) async {
    await fetchArchive(archiveType: archiveType, filter: filter);
  }

  /// Removes items from the local list by their IDs.
  void removeItemsByIds(List<int> ids) {
    final idSet = ids.toSet();
    final updated = state.items.where((item) => !idSet.contains(item.id)).toList();
    state = state.copyWith(
      items: updated,
      total: state.total - (state.items.length - updated.length),
    );
  }

  /// Clears the current list state.
  void clear() {
    state = const ArchiveListState();
  }
}

/// Provider for [ArchiveListNotifier].
final archiveListProvider =
    StateNotifierProvider<ArchiveListNotifier, ArchiveListState>((ref) {
  final repository = ref.watch(archiveRepositoryProvider);
  return ArchiveListNotifier(repository);
});

// ═══════════════════════════════════════════════════════════════════════════════
// ARCHIVE ACTIONS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// State for async archive actions (delete, cancel, restore, export).
class ArchiveActionState {
  const ArchiveActionState({
    this.isDeleting = false,
    this.isCancelling = false,
    this.isRestoring = false,
    this.isExporting = false,
    this.successMessage,
    this.errorMessage,
  });

  final bool isDeleting;
  final bool isCancelling;
  final bool isRestoring;
  final bool isExporting;
  final String? successMessage;
  final String? errorMessage;

  bool get isBusy => isDeleting || isCancelling || isRestoring || isExporting;

  ArchiveActionState copyWith({
    bool? isDeleting,
    bool? isCancelling,
    bool? isRestoring,
    bool? isExporting,
    String? successMessage,
    String? errorMessage,
    bool clearMessages = false,
  }) {
    return ArchiveActionState(
      isDeleting: isDeleting ?? this.isDeleting,
      isCancelling: isCancelling ?? this.isCancelling,
      isRestoring: isRestoring ?? this.isRestoring,
      isExporting: isExporting ?? this.isExporting,
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Notifier for archive bulk actions.
class ArchiveActionsNotifier extends StateNotifier<ArchiveActionState> {
  ArchiveActionsNotifier(this._repository) : super(const ArchiveActionState());

  final ArchiveRepository _repository;

  /// Deletes the specified messages and removes them from the list.
  Future<bool> deleteMessages({
    required ArchiveType archiveType,
    required List<int> messageIds,
    required ArchiveListNotifier listNotifier,
  }) async {
    state = state.copyWith(isDeleting: true, clearMessages: true);

    try {
      final success = await _repository.deleteMessages(
        archiveType: archiveType,
        messageIds: messageIds,
      );

      if (success) {
        listNotifier.removeItemsByIds(messageIds);
        state = state.copyWith(
          isDeleting: false,
          successMessage: 'archive_messages_deleted',
        );
      } else {
        state = state.copyWith(
          isDeleting: false,
          errorMessage: 'archive_delete_failed',
        );
      }

      return success;
    } on ApiException catch (e) {
      state = state.copyWith(
        isDeleting: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isDeleting: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Cancels pending messages.
  Future<bool> cancelPending({
    required List<int> messageIds,
    required ArchiveListNotifier listNotifier,
  }) async {
    state = state.copyWith(isCancelling: true, clearMessages: true);

    try {
      final success = await _repository.cancelPendingMessages(
        messageIds: messageIds,
      );

      if (success) {
        listNotifier.removeItemsByIds(messageIds);
        state = state.copyWith(
          isCancelling: false,
          successMessage: 'archive_cancel_pending_success',
        );
      } else {
        state = state.copyWith(
          isCancelling: false,
          errorMessage: 'archive_cancel_pending_failed',
        );
      }

      return success;
    } on ApiException catch (e) {
      state = state.copyWith(
        isCancelling: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isCancelling: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Restores archived messages.
  Future<bool> restore({
    required List<int> messageIds,
    required ArchiveListNotifier listNotifier,
  }) async {
    state = state.copyWith(isRestoring: true, clearMessages: true);

    try {
      final success = await _repository.restoreMessages(
        messageIds: messageIds,
      );

      if (success) {
        listNotifier.removeItemsByIds(messageIds);
        state = state.copyWith(
          isRestoring: false,
          successMessage: 'archive_messages_restored',
        );
      } else {
        state = state.copyWith(
          isRestoring: false,
          errorMessage: 'archive_restore_failed',
        );
      }

      return success;
    } on ApiException catch (e) {
      state = state.copyWith(
        isRestoring: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isRestoring: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Exports archive data.
  Future<String?> exportArchive({
    required ArchiveType archiveType,
    ArchiveFilter? filter,
  }) async {
    state = state.copyWith(isExporting: true, clearMessages: true);

    try {
      final url = await _repository.exportArchive(
        archiveType: archiveType,
        filter: filter,
      );

      state = state.copyWith(
        isExporting: false,
        successMessage: url ?? 'archive_export_requested',
      );

      return url;
    } on ApiException catch (e) {
      state = state.copyWith(
        isExporting: false,
        errorMessage: e.message,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Clears any success/error messages.
  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}

/// Provider for [ArchiveActionsNotifier].
final archiveActionsProvider =
    StateNotifierProvider<ArchiveActionsNotifier, ArchiveActionState>((ref) {
  final repository = ref.watch(archiveRepositoryProvider);
  return ArchiveActionsNotifier(repository);
});

// ═══════════════════════════════════════════════════════════════════════════════
// FILTERED ITEMS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Provides the list of archive items filtered by the local search query.
final filteredArchiveItemsProvider = Provider<List<ArchiveItem>>((ref) {
  final listState = ref.watch(archiveListProvider);
  final searchQuery = ref.watch(archiveSearchQueryProvider).toLowerCase().trim();

  if (searchQuery.isEmpty) return listState.items;

  return listState.items.where((item) {
    return item.senderName.toLowerCase().contains(searchQuery) ||
        item.recipientNumber.contains(searchQuery) ||
        item.messageBody.toLowerCase().contains(searchQuery) ||
        (item.recipientName?.toLowerCase().contains(searchQuery) ?? false);
  }).toList();
});
