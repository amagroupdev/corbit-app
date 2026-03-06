import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/features/groups/data/datasources/groups_remote_datasource.dart';
import 'package:orbit_app/features/groups/data/models/group_model.dart';
import 'package:orbit_app/features/groups/data/models/number_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository that wraps [GroupsRemoteDatasource] to provide a clean
/// interface for the presentation layer.
///
/// If caching or offline support is needed in the future, this is the
/// layer to add it without touching the UI or datasource.
class GroupsRepository {
  GroupsRepository(this._datasource);

  final GroupsRemoteDatasource _datasource;

  // ─── Groups ──────────────────────────────────────────────────────

  Future<PaginatedResponse<GroupModel>> listGroups({
    int page = 1,
    int perPage = 15,
    String? search,
    bool includeTrashed = false,
  }) {
    return _datasource.listGroups(
      page: page,
      perPage: perPage,
      search: search,
      includeTrashed: includeTrashed,
    );
  }

  Future<GroupModel> createGroup({required String name}) {
    return _datasource.createGroup(name: name);
  }

  Future<GroupModel> getGroup(int id) {
    return _datasource.getGroup(id);
  }

  Future<GroupModel> updateGroup({
    required int id,
    required String name,
  }) {
    return _datasource.updateGroup(id: id, name: name);
  }

  Future<void> deleteGroup(int id) {
    return _datasource.deleteGroup(id);
  }

  Future<void> restoreGroup(int id) {
    return _datasource.restoreGroup(id);
  }

  // ─── Numbers ─────────────────────────────────────────────────────

  Future<PaginatedResponse<NumberModel>> listNumbers({
    required int groupId,
    int page = 1,
    int perPage = 15,
    List<int>? excludedNumbers,
  }) {
    return _datasource.listNumbers(
      groupId: groupId,
      page: page,
      perPage: perPage,
      excludedNumbers: excludedNumbers,
    );
  }

  Future<int> getNumbersCount(int groupId) {
    return _datasource.getNumbersCount(groupId);
  }

  // ─── Import / Export ─────────────────────────────────────────────

  Future<Map<String, dynamic>> importExcel({
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  }) {
    return _datasource.importExcel(
      filePath: filePath,
      fileName: fileName,
      onProgress: onProgress,
    );
  }

  Future<Map<String, dynamic>> importCustomExcel({
    required String filePath,
    required String fileName,
    required String phoneColumn,
    required String groupColumn,
    String? nameColumn,
    String? identifierColumn,
    void Function(int sent, int total)? onProgress,
  }) {
    return _datasource.importCustomExcel(
      filePath: filePath,
      fileName: fileName,
      phoneColumn: phoneColumn,
      groupColumn: groupColumn,
      nameColumn: nameColumn,
      identifierColumn: identifierColumn,
      onProgress: onProgress,
    );
  }

  Future<Map<String, dynamic>> exportGroups() {
    return _datasource.exportGroups();
  }

  // ─── Number CRUD ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> validatePhone(String phone) {
    return _datasource.validatePhone(phone);
  }

  Future<NumberModel> createNumber({
    required int groupId,
    required String name,
    required String number,
    String? identifier,
  }) {
    return _datasource.createNumber(
      groupId: groupId,
      name: name,
      number: number,
      identifier: identifier,
    );
  }

  Future<NumberModel> updateNumber({
    required int id,
    String? name,
    String? number,
    String? identifier,
  }) {
    return _datasource.updateNumber(
      id: id,
      name: name,
      number: number,
      identifier: identifier,
    );
  }

  Future<void> deleteNumber(int id) {
    return _datasource.deleteNumber(id);
  }
}

// ─── Provider ──────────────────────────────────────────────────────

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  final datasource = ref.watch(groupsRemoteDatasourceProvider);
  return GroupsRepository(datasource);
});
