import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/features/drafts/data/models/draft_data_model.dart';
import 'package:orbit_app/features/drafts/data/models/draft_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Remote datasource for the V3 Drafts feature.
///
/// Endpoints used (constants live in [ApiConstants]):
/// - `POST /messages/drafts/store`  — creates a draft (4 variants)
/// - `POST /messages/drafts/list`   — paginated listing
/// - `GET  /messages/drafts/{id}`   — fetch one
/// - `PUT  /messages/drafts/{id}`   — partial update of `draft_data`
/// - `DELETE /messages/drafts/{id}` — delete
///
/// All calls go through the shared [ApiClient] which already handles
/// authentication, language headers, and converting `DioException`
/// into `ApiException`.
class DraftsRemoteDatasource {
  const DraftsRemoteDatasource(this._client);

  final ApiClient _client;

  // ─── Store ───────────────────────────────────────────────────────────────

  /// Saves a new draft. The server returns the created draft id and shape.
  ///
  /// [messageType] selects the variant (`to_number`, `to_group`, `voice`,
  /// `vip_card`). [draftData] carries the variant-specific payload.
  Future<DraftModel> storeDraft({
    required DraftMessageType messageType,
    required DraftDataModel draftData,
  }) async {
    final response = await _client.post(
      ApiConstants.messageDraftsStore,
      data: {
        'message_type': messageType.value,
        'draft_data': draftData.toJson(),
      },
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
    );

    final payload = apiResponse.data ?? <String, dynamic>{};
    // Some servers wrap the draft inside `data.draft`; fall back gracefully.
    final draftJson = (payload['draft'] is Map)
        ? Map<String, dynamic>.from(payload['draft'] as Map)
        : payload;

    return DraftModel.fromJson(draftJson);
  }

  // ─── List ────────────────────────────────────────────────────────────────

  /// Returns a paginated list of drafts.
  ///
  /// The server expects `POST /messages/drafts/list` with body
  /// `{ "page": <int>, "per_page": <int> }` and responds with the
  /// standard envelope wrapping `{ data, current_page, last_page, ... }`.
  Future<PaginatedResponse<DraftModel>> listDrafts({
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await _client.post(
      ApiConstants.messageDraftsList,
      data: {
        'page': page,
        'per_page': perPage,
      },
    );

    final json = response.data as Map<String, dynamic>;
    final dataPayload = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    // Some servers nest the page metadata under `pagination`. Re-map so
    // PaginatedResponse.fromJson can read it directly.
    Map<String, dynamic> remapped;
    if (dataPayload.containsKey('pagination') &&
        dataPayload['pagination'] is Map) {
      remapped = <String, dynamic>{
        'data': dataPayload['data'] ?? dataPayload['drafts'] ?? const [],
        ...(dataPayload['pagination'] as Map).cast<String, dynamic>(),
      };
    } else if (dataPayload.containsKey('drafts') &&
        !dataPayload.containsKey('data')) {
      remapped = <String, dynamic>{
        ...dataPayload,
        'data': dataPayload['drafts'],
      };
    } else {
      remapped = dataPayload;
    }

    return PaginatedResponse<DraftModel>.fromJson(
      remapped,
      itemFromJson: (item) =>
          DraftModel.fromJson(item as Map<String, dynamic>),
    );
  }

  // ─── Show ────────────────────────────────────────────────────────────────

  /// Fetches a single draft by id.
  Future<DraftModel> getDraft(int id) async {
    final response = await _client.get(ApiConstants.messageDraftShow(id));
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
    );
    final payload = apiResponse.data ?? <String, dynamic>{};
    final draftJson = (payload['draft'] is Map)
        ? Map<String, dynamic>.from(payload['draft'] as Map)
        : payload;
    return DraftModel.fromJson(draftJson);
  }

  // ─── Update ──────────────────────────────────────────────────────────────

  /// Partial update of an existing draft's `draft_data`.
  ///
  /// The V3 contract is `PUT /messages/drafts/{id}` with body
  /// `{ "draft_data": { ... } }`. The server replaces the stored
  /// `draft_data` with the supplied object.
  Future<DraftModel> updateDraft({
    required int id,
    required DraftDataModel draftData,
  }) async {
    final response = await _client.put(
      ApiConstants.messageDraftUpdate(id),
      data: {
        'draft_data': draftData.toJson(),
      },
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
    );
    final payload = apiResponse.data ?? <String, dynamic>{};
    final draftJson = (payload['draft'] is Map)
        ? Map<String, dynamic>.from(payload['draft'] as Map)
        : payload;
    return DraftModel.fromJson(draftJson);
  }

  // ─── Delete ──────────────────────────────────────────────────────────────

  /// Deletes a draft by id.
  Future<void> deleteDraft(int id) async {
    await _client.delete(ApiConstants.messageDraftDelete(id));
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

/// Provider exposing a configured [DraftsRemoteDatasource].
final draftsRemoteDatasourceProvider =
    Provider<DraftsRemoteDatasource>((ref) {
  final client = ref.watch(apiClientProvider);
  return DraftsRemoteDatasource(client);
});
