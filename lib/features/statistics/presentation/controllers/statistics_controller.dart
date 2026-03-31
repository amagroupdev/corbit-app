import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/core/storage/secure_storage.dart';
import 'package:orbit_app/features/statistics/data/models/statistics_model.dart';
import 'package:orbit_app/features/statistics/data/repositories/statistics_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// STATISTICS LIST STATE
// ═══════════════════════════════════════════════════════════════════════════════

/// Complete state of the statistics list: items, pagination, loading, errors.
class StatisticsListState {
  const StatisticsListState({
    this.items = const [],
    this.currentPage = 0,
    this.lastPage = 1,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasLoadedOnce = false,
  });

  final List<StatisticsItem> items;
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

  StatisticsListState copyWith({
    List<StatisticsItem>? items,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    bool? hasLoadedOnce,
  }) {
    return StatisticsListState(
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
// TAB & FILTER PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Tracks the currently selected statistics tab.
final statisticsSelectedTabProvider =
    StateProvider<StatisticsType>((ref) => StatisticsType.absenceLateness);

/// Holds the current statistics filter state.
final statisticsFilterProvider = StateProvider<StatisticsFilter>((ref) {
  return const StatisticsFilter();
});

/// Tracks the selected sub-type for the current statistics type.
final statisticsSubTypeProvider = StateProvider<String>((ref) => 'all');

/// Tracks whether export is in progress.
final statisticsExportingProvider = StateProvider<bool>((ref) => false);

// ═══════════════════════════════════════════════════════════════════════════════
// STATISTICS LIST NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════════

/// Main controller for the statistics list with pagination.
class StatisticsListNotifier extends StateNotifier<StatisticsListState> {
  StatisticsListNotifier(this._repository, this._storage) : super(const StatisticsListState());

  final StatisticsRepository _repository;
  final SecureStorageService _storage;

  static const int _perPage = 15;

  /// Fetches the first page, replacing existing data.
  Future<void> fetchStatistics({
    required StatisticsType statisticsType,
    StatisticsFilter? filter,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    if (await _storage.isGuestMode()) {
      state = const StatisticsListState(
        items: [],
        currentPage: 1,
        lastPage: 1,
        total: 0,
        isLoading: false,
        hasLoadedOnce: true,
      );
      return;
    }

    try {
      final result = await _repository.getStatisticsList(
        statisticsType: statisticsType,
        page: 1,
        perPage: _perPage,
        filter: filter,
      );

      state = StatisticsListState(
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

  /// Loads the next page and appends items.
  Future<void> loadMore({
    required StatisticsType statisticsType,
    StatisticsFilter? filter,
  }) async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final result = await _repository.getStatisticsList(
        statisticsType: statisticsType,
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

  /// Refreshes the entire list.
  Future<void> refresh({
    required StatisticsType statisticsType,
    StatisticsFilter? filter,
  }) async {
    await fetchStatistics(statisticsType: statisticsType, filter: filter);
  }

  /// Clears the list state.
  void clear() {
    state = const StatisticsListState();
  }
}

/// Provider for [StatisticsListNotifier].
final statisticsListProvider =
    StateNotifierProvider<StatisticsListNotifier, StatisticsListState>((ref) {
  final repository = ref.watch(statisticsRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  return StatisticsListNotifier(repository, storage);
});

// ═══════════════════════════════════════════════════════════════════════════════
// EXPORT ACTION PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Handles statistics export actions.
class StatisticsExportNotifier extends StateNotifier<AsyncValue<String?>> {
  StatisticsExportNotifier(this._repository)
      : super(const AsyncValue.data(null));

  final StatisticsRepository _repository;

  /// Triggers an export and returns the download URL or message.
  Future<String?> exportStatistics({
    required StatisticsType statisticsType,
    StatisticsFilter? filter,
  }) async {
    state = const AsyncValue.loading();

    try {
      final result = await _repository.exportStatistics(
        statisticsType: statisticsType,
        filter: filter,
      );

      state = AsyncValue.data(result);
      return result;
    } on ApiException catch (e, stack) {
      state = AsyncValue.error(e.message, stack);
      return null;
    } catch (e, stack) {
      state = AsyncValue.error(e.toString(), stack);
      return null;
    }
  }

  /// Fetches the download URL for a previously triggered export.
  Future<String?> getDownloadUrl({
    required StatisticsType statisticsType,
  }) async {
    state = const AsyncValue.loading();

    try {
      final url = await _repository.getExportDownloadUrl(
        statisticsType: statisticsType,
      );

      state = AsyncValue.data(url);
      return url;
    } on ApiException catch (e, stack) {
      state = AsyncValue.error(e.message, stack);
      return null;
    } catch (e, stack) {
      state = AsyncValue.error(e.toString(), stack);
      return null;
    }
  }
}

/// Provider for [StatisticsExportNotifier].
final statisticsExportProvider =
    StateNotifierProvider<StatisticsExportNotifier, AsyncValue<String?>>((ref) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return StatisticsExportNotifier(repository);
});
