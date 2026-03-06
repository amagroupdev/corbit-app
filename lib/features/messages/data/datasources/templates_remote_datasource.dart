import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/features/messages/data/models/template_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';

/// Remote data source for message template CRUD operations.
class TemplatesRemoteDatasource {
  const TemplatesRemoteDatasource(this._client);

  final ApiClient _client;

  // ─── List ────────────────────────────────────────────────────────────

  /// Returns all templates belonging to the current user.
  ///
  /// Uses POST /templates/list which returns:
  /// `{success, message, data: {data: [{id, name, template}], pagination: {...}}}`
  Future<List<TemplateModel>> listTemplates() async {
    try {
      final response = await _client.post(
        '${ApiConstants.templates}/list',
        data: {'page': 1, 'per_page': 100},
      );

      final json = response.data as Map<String, dynamic>;
      final data = json['data'];

      List<dynamic> rawList;
      if (data is Map<String, dynamic>) {
        // Paginated: {data: [...], pagination: {...}}
        rawList = data['data'] as List<dynamic>? ?? [];
      } else if (data is List) {
        rawList = data;
      } else {
        rawList = [];
      }

      return rawList
          .map((item) => TemplateModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Get Single ──────────────────────────────────────────────────────

  /// Fetches a single template by its [id].
  Future<TemplateModel> getTemplate(int id) async {
    final response = await _client.get(ApiConstants.templateShow(id));
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
    );
    return TemplateModel.fromJson(apiResponse.data ?? {});
  }

  // ─── Create ──────────────────────────────────────────────────────────

  /// Creates a new template and returns the created model.
  Future<TemplateModel> createTemplate({
    required String name,
    required String body,
  }) async {
    final response = await _client.post(
      ApiConstants.templates,
      data: {'name': name, 'template': body},
    );
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
    );
    return TemplateModel.fromJson(apiResponse.data ?? {});
  }

  // ─── Update ──────────────────────────────────────────────────────────

  /// Updates an existing template and returns the updated model.
  Future<TemplateModel> updateTemplate({
    required int id,
    required String name,
    required String body,
  }) async {
    final response = await _client.put(
      ApiConstants.templateUpdate(id),
      data: {'name': name, 'template': body},
    );
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
    );
    return TemplateModel.fromJson(apiResponse.data ?? {});
  }

  // ─── Delete ──────────────────────────────────────────────────────────

  /// Deletes a template by its [id].
  Future<void> deleteTemplate(int id) async {
    await _client.delete(ApiConstants.templateDelete(id));
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final templatesRemoteDatasourceProvider = Provider<TemplatesRemoteDatasource>((ref) {
  final client = ref.watch(apiClientProvider);
  return TemplatesRemoteDatasource(client);
});
