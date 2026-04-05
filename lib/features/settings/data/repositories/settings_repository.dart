import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:orbit_app/features/settings/data/models/api_key_model.dart';
import 'package:orbit_app/features/settings/data/models/contract_model.dart';
import 'package:orbit_app/features/settings/data/models/invoice_model.dart';
import 'package:orbit_app/features/settings/data/models/permission_model.dart';
import 'package:orbit_app/features/settings/data/models/role_model.dart';
import 'package:orbit_app/features/settings/data/models/sender_request_model.dart';
import 'package:orbit_app/features/settings/data/models/sub_account_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository that wraps [SettingsRemoteDatasource] and provides
/// strongly-typed access to all Settings feature operations.
class SettingsRepository {
  SettingsRepository(this._datasource);

  final SettingsRemoteDatasource _datasource;

  // ═══════════════════════════════════════════════════════════════════════════
  //  PROFILE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getProfile() => _datasource.getProfile();

  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data,
  ) => _datasource.updateProfile(data);

  Future<Map<String, dynamic>> uploadProfilePhoto(
    MultipartFile file,
  ) => _datasource.uploadProfilePhoto(file);

  Future<Map<String, dynamic>> deleteProfilePhoto() =>
      _datasource.deleteProfilePhoto();

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) => _datasource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

  /// Sends an account deletion request.
  Future<Map<String, dynamic>> deleteAccount() => _datasource.deleteAccount();

  // ═══════════════════════════════════════════════════════════════════════════
  //  BALANCE REMINDER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<BalanceReminderModel> getBalanceReminder() =>
      _datasource.getBalanceReminder();

  Future<Map<String, dynamic>> updateBalanceReminder(
    BalanceReminderModel reminder,
  ) => _datasource.updateBalanceReminder(reminder);

  // ═══════════════════════════════════════════════════════════════════════════
  //  SUB-ACCOUNTS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<PaginatedResponse<SubAccountModel>> listSubAccounts({
    int page = 1,
    int perPage = 15,
    String? search,
  }) async {
    final raw = await _datasource.listSubAccounts(
      page: page,
      perPage: perPage,
      search: search,
    );
    final paginationData = raw['data'] as Map<String, dynamic>? ?? raw;
    return PaginatedResponse.fromJson(
      paginationData,
      itemFromJson: (item) =>
          SubAccountModel.fromJson(item as Map<String, dynamic>),
    );
  }

  Future<SubAccountModel> getSubAccount(int id) =>
      _datasource.getSubAccount(id);

  Future<Map<String, dynamic>> createSubAccount(
    Map<String, dynamic> data,
  ) => _datasource.createSubAccount(data);

  Future<Map<String, dynamic>> verifySubAccountOtp({
    required String otp,
    required int userId,
  }) => _datasource.verifySubAccountOtp(otp: otp, userId: userId);

  Future<Map<String, dynamic>> updateSubAccount(
    int id,
    Map<String, dynamic> data,
  ) => _datasource.updateSubAccount(id, data);

  Future<Map<String, dynamic>> deleteSubAccount(int id) =>
      _datasource.deleteSubAccount(id);

  Future<Map<String, dynamic>> toggleSubAccountStatus(int id) =>
      _datasource.toggleSubAccountStatus(id);

  Future<Map<String, dynamic>> transferBalanceToSubAccount({
    required int subAccountId,
    required double amount,
  }) => _datasource.transferBalanceToSubAccount(
        subAccountId: subAccountId,
        amount: amount,
      );

  Future<Map<String, dynamic>> setAnnualBalance({
    required int subAccountId,
    required double amount,
  }) => _datasource.setAnnualBalance(
        subAccountId: subAccountId,
        amount: amount,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  //  ROLES
  // ═══════════════════════════════════════════════════════════════════════════

  Future<PaginatedResponse<RoleModel>> listRoles({
    int page = 1,
    int perPage = 15,
  }) async {
    final raw = await _datasource.listRoles(page: page, perPage: perPage);
    final paginationData = raw['data'] as Map<String, dynamic>? ?? raw;
    return PaginatedResponse.fromJson(
      paginationData,
      itemFromJson: (item) =>
          RoleModel.fromJson(item as Map<String, dynamic>),
    );
  }

  Future<List<PermissionModel>> getPermissions() =>
      _datasource.getPermissions();

  Future<Map<String, dynamic>> createRole(
    Map<String, dynamic> data,
  ) => _datasource.createRole(data);

  Future<Map<String, dynamic>> updateRole(
    int id,
    Map<String, dynamic> data,
  ) => _datasource.updateRole(id, data);

  Future<Map<String, dynamic>> deleteRole(int id) =>
      _datasource.deleteRole(id);

  // ═══════════════════════════════════════════════════════════════════════════
  //  SUB-ACCOUNT CATEGORIES
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<SubAccountCategoryModel>> listSubAccountCategories() async {
    final raw = await _datasource.listSubAccountCategories(perPage: 100);
    final data = raw['data'];
    if (data is Map<String, dynamic>) {
      final list = data['data'];
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => SubAccountCategoryModel.fromJson(e))
            .toList();
      }
    }
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => SubAccountCategoryModel.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createSubAccountCategory(
    Map<String, dynamic> data,
  ) => _datasource.createSubAccountCategory(data);

  Future<Map<String, dynamic>> updateSubAccountCategory(
    int id,
    Map<String, dynamic> data,
  ) => _datasource.updateSubAccountCategory(id, data);

  Future<Map<String, dynamic>> deleteSubAccountCategory(int id) =>
      _datasource.deleteSubAccountCategory(id);

  // ═══════════════════════════════════════════════════════════════════════════
  //  INVOICES
  // ═══════════════════════════════════════════════════════════════════════════

  Future<PaginatedResponse<InvoiceModel>> listInvoices({
    int page = 1,
    int perPage = 15,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    final raw = await _datasource.listInvoices(
      page: page,
      perPage: perPage,
      status: status,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    final paginationData = raw['data'] as Map<String, dynamic>? ?? raw;
    return PaginatedResponse.fromJson(
      paginationData,
      itemFromJson: (item) =>
          InvoiceModel.fromJson(item as Map<String, dynamic>),
    );
  }

  Future<InvoiceModel> getInvoice(int id) => _datasource.getInvoice(id);

  Future<String> getInvoicePdf(int id) => _datasource.getInvoicePdf(id);

  // ═══════════════════════════════════════════════════════════════════════════
  //  API KEYS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<ApiKeyModel>> listApiKeys() => _datasource.listApiKeys();

  Future<ApiKeyModel> createApiKey(String name) =>
      _datasource.createApiKey(name);

  Future<Map<String, dynamic>> deleteApiKey(int id) =>
      _datasource.deleteApiKey(id);

  // ═══════════════════════════════════════════════════════════════════════════
  //  SENDERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<PaginatedResponse<SenderRequestModel>> listSenderRequests({
    int page = 1,
    int perPage = 15,
  }) async {
    final raw = await _datasource.listSenderRequests(
      page: page,
      perPage: perPage,
    );
    final paginationData = raw['data'] as Map<String, dynamic>? ?? raw;
    return PaginatedResponse.fromJson(
      paginationData,
      itemFromJson: (item) =>
          SenderRequestModel.fromJson(item as Map<String, dynamic>),
    );
  }

  Future<Map<String, dynamic>> createSenderRequest(
    Map<String, dynamic> data,
  ) => _datasource.createSenderRequest(data);

  Future<Map<String, dynamic>> deleteSenderRequest(int id) =>
      _datasource.deleteSenderRequest(id);

  Future<Map<String, dynamic>> uploadSenderDocument(
    int id,
    MultipartFile file,
  ) => _datasource.uploadSenderDocument(id, file);

  Future<Map<String, dynamic>> uploadCommercialRegister(
    int id,
    MultipartFile file,
  ) => _datasource.uploadCommercialRegister(id, file);

  Future<Map<String, dynamic>> initiateSenderPayment(int id) =>
      _datasource.initiateSenderPayment(id);

  // ═══════════════════════════════════════════════════════════════════════════
  //  CONTRACTS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<PaginatedResponse<ContractModel>> listContracts({
    int page = 1,
    int perPage = 15,
  }) async {
    final raw = await _datasource.listContracts(
      page: page,
      perPage: perPage,
    );
    final paginationData = raw['data'] as Map<String, dynamic>? ?? raw;
    return PaginatedResponse.fromJson(
      paginationData,
      itemFromJson: (item) =>
          ContractModel.fromJson(item as Map<String, dynamic>),
    );
  }

  Future<Map<String, dynamic>> createContract(
    Map<String, dynamic> data,
  ) => _datasource.createContract(data);

  Future<Map<String, dynamic>> deleteContract(int id) =>
      _datasource.deleteContract(id);

  Future<Map<String, dynamic>> uploadContractDocument(
    int id,
    MultipartFile file,
  ) => _datasource.uploadContractDocument(id, file);
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final datasource = ref.watch(settingsRemoteDatasourceProvider);
  return SettingsRepository(datasource);
});
