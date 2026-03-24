import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/statements/data/models/statement_response_model.dart';
import 'package:orbit_app/features/statements/data/repositories/statements_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// STATEMENTS LIST STATE
// ═══════════════════════════════════════════════════════════════════════════════

/// Holds the complete state of a statements list including items, pagination
/// metadata, loading flags, and error state.
class StatementsListState {
  const StatementsListState({
    this.items = const [],
    this.currentPage = 0,
    this.lastPage = 1,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasLoadedOnce = false,
  });

  final List<StatementResponseItem> items;
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

  StatementsListState copyWith({
    List<StatementResponseItem>? items,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    bool? hasLoadedOnce,
  }) {
    return StatementsListState(
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

/// Tracks the currently selected statement tab (StatementType).
final statementsSelectedTabProvider =
    StateProvider<StatementType>((ref) => StatementType.all);

// ═══════════════════════════════════════════════════════════════════════════════
// FILTER PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Holds the current statement filter state.
final statementsFilterProvider = StateProvider<StatementFilter>((ref) {
  return const StatementFilter();
});

// ═══════════════════════════════════════════════════════════════════════════════
// SEARCH QUERY PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Local search query for filtering statement items client-side.
final statementsSearchQueryProvider = StateProvider<String>((ref) => '');

// ═══════════════════════════════════════════════════════════════════════════════
// STATEMENTS LIST NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════════

/// Main controller for the statements list with pagination, refresh, and
/// append-on-scroll support.
class StatementsListNotifier extends StateNotifier<StatementsListState> {
  StatementsListNotifier(this._repository) : super(const StatementsListState());

  final StatementsRepository _repository;

  static const int _perPage = 15;

  /// Fetches the first page of statement responses, replacing any existing data.
  Future<void> fetchStatements({
    required StatementType statementType,
    StatementFilter? filter,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repository.getStatementsList(
        statementType: statementType,
        page: 1,
        perPage: _perPage,
        filter: filter,
      );

      state = StatementsListState(
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
    required StatementType statementType,
    StatementFilter? filter,
  }) async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final result = await _repository.getStatementsList(
        statementType: statementType,
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
    required StatementType statementType,
    StatementFilter? filter,
  }) async {
    await fetchStatements(statementType: statementType, filter: filter);
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
    state = const StatementsListState();
  }
}

/// Provider for [StatementsListNotifier].
final statementsListProvider =
    StateNotifierProvider<StatementsListNotifier, StatementsListState>((ref) {
  final repository = ref.watch(statementsRepositoryProvider);
  return StatementsListNotifier(repository);
});

// ═══════════════════════════════════════════════════════════════════════════════
// STATEMENTS ACTIONS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// State for async statement actions (delete, export).
class StatementsActionState {
  const StatementsActionState({
    this.isDeleting = false,
    this.isExporting = false,
    this.successMessage,
    this.errorMessage,
  });

  final bool isDeleting;
  final bool isExporting;
  final String? successMessage;
  final String? errorMessage;

  bool get isBusy => isDeleting || isExporting;

  StatementsActionState copyWith({
    bool? isDeleting,
    bool? isExporting,
    String? successMessage,
    String? errorMessage,
    bool clearMessages = false,
  }) {
    return StatementsActionState(
      isDeleting: isDeleting ?? this.isDeleting,
      isExporting: isExporting ?? this.isExporting,
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Notifier for statement actions.
class StatementsActionsNotifier extends StateNotifier<StatementsActionState> {
  StatementsActionsNotifier(this._repository) : super(const StatementsActionState());

  final StatementsRepository _repository;

  /// Deletes the specified responses and removes them from the list.
  Future<bool> deleteResponses({
    required List<int> responseIds,
    required StatementsListNotifier listNotifier,
  }) async {
    state = state.copyWith(isDeleting: true, clearMessages: true);

    try {
      final success = await _repository.deleteResponses(
        responseIds: responseIds,
      );

      if (success) {
        listNotifier.removeItemsByIds(responseIds);
        state = state.copyWith(
          isDeleting: false,
          successMessage: 'statement_responses_deleted',
        );
      } else {
        state = state.copyWith(
          isDeleting: false,
          errorMessage: 'statement_responses_delete_failed',
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

  /// Exports statement responses data.
  Future<String?> exportStatements({
    required StatementType statementType,
    StatementFilter? filter,
  }) async {
    state = state.copyWith(isExporting: true, clearMessages: true);

    try {
      final url = await _repository.exportStatements(
        statementType: statementType,
        filter: filter,
      );

      state = state.copyWith(
        isExporting: false,
        successMessage: url ?? 'statement_export_requested',
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

/// Provider for [StatementsActionsNotifier].
final statementsActionsProvider =
    StateNotifierProvider<StatementsActionsNotifier, StatementsActionState>((ref) {
  final repository = ref.watch(statementsRepositoryProvider);
  return StatementsActionsNotifier(repository);
});

// ═══════════════════════════════════════════════════════════════════════════════
// FILTERED ITEMS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Provides the list of statement items filtered by the local search query.
final filteredStatementsItemsProvider = Provider<List<StatementResponseItem>>((ref) {
  final listState = ref.watch(statementsListProvider);
  final searchQuery = ref.watch(statementsSearchQueryProvider).toLowerCase().trim();

  if (searchQuery.isEmpty) return listState.items;

  return listState.items.where((item) {
    return item.name.toLowerCase().contains(searchQuery) ||
        item.phoneNumber.contains(searchQuery) ||
        item.responseText.toLowerCase().contains(searchQuery) ||
        item.senderAccount.toLowerCase().contains(searchQuery);
  }).toList();
});
