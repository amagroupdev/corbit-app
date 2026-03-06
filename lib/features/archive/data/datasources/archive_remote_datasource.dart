import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/features/archive/data/models/archive_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Remote data source for the ORBIT SMS V3 Archive endpoints.
///
/// All archive endpoints use POST with JSON bodies. The server expects
/// a Bearer token in the Authorization header (handled by [ApiClient]).
class ArchiveRemoteDataSource {
  const ArchiveRemoteDataSource(this._client);

  final ApiClient _client;

  // Base path for all v3 archive endpoints.
  static const String _basePath = '/archive';

  // ─── List (paginated) ──────────────────────────────────────────────────

  /// Fetches a paginated list of archived messages for the given [archiveType].
  ///
  /// [page] is 1-indexed. [perPage] defaults to 15.
  /// [filter] adds optional filter criteria (date range, sender, etc.).
  Future<PaginatedResponse<ArchiveItem>> fetchArchiveList({
    required ArchiveType archiveType,
    int page = 1,
    int perPage = 15,
    ArchiveFilter? filter,
  }) async {
    final body = <String, dynamic>{
      'archive_type': archiveType.apiValue,
      'page': page,
      'per_page': perPage,
    };

    if (filter != null && filter.isNotEmpty) {
      body['filters'] = filter.toJson();
    }

    final response = await _client.post(
      '$_basePath/list',
      data: body,
    );

    final json = response.data as Map<String, dynamic>;
    final dataPayload = json['data'] as Map<String, dynamic>? ?? json;

    // API returns {messages: [...], pagination: {...}}.
    // Remap to PaginatedResponse format if needed.
    if (dataPayload.containsKey('messages') && !dataPayload.containsKey('data')) {
      final pagination = dataPayload['pagination'] as Map<String, dynamic>?;
      final remapped = <String, dynamic>{
        'data': dataPayload['messages'],
        ...?pagination,
      };
      return PaginatedResponse<ArchiveItem>.fromJson(
        remapped,
        itemFromJson: (item) =>
            ArchiveItem.fromJson(item as Map<String, dynamic>),
      );
    }

    return PaginatedResponse<ArchiveItem>.fromJson(
      dataPayload,
      itemFromJson: (item) =>
          ArchiveItem.fromJson(item as Map<String, dynamic>),
    );
  }

  // ─── Count ─────────────────────────────────────────────────────────────

  /// Returns the total count of archive messages matching the given criteria.
  Future<ArchiveCountResult> fetchArchiveCount({
    required ArchiveType archiveType,
    ArchiveFilter? filter,
  }) async {
    final body = <String, dynamic>{
      'archive_type': archiveType.apiValue,
    };

    if (filter != null && filter.isNotEmpty) {
      body['filters'] = filter.toJson();
    }

    final response = await _client.post(
      '$_basePath/count',
      data: body,
    );

    final json = response.data as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return ArchiveCountResult.fromJson(data);
  }

  // ─── Delete ────────────────────────────────────────────────────────────

  /// Deletes the archive messages with the given [messageIds].
  Future<Map<String, dynamic>> deleteArchiveMessages({
    required ArchiveType archiveType,
    required List<int> messageIds,
  }) async {
    final response = await _client.post(
      '$_basePath/delete',
      data: {
        'archive_type': archiveType.apiValue,
        'message_ids': messageIds,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  // ─── Export ─────────────────────────────────────────────────────────────

  /// Triggers an export of archived messages matching the filter criteria.
  ///
  /// The server typically returns a download URL or sends the export file
  /// via email.
  Future<Map<String, dynamic>> exportArchive({
    required ArchiveType archiveType,
    ArchiveFilter? filter,
  }) async {
    final body = <String, dynamic>{
      'archive_type': archiveType.apiValue,
    };

    if (filter != null && filter.isNotEmpty) {
      body['filters'] = filter.toJson();
    }

    final response = await _client.post(
      '$_basePath/export',
      data: body,
    );

    return response.data as Map<String, dynamic>;
  }

  // ─── Print ─────────────────────────────────────────────────────────────

  /// Fetches a large page of archive messages for print-friendly rendering.
  ///
  /// Uses `per_page: 1000` as specified by the API.
  Future<PaginatedResponse<ArchiveItem>> fetchArchiveForPrint({
    required ArchiveType archiveType,
    ArchiveFilter? filter,
  }) async {
    final body = <String, dynamic>{
      'archive_type': archiveType.apiValue,
      'per_page': 1000,
    };

    if (filter != null && filter.isNotEmpty) {
      body['filters'] = filter.toJson();
    }

    final response = await _client.post(
      '$_basePath/print',
      data: body,
    );

    final json = response.data as Map<String, dynamic>;
    final dataPayload = json['data'] as Map<String, dynamic>? ?? json;

    return PaginatedResponse<ArchiveItem>.fromJson(
      dataPayload,
      itemFromJson: (item) =>
          ArchiveItem.fromJson(item as Map<String, dynamic>),
    );
  }

  // ─── Cancel Pending ────────────────────────────────────────────────────

  /// Cancels pending (not yet sent) messages in the general archive.
  Future<Map<String, dynamic>> cancelPendingMessages({
    required List<int> messageIds,
  }) async {
    final response = await _client.post(
      '$_basePath/cancel-pending',
      data: {
        'archive_type': 'general',
        'message_ids': messageIds,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  // ─── Add to Archive ────────────────────────────────────────────────────

  /// Adds messages to the general archive.
  Future<Map<String, dynamic>> addToArchive({
    required List<int> messageIds,
  }) async {
    final response = await _client.post(
      '$_basePath/add',
      data: {
        'archive_type': 'general',
        'message_ids': messageIds,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  // ─── Restore ───────────────────────────────────────────────────────────

  /// Restores previously deleted/archived messages back to the active list.
  Future<Map<String, dynamic>> restoreMessages({
    required List<int> messageIds,
  }) async {
    final response = await _client.post(
      '$_basePath/restore',
      data: {
        'archive_type': 'general',
        'message_ids': messageIds,
      },
    );

    return response.data as Map<String, dynamic>;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Riverpod provider for [ArchiveRemoteDataSource].
final archiveRemoteDataSourceProvider =
    Provider<ArchiveRemoteDataSource>((ref) {
  final client = ref.watch(apiClientProvider);
  return ArchiveRemoteDataSource(client);
});
