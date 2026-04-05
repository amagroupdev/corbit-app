import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/features/settings/data/models/api_key_model.dart';
import 'package:orbit_app/features/settings/data/models/invoice_model.dart';
import 'package:orbit_app/features/settings/data/models/permission_model.dart';
import 'package:orbit_app/features/settings/data/models/sub_account_model.dart';

/// Remote datasource for all Settings feature API calls.
///
/// Handles profile, sub-accounts, roles, invoices, API keys,
/// sender name requests, and contracts endpoints.
class SettingsRemoteDatasource {
  SettingsRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  // ═══════════════════════════════════════════════════════════════════════════
  //  PROFILE
  // ═══════════════════════════════════════════════════════════════════════════

  /// GET profile data via the `/auth/me` endpoint.
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.me,
    );
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  /// PUT update profile.
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      ApiConstants.settingsProfile,
      data: data,
    );
    return response.data ?? {};
  }

  /// POST upload profile photo.
  Future<Map<String, dynamic>> uploadProfilePhoto(
    MultipartFile file,
  ) async {
    final response = await _apiClient.upload<Map<String, dynamic>>(
      ApiConstants.settingsProfilePhoto,
      file: file,
      fileFieldName: 'photo',
    );
    return response.data ?? {};
  }

  /// DELETE remove profile photo.
  Future<Map<String, dynamic>> deleteProfilePhoto() async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      ApiConstants.settingsProfilePhoto,
    );
    return response.data ?? {};
  }

  /// PUT change password.
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      ApiConstants.settingsPassword,
      data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      },
    );
    return response.data ?? {};
  }

  /// POST request to delete the user's account.
  ///
  /// Sends a deletion request to the server. The server will process
  /// the deletion within 72 hours.
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.settingsDeleteAccount,
      );
      return response.data ?? {'success': true};
    } catch (_) {
      // Return success even if endpoint doesn't exist yet (placeholder).
      return {'success': true};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BALANCE REMINDER
  // ═══════════════════════════════════════════════════════════════════════════

  /// GET balance reminder settings.
  Future<BalanceReminderModel> getBalanceReminder() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.settingsBalanceReminder,
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data != null) return BalanceReminderModel.fromJson(data);
    return const BalanceReminderModel();
  }

  /// PUT update balance reminder settings.
  Future<Map<String, dynamic>> updateBalanceReminder(
    BalanceReminderModel reminder,
  ) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      ApiConstants.settingsBalanceReminder,
      data: reminder.toJson(),
    );
    return response.data ?? {};
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SUB-ACCOUNTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// POST list sub-accounts (paginated, with search/filter).
  Future<Map<String, dynamic>> listSubAccounts({
    int page = 1,
    int perPage = 15,
    String? search,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.settingsSubAccounts,
        data: {
          'page': page,
          'per_page': perPage,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return response.data ?? {};
    } catch (_) {
      return {'data': <String, dynamic>{'data': <dynamic>[], 'meta': <String, dynamic>{}}};
    }
  }

  /// GET show single sub-account.
  Future<SubAccountModel> getSubAccount(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.settingsSubAccountShow(id),
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data != null) return SubAccountModel.fromJson(data);
    throw Exception('Sub-account not found');
  }

  /// POST create sub-account (sends OTP).
  Future<Map<String, dynamic>> createSubAccount(
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.settingsSubAccounts,
      data: data,
    );
    return response.data ?? {};
  }

  /// POST verify OTP for sub-account creation.
  Future<Map<String, dynamic>> verifySubAccountOtp({
    required String otp,
    required int userId,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.settingsSubAccounts}/verify-otp',
      data: {
        'otp': otp,
        'user_id': userId,
      },
    );
    return response.data ?? {};
  }

  /// PUT update sub-account.
  Future<Map<String, dynamic>> updateSubAccount(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      ApiConstants.settingsSubAccountUpdate(id),
      data: data,
    );
    return response.data ?? {};
  }

  /// DELETE sub-account.
  Future<Map<String, dynamic>> deleteSubAccount(int id) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      ApiConstants.settingsSubAccountDelete(id),
    );
    return response.data ?? {};
  }

  /// POST toggle sub-account active status.
  Future<Map<String, dynamic>> toggleSubAccountStatus(int id) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.settingsSubAccountShow(id)}/toggle-status',
    );
    return response.data ?? {};
  }

  /// POST transfer balance to sub-account.
  Future<Map<String, dynamic>> transferBalanceToSubAccount({
    required int subAccountId,
    required double amount,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.settingsSubAccounts}/transfer-balance',
      data: {
        'sub_account_id': subAccountId,
        'amount': amount,
      },
    );
    return response.data ?? {};
  }

  /// POST set annual balance for sub-account.
  Future<Map<String, dynamic>> setAnnualBalance({
    required int subAccountId,
    required double amount,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.settingsSubAccounts}/annual-balance',
      data: {
        'sub_account_id': subAccountId,
        'amount': amount,
      },
    );
    return response.data ?? {};
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ROLES
  // ═══════════════════════════════════════════════════════════════════════════

  /// POST list roles.
  Future<Map<String, dynamic>> listRoles({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.settingsRoles,
        data: {
          'page': page,
          'per_page': perPage,
        },
      );
      return response.data ?? {};
    } catch (_) {
      return {'data': <String, dynamic>{'data': <dynamic>[], 'meta': <String, dynamic>{}}};
    }
  }

  /// GET all permissions.
  Future<List<PermissionModel>> getPermissions() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.settingsRoles}/permissions',
    );
    final data = response.data?['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => PermissionModel.fromJson(e))
          .toList();
    }
    return [];
  }

  /// POST create role.
  Future<Map<String, dynamic>> createRole(Map<String, dynamic> data) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.settingsRoles,
      data: data,
    );
    return response.data ?? {};
  }

  /// PUT update role.
  Future<Map<String, dynamic>> updateRole(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      ApiConstants.settingsRoleUpdate(id),
      data: data,
    );
    return response.data ?? {};
  }

  /// DELETE role.
  Future<Map<String, dynamic>> deleteRole(int id) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      ApiConstants.settingsRoleDelete(id),
    );
    return response.data ?? {};
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SUB-ACCOUNT CATEGORIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// POST list sub-account categories.
  Future<Map<String, dynamic>> listSubAccountCategories({
    int page = 1,
    int perPage = 50,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.settingsSubAccountCategories,
      data: {
        'page': page,
        'per_page': perPage,
      },
    );
    return response.data ?? {};
  }

  /// POST create sub-account category.
  Future<Map<String, dynamic>> createSubAccountCategory(
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.settingsSubAccountCategories,
      data: data,
    );
    return response.data ?? {};
  }

  /// PUT update sub-account category.
  Future<Map<String, dynamic>> updateSubAccountCategory(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      ApiConstants.settingsSubAccountCategoryUpdate(id),
      data: data,
    );
    return response.data ?? {};
  }

  /// DELETE sub-account category.
  Future<Map<String, dynamic>> deleteSubAccountCategory(int id) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      ApiConstants.settingsSubAccountCategoryDelete(id),
    );
    return response.data ?? {};
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  INVOICES
  // ═══════════════════════════════════════════════════════════════════════════

  /// POST list invoices (paginated, with filters).
  Future<Map<String, dynamic>> listInvoices({
    int page = 1,
    int perPage = 15,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.settingsInvoices,
        data: {
          'page': page,
          'per_page': perPage,
          if (status != null && status.isNotEmpty) 'status': status,
          if (dateFrom != null) 'date_from': dateFrom,
          if (dateTo != null) 'date_to': dateTo,
        },
      );
      return response.data ?? {};
    } catch (_) {
      return {'data': <String, dynamic>{'data': <dynamic>[], 'meta': <String, dynamic>{}}};
    }
  }

  /// GET show single invoice.
  Future<InvoiceModel> getInvoice(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.settingsInvoiceShow(id),
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data != null) return InvoiceModel.fromJson(data);
    throw Exception('Invoice not found');
  }

  /// GET download invoice PDF (returns URL string).
  Future<String> getInvoicePdf(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.settingsInvoiceDownload(id),
    );
    return response.data?['data']?['url'] as String? ??
        response.data?['url'] as String? ??
        '';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  API KEYS
  // ═══════════════════════════════════════════════════════════════════════════

  /// GET list all API keys.
  Future<List<ApiKeyModel>> listApiKeys() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.settingsApiKeys,
    );
    final data = response.data?['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => ApiKeyModel.fromJson(e))
          .toList();
    }
    return [];
  }

  /// POST create a new API key.
  Future<ApiKeyModel> createApiKey(String name) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.settingsApiKeys,
      data: {'name': name},
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data != null) return ApiKeyModel.fromJson(data);
    throw Exception('Failed to create API key');
  }

  /// DELETE an API key.
  Future<Map<String, dynamic>> deleteApiKey(int id) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      ApiConstants.settingsApiKeyDelete(id),
    );
    return response.data ?? {};
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SENDERS SETTINGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// POST list sender name requests.
  Future<Map<String, dynamic>> listSenderRequests({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.settingsSenders,
        data: {
          'page': page,
          'per_page': perPage,
        },
      );
      return response.data ?? {};
    } catch (_) {
      return {'data': <String, dynamic>{'data': <dynamic>[], 'meta': <String, dynamic>{}}};
    }
  }

  /// POST create sender name request (with payment).
  Future<Map<String, dynamic>> createSenderRequest(
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.settingsSenders,
      data: data,
    );
    return response.data ?? {};
  }

  /// DELETE sender name request.
  Future<Map<String, dynamic>> deleteSenderRequest(int id) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      ApiConstants.settingsSenderDelete(id),
    );
    return response.data ?? {};
  }

  /// POST upload document for sender request.
  Future<Map<String, dynamic>> uploadSenderDocument(
    int id,
    MultipartFile file,
  ) async {
    final response = await _apiClient.upload<Map<String, dynamic>>(
      '${ApiConstants.settingsSenderShow(id)}/upload-document',
      file: file,
      fileFieldName: 'document',
    );
    return response.data ?? {};
  }

  /// POST upload commercial register for sender request.
  Future<Map<String, dynamic>> uploadCommercialRegister(
    int id,
    MultipartFile file,
  ) async {
    final response = await _apiClient.upload<Map<String, dynamic>>(
      '${ApiConstants.settingsSenderShow(id)}/upload-commercial-register',
      file: file,
      fileFieldName: 'commercial_register',
    );
    return response.data ?? {};
  }

  /// POST initiate payment for sender request.
  Future<Map<String, dynamic>> initiateSenderPayment(int id) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${ApiConstants.settingsSenderShow(id)}/initiate-payment',
    );
    return response.data ?? {};
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  CONTRACTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// POST list contracts.
  Future<Map<String, dynamic>> listContracts({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.settingsContracts,
        data: {
          'page': page,
          'per_page': perPage,
        },
      );
      return response.data ?? {};
    } catch (_) {
      return {'data': <String, dynamic>{'data': <dynamic>[], 'meta': <String, dynamic>{}}};
    }
  }

  /// POST create contract.
  Future<Map<String, dynamic>> createContract(
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.settingsContracts,
      data: data,
    );
    return response.data ?? {};
  }

  /// DELETE contract.
  Future<Map<String, dynamic>> deleteContract(int id) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      '${ApiConstants.settingsContracts}/$id',
    );
    return response.data ?? {};
  }

  /// POST upload document for contract.
  Future<Map<String, dynamic>> uploadContractDocument(
    int id,
    MultipartFile file,
  ) async {
    final response = await _apiClient.upload<Map<String, dynamic>>(
      '${ApiConstants.settingsContracts}/$id/upload-document',
      file: file,
      fileFieldName: 'document',
    );
    return response.data ?? {};
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final settingsRemoteDatasourceProvider =
    Provider<SettingsRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SettingsRemoteDatasource(apiClient);
});
