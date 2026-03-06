import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/features/groups/data/models/group_model.dart';
import 'package:orbit_app/features/groups/data/models/number_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Remote data source for all group and number API operations.
///
/// Every method maps 1:1 to an API v3 endpoint. Error handling is
/// delegated to the [ApiClient] layer which throws typed [ApiException]s.
class GroupsRemoteDatasource {
  GroupsRemoteDatasource(this._client);

  final ApiClient _client;

  // ─── Groups ──────────────────────────────────────────────────────

  /// POST /api/v3/groups/list
  ///
  /// API returns: `{success, message, data: {groups: [...]}}`
  Future<PaginatedResponse<GroupModel>> listGroups({
    int page = 1,
    int perPage = 15,
    String? search,
    bool includeTrashed = false,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/groups/list',
      data: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
        if (includeTrashed) 'include_trashed': true,
      },
    );

    final body = response.data!;
    final payload = body['data'] as Map<String, dynamic>? ?? body;

    // API returns {groups: [...]} without pagination metadata.
    // Remap to PaginatedResponse format and estimate pagination from count.
    if (payload.containsKey('groups') && !payload.containsKey('data')) {
      final groups = payload['groups'] as List<dynamic>? ?? [];
      final pagination = payload['pagination'] as Map<String, dynamic>?;
      // If API didn't provide pagination, estimate: if we got a full page,
      // there might be more; otherwise this is the last page.
      final hasMore = groups.length >= perPage;
      final remapped = <String, dynamic>{
        'data': groups,
        ...?pagination,
        if (pagination == null) 'current_page': page,
        if (pagination == null) 'per_page': perPage,
        if (pagination == null) 'total': hasMore ? (page * perPage + 1) : ((page - 1) * perPage + groups.length),
        if (pagination == null) 'last_page': hasMore ? page + 1 : page,
      };
      return PaginatedResponse<GroupModel>.fromJson(
        remapped,
        itemFromJson: (item) =>
            GroupModel.fromJson(item as Map<String, dynamic>),
      );
    }

    return PaginatedResponse<GroupModel>.fromJson(
      payload,
      itemFromJson: (item) =>
          GroupModel.fromJson(item as Map<String, dynamic>),
    );
  }

  /// POST /api/v3/groups
  Future<GroupModel> createGroup({required String name}) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/groups',
      data: {'name': name},
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data!,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    return GroupModel.fromJson(apiResponse.data!);
  }

  /// GET /api/v3/groups/{id}
  Future<GroupModel> getGroup(int id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/groups/$id',
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data!,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    return GroupModel.fromJson(apiResponse.data!);
  }

  /// PUT /api/v3/groups/{id}
  Future<GroupModel> updateGroup({
    required int id,
    required String name,
  }) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/groups/$id',
      data: {'name': name},
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data!,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    return GroupModel.fromJson(apiResponse.data!);
  }

  /// DELETE /api/v3/groups/{id} -- soft delete
  Future<void> deleteGroup(int id) async {
    await _client.delete('/groups/$id');
  }

  /// POST /api/v3/groups/{id}/restore
  Future<void> restoreGroup(int id) async {
    await _client.post('/groups/$id/restore');
  }

  // ─── Numbers within a group ──────────────────────────────────────

  /// POST /api/v3/groups/{id}/numbers
  ///
  /// API returns: `{success, message, data: {numbers: [...], pagination: {...}}}`
  /// We remap `numbers` → `data` so PaginatedResponse can parse it.
  Future<PaginatedResponse<NumberModel>> listNumbers({
    required int groupId,
    int page = 1,
    int perPage = 15,
    List<int>? excludedNumbers,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/groups/$groupId/numbers',
      data: {
        'page': page,
        'per_page': perPage,
        if (excludedNumbers != null && excludedNumbers.isNotEmpty)
          'excluded_numbers': excludedNumbers,
      },
    );

    final body = response.data!;
    final payload = body['data'] as Map<String, dynamic>? ?? body;

    // API returns {numbers: [...], pagination: {...}} instead of {data: [...], ...}
    if (payload.containsKey('numbers') && !payload.containsKey('data')) {
      final numbers = payload['numbers'] as List<dynamic>? ?? [];
      final pagination = payload['pagination'] as Map<String, dynamic>?;
      final remapped = <String, dynamic>{
        'data': numbers,
        ...?pagination,
        if (pagination == null) 'current_page': page,
        if (pagination == null) 'per_page': perPage,
        if (pagination == null) 'total': numbers.length,
        if (pagination == null) 'last_page': 1,
      };
      return PaginatedResponse<NumberModel>.fromJson(
        remapped,
        itemFromJson: (item) =>
            NumberModel.fromJson(item as Map<String, dynamic>),
      );
    }

    return PaginatedResponse<NumberModel>.fromJson(
      payload,
      itemFromJson: (item) =>
          NumberModel.fromJson(item as Map<String, dynamic>),
    );
  }

  /// GET /api/v3/groups/{id}/numbers-count
  Future<int> getNumbersCount(int groupId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/groups/$groupId/numbers-count',
    );

    final body = response.data!;
    final data = body['data'];
    if (data is int) return data;
    if (data is Map<String, dynamic>) {
      return data['count'] as int? ?? 0;
    }
    return 0;
  }

  // ─── Import / Export ─────────────────────────────────────────────

  /// POST /api/v3/groups/import-excel -- standard import (max 5000 rows)
  Future<Map<String, dynamic>> importExcel({
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  }) async {
    final file = await MultipartFile.fromFile(filePath, filename: fileName);

    final response = await _client.upload<Map<String, dynamic>>(
      '/groups/import-excel',
      file: file,
      fileFieldName: 'file',
      onSendProgress: onProgress,
    );

    return response.data ?? {};
  }

  /// POST /api/v3/groups/import-custom-excel -- custom column mapping
  ///
  /// API requires: file, phone_column, group_column (all required).
  /// Optional: name_column, identifier_column.
  Future<Map<String, dynamic>> importCustomExcel({
    required String filePath,
    required String fileName,
    required String phoneColumn,
    required String groupColumn,
    String? nameColumn,
    String? identifierColumn,
    void Function(int sent, int total)? onProgress,
  }) async {
    final file = await MultipartFile.fromFile(filePath, filename: fileName);

    final Map<String, dynamic> data = {
      'phone_column': phoneColumn,
      'group_column': groupColumn,
      if (nameColumn != null) 'name_column': nameColumn,
      if (identifierColumn != null) 'identifier_column': identifierColumn,
    };

    final response = await _client.upload<Map<String, dynamic>>(
      '/groups/import-custom-excel',
      file: file,
      fileFieldName: 'file',
      data: data,
      onSendProgress: onProgress,
    );

    return response.data ?? {};
  }

  /// POST /api/v3/groups/export -- export all groups
  Future<Map<String, dynamic>> exportGroups() async {
    final response = await _client.post<Map<String, dynamic>>(
      '/groups/export',
    );
    return response.data ?? {};
  }

  // ─── Individual number CRUD ──────────────────────────────────────

  /// POST /api/v3/numbers/validate
  Future<Map<String, dynamic>> validatePhone(String phone) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/numbers/validate',
      data: {'number': phone},
    );
    return response.data ?? {};
  }

  /// POST /api/v3/numbers
  Future<NumberModel> createNumber({
    required int groupId,
    required String name,
    required String number,
    String? identifier,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/numbers',
      data: {
        'group_id': groupId,
        'name': name,
        'number': number,
        if (identifier != null && identifier.isNotEmpty)
          'identifier': identifier,
      },
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data!,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    return NumberModel.fromJson(apiResponse.data!);
  }

  /// PUT /api/v3/numbers/{id}
  Future<NumberModel> updateNumber({
    required int id,
    String? name,
    String? number,
    String? identifier,
  }) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/numbers/$id',
      data: {
        if (name != null) 'name': name,
        if (number != null) 'number': number,
        if (identifier != null) 'identifier': identifier,
      },
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data!,
      fromJsonT: (data) => data as Map<String, dynamic>,
    );

    return NumberModel.fromJson(apiResponse.data!);
  }

  /// DELETE /api/v3/numbers/{id}
  Future<void> deleteNumber(int id) async {
    await _client.delete('/numbers/$id');
  }
}

// ─── Provider ──────────────────────────────────────────────────────

final groupsRemoteDatasourceProvider =
    Provider<GroupsRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GroupsRemoteDatasource(apiClient);
});
