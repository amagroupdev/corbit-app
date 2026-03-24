import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/groups/data/models/group_model.dart';
import 'package:orbit_app/features/groups/data/models/number_model.dart';
import 'package:orbit_app/features/groups/data/repositories/groups_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// STATE CLASSES
// ═══════════════════════════════════════════════════════════════════════

/// State for the groups list screen.
class GroupsListState {
  const GroupsListState({
    this.groups = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.search = '',
    this.includeTrashed = false,
  });

  final List<GroupModel> groups;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int lastPage;
  final int total;
  final String search;
  final bool includeTrashed;

  bool get hasMore => currentPage < lastPage;
  bool get isEmpty => groups.isEmpty && !isLoading;

  GroupsListState copyWith({
    List<GroupModel>? groups,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    int? lastPage,
    int? total,
    String? search,
    bool? includeTrashed,
  }) {
    return GroupsListState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      search: search ?? this.search,
      includeTrashed: includeTrashed ?? this.includeTrashed,
    );
  }
}

/// State for the group detail screen.
class GroupDetailState {
  const GroupDetailState({
    this.group,
    this.numbers = const [],
    this.numbersCount = 0,
    this.isLoading = false,
    this.isLoadingNumbers = false,
    this.isLoadingMoreNumbers = false,
    this.error,
    this.numbersPage = 1,
    this.numbersLastPage = 1,
  });

  final GroupModel? group;
  final List<NumberModel> numbers;
  final int numbersCount;
  final bool isLoading;
  final bool isLoadingNumbers;
  final bool isLoadingMoreNumbers;
  final String? error;
  final int numbersPage;
  final int numbersLastPage;

  bool get hasMoreNumbers => numbersPage < numbersLastPage;

  GroupDetailState copyWith({
    GroupModel? group,
    List<NumberModel>? numbers,
    int? numbersCount,
    bool? isLoading,
    bool? isLoadingNumbers,
    bool? isLoadingMoreNumbers,
    String? error,
    int? numbersPage,
    int? numbersLastPage,
  }) {
    return GroupDetailState(
      group: group ?? this.group,
      numbers: numbers ?? this.numbers,
      numbersCount: numbersCount ?? this.numbersCount,
      isLoading: isLoading ?? this.isLoading,
      isLoadingNumbers: isLoadingNumbers ?? this.isLoadingNumbers,
      isLoadingMoreNumbers: isLoadingMoreNumbers ?? this.isLoadingMoreNumbers,
      error: error,
      numbersPage: numbersPage ?? this.numbersPage,
      numbersLastPage: numbersLastPage ?? this.numbersLastPage,
    );
  }
}

/// State for the import numbers screen.
class ImportState {
  const ImportState({
    this.isUploading = false,
    this.progress = 0.0,
    this.result,
    this.error,
  });

  final bool isUploading;
  final double progress;
  final Map<String, dynamic>? result;
  final String? error;

  bool get isComplete => result != null;

  ImportState copyWith({
    bool? isUploading,
    double? progress,
    Map<String, dynamic>? result,
    String? error,
  }) {
    return ImportState(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      result: result ?? this.result,
      error: error,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GROUPS LIST CONTROLLER
// ═══════════════════════════════════════════════════════════════════════

class GroupsListController extends StateNotifier<GroupsListState> {
  GroupsListController(this._repository) : super(const GroupsListState());

  final GroupsRepository _repository;

  /// Load the first page of groups.
  Future<void> loadGroups() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.listGroups(
        page: 1,
        search: state.search.isNotEmpty ? state.search : null,
        includeTrashed: state.includeTrashed,
      );

      state = state.copyWith(
        groups: response.data,
        isLoading: false,
        currentPage: response.currentPage,
        lastPage: response.lastPage,
        total: response.total,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred.',
      );
    }
  }

  /// Load the next page of groups (infinite scroll).
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final response = await _repository.listGroups(
        page: state.currentPage + 1,
        search: state.search.isNotEmpty ? state.search : null,
        includeTrashed: state.includeTrashed,
      );

      state = state.copyWith(
        groups: [...state.groups, ...response.data],
        isLoadingMore: false,
        currentPage: response.currentPage,
        lastPage: response.lastPage,
        total: response.total,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.message);
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Update the search query and reload.
  Future<void> search(String query) async {
    state = state.copyWith(search: query);
    await loadGroups();
  }

  /// Toggle the include-trashed filter and reload.
  Future<void> toggleTrashed(bool value) async {
    state = state.copyWith(includeTrashed: value);
    await loadGroups();
  }

  /// Delete a group from the list.
  Future<bool> deleteGroup(int id) async {
    try {
      await _repository.deleteGroup(id);
      state = state.copyWith(
        groups: state.groups.where((g) => g.id != id).toList(),
        total: state.total - 1,
      );
      return true;
    } on ApiException {
      return false;
    }
  }

  /// Restore a trashed group.
  Future<bool> restoreGroup(int id) async {
    try {
      await _repository.restoreGroup(id);
      await loadGroups();
      return true;
    } on ApiException {
      return false;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GROUP DETAIL CONTROLLER
// ═══════════════════════════════════════════════════════════════════════

class GroupDetailController extends StateNotifier<GroupDetailState> {
  GroupDetailController(this._repository) : super(const GroupDetailState());

  final GroupsRepository _repository;

  /// Load the group and its numbers.
  Future<void> loadGroup(int groupId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final group = await _repository.getGroup(groupId);
      final count = await _repository.getNumbersCount(groupId);

      state = state.copyWith(
        group: group,
        numbersCount: count,
        isLoading: false,
      );

      await loadNumbers(groupId);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load group details.',
      );
    }
  }

  /// Load numbers for this group.
  Future<void> loadNumbers(int groupId) async {
    state = state.copyWith(isLoadingNumbers: true);

    try {
      final response = await _repository.listNumbers(
        groupId: groupId,
        page: 1,
      );

      state = state.copyWith(
        numbers: response.data,
        isLoadingNumbers: false,
        numbersPage: response.currentPage,
        numbersLastPage: response.lastPage,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoadingNumbers: false, error: e.message);
    } catch (_) {
      state = state.copyWith(isLoadingNumbers: false);
    }
  }

  /// Load more numbers (infinite scroll).
  Future<void> loadMoreNumbers(int groupId) async {
    if (!state.hasMoreNumbers || state.isLoadingMoreNumbers) return;

    state = state.copyWith(isLoadingMoreNumbers: true);

    try {
      final response = await _repository.listNumbers(
        groupId: groupId,
        page: state.numbersPage + 1,
      );

      state = state.copyWith(
        numbers: [...state.numbers, ...response.data],
        isLoadingMoreNumbers: false,
        numbersPage: response.currentPage,
        numbersLastPage: response.lastPage,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMoreNumbers: false);
    }
  }

  /// Update the group name.
  Future<bool> updateGroupName(int groupId, String name) async {
    try {
      final updated = await _repository.updateGroup(id: groupId, name: name);
      state = state.copyWith(group: updated);
      return true;
    } on ApiException {
      return false;
    }
  }

  /// Add a new number to this group.
  Future<bool> addNumber({
    required int groupId,
    required String name,
    required String number,
    String? identifier,
  }) async {
    try {
      final newNumber = await _repository.createNumber(
        groupId: groupId,
        name: name,
        number: number,
        identifier: identifier,
      );

      state = state.copyWith(
        numbers: [newNumber, ...state.numbers],
        numbersCount: state.numbersCount + 1,
      );
      return true;
    } on ApiException {
      return false;
    }
  }

  /// Update an existing number.
  Future<bool> updateNumber({
    required int id,
    String? name,
    String? number,
    String? identifier,
  }) async {
    try {
      final updated = await _repository.updateNumber(
        id: id,
        name: name,
        number: number,
        identifier: identifier,
      );

      state = state.copyWith(
        numbers: state.numbers.map((n) => n.id == id ? updated : n).toList(),
      );
      return true;
    } on ApiException {
      return false;
    }
  }

  /// Add multiple numbers to this group (batch import from contacts).
  /// Returns a map with success/failed/duplicate/total counts.
  Future<Map<String, int>> addNumbersBatch({
    required int groupId,
    required List<Map<String, String>> contacts,
    void Function(int current, int total)? onProgress,
  }) async {
    int success = 0;
    int failed = 0;
    int duplicate = 0;
    final total = contacts.length;

    for (int i = 0; i < contacts.length; i++) {
      final contact = contacts[i];
      try {
        final newNumber = await _repository.createNumber(
          groupId: groupId,
          name: contact['name'] ?? '',
          number: contact['number'] ?? '',
        );

        // Add only the first few to the local state to avoid memory issues
        if (i < 50) {
          state = state.copyWith(
            numbers: [newNumber, ...state.numbers],
            numbersCount: state.numbersCount + 1,
          );
        } else if (i == contacts.length - 1) {
          state = state.copyWith(
            numbersCount: state.numbersCount + 1,
          );
        }

        success++;
      } on ApiException catch (e) {
        // Check if it's a duplicate/validation error (422)
        if (e.statusCode == 422) {
          duplicate++;
        } else {
          failed++;
        }
      } catch (_) {
        failed++;
      }

      onProgress?.call(i + 1, total);
    }

    // Reload numbers if large batch
    if (contacts.length > 50) {
      await loadNumbers(groupId);
      final count = await _repository.getNumbersCount(groupId);
      state = state.copyWith(numbersCount: count);
    }

    return {
      'success': success,
      'failed': failed,
      'duplicate': duplicate,
      'total': total,
    };
  }

  /// Delete a number.
  Future<bool> deleteNumber(int id) async {
    try {
      await _repository.deleteNumber(id);
      state = state.copyWith(
        numbers: state.numbers.where((n) => n.id != id).toList(),
        numbersCount: state.numbersCount - 1,
      );
      return true;
    } on ApiException {
      return false;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// IMPORT CONTROLLER
// ═══════════════════════════════════════════════════════════════════════

class ImportController extends StateNotifier<ImportState> {
  ImportController(this._repository) : super(const ImportState());

  final GroupsRepository _repository;

  /// Standard Excel import.
  Future<void> importStandard({
    required String filePath,
    required String fileName,
  }) async {
    state = state.copyWith(isUploading: true, progress: 0, error: null);

    try {
      final result = await _repository.importExcel(
        filePath: filePath,
        fileName: fileName,
        onProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(progress: sent / total);
          }
        },
      );

      state = state.copyWith(isUploading: false, progress: 1.0, result: result);
    } on ApiException catch (e) {
      state = state.copyWith(isUploading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: 'Upload failed. Please try again.',
      );
    }
  }

  /// Custom Excel import with column mapping.
  Future<void> importCustom({
    required String filePath,
    required String fileName,
    required String phoneColumn,
    required String groupColumn,
    String? nameColumn,
    String? identifierColumn,
  }) async {
    state = state.copyWith(isUploading: true, progress: 0, error: null);

    try {
      final result = await _repository.importCustomExcel(
        filePath: filePath,
        fileName: fileName,
        phoneColumn: phoneColumn,
        groupColumn: groupColumn,
        nameColumn: nameColumn,
        identifierColumn: identifierColumn,
        onProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(progress: sent / total);
          }
        },
      );

      state = state.copyWith(isUploading: false, progress: 1.0, result: result);
    } on ApiException catch (e) {
      state = state.copyWith(isUploading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: 'Upload failed. Please try again.',
      );
    }
  }

  /// Custom import for contacts - returns the result map directly.
  Future<Map<String, dynamic>> importCustomForContacts({
    required String filePath,
    required String fileName,
    required String phoneColumn,
    required String groupColumn,
    String? nameColumn,
  }) async {
    state = state.copyWith(isUploading: true, progress: 0, error: null);

    try {
      final result = await _repository.importCustomExcel(
        filePath: filePath,
        fileName: fileName,
        phoneColumn: phoneColumn,
        groupColumn: groupColumn,
        nameColumn: nameColumn,
        onProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(progress: sent / total);
          }
        },
      );

      state = state.copyWith(isUploading: false, progress: 1.0, result: result);
      return result;
    } on ApiException catch (e) {
      state = state.copyWith(isUploading: false, error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: 'Upload failed. Please try again.',
      );
      rethrow;
    }
  }

  /// Reset the import state for a new import.
  void reset() {
    state = const ImportState();
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provider for the groups list controller.
final groupsListControllerProvider =
    StateNotifierProvider<GroupsListController, GroupsListState>((ref) {
  final repository = ref.watch(groupsRepositoryProvider);
  return GroupsListController(repository);
});

/// Provider for the group detail controller.
final groupDetailControllerProvider =
    StateNotifierProvider<GroupDetailController, GroupDetailState>((ref) {
  final repository = ref.watch(groupsRepositoryProvider);
  return GroupDetailController(repository);
});

/// Provider for the import controller.
final importControllerProvider =
    StateNotifierProvider<ImportController, ImportState>((ref) {
  final repository = ref.watch(groupsRepositoryProvider);
  return ImportController(repository);
});

/// Provider for creating a group (simple async action).
final createGroupProvider =
    FutureProvider.autoDispose.family<GroupModel, String>((ref, name) async {
  final repository = ref.watch(groupsRepositoryProvider);
  return repository.createGroup(name: name);
});

/// Provider for exporting groups.
final exportGroupsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(groupsRepositoryProvider);
  return repository.exportGroups();
});
