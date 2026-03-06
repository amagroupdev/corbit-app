import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/contact_me/data/models/contact_me_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository for Contact Me feature operations.
class ContactMeRepository {
  const ContactMeRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Fetches the current Contact Me settings.
  Future<ContactMeSettings> getSettings() async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.contactMe}/settings',
      );

      final apiResponse = ApiResponse<ContactMeSettings>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) =>
            ContactMeSettings.fromJson(data as Map<String, dynamic>),
      );

      return apiResponse.data!;
    } on ApiException {
      rethrow;
    }
  }

  /// Updates Contact Me settings.
  Future<ContactMeSettings> updateSettings({
    required bool isEnabled,
    required String rootUrl,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.contactMe}/settings',
        data: {
          'is_enabled': isEnabled,
          'root_url': rootUrl,
        },
      );

      final apiResponse = ApiResponse<ContactMeSettings>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) =>
            ContactMeSettings.fromJson(data as Map<String, dynamic>),
      );

      return apiResponse.data!;
    } on ApiException {
      rethrow;
    }
  }

  /// Checks if the root URL is available.
  Future<bool> checkRoot(String rootUrl) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.contactMe}/check-root',
        data: {'root_url': rootUrl},
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
      );

      return apiResponse.data?['available'] as bool? ?? false;
    } on ApiException {
      rethrow;
    }
  }

  /// Fetches the list of contact reasons.
  Future<List<ContactMeReason>> getReasons() async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.contactMe}/reasons/list',
      );

      final apiResponse = ApiResponse<List<ContactMeReason>>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) => (data as List<dynamic>)
            .map((item) =>
                ContactMeReason.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

      return apiResponse.data ?? [];
    } on ApiException {
      rethrow;
    }
  }

  /// Creates a new contact reason.
  Future<ContactMeReason> createReason(String title) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.contactMe}/reasons',
        data: {'title': title},
      );

      final apiResponse = ApiResponse<ContactMeReason>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) =>
            ContactMeReason.fromJson(data as Map<String, dynamic>),
      );

      return apiResponse.data!;
    } on ApiException {
      rethrow;
    }
  }

  /// Updates a contact reason.
  Future<ContactMeReason> updateReason({
    required int id,
    required String title,
  }) async {
    try {
      final response = await _apiClient.put(
        '${ApiConstants.contactMe}/reasons/$id',
        data: {'title': title},
      );

      final apiResponse = ApiResponse<ContactMeReason>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) =>
            ContactMeReason.fromJson(data as Map<String, dynamic>),
      );

      return apiResponse.data!;
    } on ApiException {
      rethrow;
    }
  }

  /// Deletes a contact reason.
  Future<void> deleteReason(int id) async {
    try {
      await _apiClient.delete(
        '${ApiConstants.contactMe}/reasons/$id',
      );
    } on ApiException {
      rethrow;
    }
  }

  /// Fetches received contact messages.
  Future<PaginatedResponse<ContactMeMessage>> getMessages({
    int page = 1,
    String? search,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.contactMe}/messages',
        data: {
          'page': page,
          'per_page': ApiConstants.defaultPerPage,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final apiResponse =
          ApiResponse<PaginatedResponse<ContactMeMessage>>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: (data) => PaginatedResponse<ContactMeMessage>.fromJson(
          data as Map<String, dynamic>,
          itemFromJson: (item) =>
              ContactMeMessage.fromJson(item as Map<String, dynamic>),
        ),
      );

      return apiResponse.data ?? PaginatedResponse<ContactMeMessage>.empty();
    } on ApiException {
      rethrow;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

final contactMeRepositoryProvider = Provider<ContactMeRepository>((ref) {
  return ContactMeRepository(ref.watch(apiClientProvider));
});
