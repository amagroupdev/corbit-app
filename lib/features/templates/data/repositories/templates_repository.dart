import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/messages/data/models/template_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository for managing SMS message templates.
///
/// Handles CRUD operations for templates through the ORBIT SMS V3 API.
class TemplatesRepository {
  const TemplatesRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Fetches a paginated list of templates.
  ///
  /// [page] is the page number (1-indexed).
  /// [search] is an optional search query to filter templates by name/body.
  Future<PaginatedResponse<TemplateModel>> getTemplates({
    int page = 1,
    String? search,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.templates}/list',
        data: {
          'page': page,
          'per_page': ApiConstants.defaultPerPage,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final apiResponse = ApiResponse<PaginatedResponse<TemplateModel>>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) => PaginatedResponse<TemplateModel>.fromJson(
          data as Map<String, dynamic>,
          itemFromJson: (item) =>
              TemplateModel.fromJson(item as Map<String, dynamic>),
        ),
      );

      return apiResponse.data ?? PaginatedResponse<TemplateModel>.empty();
    } on ApiException {
      rethrow;
    }
  }

  /// Fetches a single template by [id].
  Future<TemplateModel> getTemplate(int id) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.templateShow(id),
      );

      final apiResponse = ApiResponse<TemplateModel>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) =>
            TemplateModel.fromJson(data as Map<String, dynamic>),
      );

      return apiResponse.data!;
    } on ApiException {
      rethrow;
    }
  }

  /// Creates a new template.
  ///
  /// Returns the newly created [TemplateModel].
  Future<TemplateModel> createTemplate({
    required String name,
    required String body,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.templates,
        data: {
          'name': name,
          'template': body,
        },
      );

      final apiResponse = ApiResponse<TemplateModel>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) =>
            TemplateModel.fromJson(data as Map<String, dynamic>),
      );

      return apiResponse.data!;
    } on ApiException {
      rethrow;
    }
  }

  /// Updates an existing template.
  ///
  /// Returns the updated [TemplateModel].
  Future<TemplateModel> updateTemplate({
    required int id,
    required String name,
    required String body,
  }) async {
    try {
      final response = await _apiClient.put(
        ApiConstants.templateUpdate(id),
        data: {
          'name': name,
          'template': body,
        },
      );

      final apiResponse = ApiResponse<TemplateModel>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) =>
            TemplateModel.fromJson(data as Map<String, dynamic>),
      );

      return apiResponse.data!;
    } on ApiException {
      rethrow;
    }
  }

  /// Deletes a template by [id].
  Future<void> deleteTemplate(int id) async {
    try {
      await _apiClient.delete(
        ApiConstants.templateDelete(id),
      );
    } on ApiException {
      rethrow;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

final templatesRepositoryProvider = Provider<TemplatesRepository>((ref) {
  return TemplatesRepository(ref.watch(apiClientProvider));
});

/// Provider for the paginated templates list.
///
/// Accepts a record of (page, search) as family parameter.
final templatesListProvider = FutureProvider.family<
    PaginatedResponse<TemplateModel>, ({int page, String? search})>(
  (ref, params) {
    final repository = ref.watch(templatesRepositoryProvider);
    return repository.getTemplates(
      page: params.page,
      search: params.search,
    );
  },
);
