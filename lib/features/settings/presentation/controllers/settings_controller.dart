import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/features/settings/data/models/api_key_model.dart';
import 'package:orbit_app/features/settings/data/models/contract_model.dart';
import 'package:orbit_app/features/settings/data/models/invoice_model.dart';
import 'package:orbit_app/features/settings/data/models/permission_model.dart';
import 'package:orbit_app/features/settings/data/models/role_model.dart';
import 'package:orbit_app/features/settings/data/models/sender_request_model.dart';
import 'package:orbit_app/features/settings/data/models/sub_account_model.dart';
import 'package:orbit_app/features/settings/data/repositories/settings_repository.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  PROFILE
// ═══════════════════════════════════════════════════════════════════════════

/// Loads and caches the user profile data.
class ProfileNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() => _fetch();

  Future<Map<String, dynamic>> _fetch() {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.getProfile();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.updateProfile(data);
    final success = result['success'] as bool? ?? false;
    if (success) await refresh();
    return success;
  }

  Future<bool> uploadPhoto(MultipartFile file) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.uploadProfilePhoto(file);
    final success = result['success'] as bool? ?? false;
    if (success) await refresh();
    return success;
  }

  Future<bool> deletePhoto() async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.deleteProfilePhoto();
    final success = result['success'] as bool? ?? false;
    if (success) await refresh();
    return success;
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, Map<String, dynamic>>(
  ProfileNotifier.new,
);

// ═══════════════════════════════════════════════════════════════════════════
//  BALANCE REMINDER
// ═══════════════════════════════════════════════════════════════════════════

class BalanceReminderNotifier extends AsyncNotifier<BalanceReminderModel> {
  @override
  Future<BalanceReminderModel> build() => _fetch();

  Future<BalanceReminderModel> _fetch() {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.getBalanceReminder();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<bool> updateReminder(BalanceReminderModel reminder) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.updateBalanceReminder(reminder);
    final success = result['success'] as bool? ?? false;
    if (success) {
      state = AsyncValue.data(reminder);
    }
    return success;
  }
}

final balanceReminderProvider =
    AsyncNotifierProvider<BalanceReminderNotifier, BalanceReminderModel>(
  BalanceReminderNotifier.new,
);

// ═══════════════════════════════════════════════════════════════════════════
//  SUB-ACCOUNTS
// ═══════════════════════════════════════════════════════════════════════════

class SubAccountsNotifier
    extends AsyncNotifier<PaginatedResponse<SubAccountModel>> {
  int _currentPage = 1;
  String _search = '';

  @override
  Future<PaginatedResponse<SubAccountModel>> build() => _fetch();

  Future<PaginatedResponse<SubAccountModel>> _fetch() {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.listSubAccounts(
      page: _currentPage,
      search: _search.isNotEmpty ? _search : null,
    );
  }

  Future<void> refresh() async {
    _currentPage = 1;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> search(String query) async {
    _search = query;
    _currentPage = 1;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> loadPage(int page) async {
    _currentPage = page;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.createSubAccount(data);
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String otp,
    required int userId,
  }) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result =
        await repo.verifySubAccountOtp(otp: otp, userId: userId);
    await refresh();
    return result;
  }

  Future<Map<String, dynamic>> updateSubAccount(
      int id, Map<String, dynamic> data) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.updateSubAccount(id, data);
    await refresh();
    return result;
  }

  Future<bool> delete(int id) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.deleteSubAccount(id);
    final success = result['success'] as bool? ?? false;
    if (success) await refresh();
    return success;
  }

  Future<bool> toggleStatus(int id) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.toggleSubAccountStatus(id);
    final success = result['success'] as bool? ?? false;
    if (success) await refresh();
    return success;
  }

  Future<Map<String, dynamic>> transferBalance({
    required int subAccountId,
    required double amount,
  }) async {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.transferBalanceToSubAccount(
      subAccountId: subAccountId,
      amount: amount,
    );
  }

  Future<Map<String, dynamic>> setAnnualBalance({
    required int subAccountId,
    required double amount,
  }) async {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.setAnnualBalance(
      subAccountId: subAccountId,
      amount: amount,
    );
  }
}

final subAccountsProvider = AsyncNotifierProvider<SubAccountsNotifier,
    PaginatedResponse<SubAccountModel>>(
  SubAccountsNotifier.new,
);

// ═══════════════════════════════════════════════════════════════════════════
//  ROLES
// ═══════════════════════════════════════════════════════════════════════════

class RolesNotifier extends AsyncNotifier<PaginatedResponse<RoleModel>> {
  @override
  Future<PaginatedResponse<RoleModel>> build() => _fetch();

  Future<PaginatedResponse<RoleModel>> _fetch() {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.listRoles();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.createRole(data);
    await refresh();
    return result;
  }

  Future<Map<String, dynamic>> updateRole(
      int id, Map<String, dynamic> data) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.updateRole(id, data);
    await refresh();
    return result;
  }

  Future<bool> delete(int id) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.deleteRole(id);
    final success = result['success'] as bool? ?? false;
    if (success) await refresh();
    return success;
  }
}

final rolesProvider =
    AsyncNotifierProvider<RolesNotifier, PaginatedResponse<RoleModel>>(
  RolesNotifier.new,
);

/// Loads all available permissions for role editing.
final permissionsProvider = FutureProvider<List<PermissionModel>>((ref) async {
  final repo = ref.read(settingsRepositoryProvider);
  return repo.getPermissions();
});

// ═══════════════════════════════════════════════════════════════════════════
//  SUB-ACCOUNT CATEGORIES
// ═══════════════════════════════════════════════════════════════════════════

class SubAccountCategoriesNotifier
    extends AsyncNotifier<List<SubAccountCategoryModel>> {
  @override
  Future<List<SubAccountCategoryModel>> build() => _fetch();

  Future<List<SubAccountCategoryModel>> _fetch() {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.listSubAccountCategories();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.createSubAccountCategory(data);
    await refresh();
    return result;
  }

  Future<Map<String, dynamic>> updateCategory(
      int id, Map<String, dynamic> data) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.updateSubAccountCategory(id, data);
    await refresh();
    return result;
  }

  Future<bool> delete(int id) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.deleteSubAccountCategory(id);
    final success = result['success'] as bool? ?? false;
    if (success) await refresh();
    return success;
  }
}

final subAccountCategoriesProvider = AsyncNotifierProvider<
    SubAccountCategoriesNotifier, List<SubAccountCategoryModel>>(
  SubAccountCategoriesNotifier.new,
);

// ═══════════════════════════════════════════════════════════════════════════
//  INVOICES
// ═══════════════════════════════════════════════════════════════════════════

class InvoicesNotifier
    extends AsyncNotifier<PaginatedResponse<InvoiceModel>> {
  int _currentPage = 1;
  String? _statusFilter;
  String? _dateFrom;
  String? _dateTo;

  @override
  Future<PaginatedResponse<InvoiceModel>> build() => _fetch();

  Future<PaginatedResponse<InvoiceModel>> _fetch() {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.listInvoices(
      page: _currentPage,
      status: _statusFilter,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );
  }

  Future<void> refresh() async {
    _currentPage = 1;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> filter({
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    _statusFilter = status;
    _dateFrom = dateFrom;
    _dateTo = dateTo;
    _currentPage = 1;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> loadPage(int page) async {
    _currentPage = page;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<String> downloadPdf(int id) async {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.getInvoicePdf(id);
  }
}

final invoicesProvider = AsyncNotifierProvider<InvoicesNotifier,
    PaginatedResponse<InvoiceModel>>(
  InvoicesNotifier.new,
);

/// Loads a single invoice by ID.
final invoiceDetailProvider =
    FutureProvider.family<InvoiceModel, int>((ref, id) async {
  final repo = ref.read(settingsRepositoryProvider);
  return repo.getInvoice(id);
});

// ═══════════════════════════════════════════════════════════════════════════
//  API KEYS
// ═══════════════════════════════════════════════════════════════════════════

class ApiKeysNotifier extends AsyncNotifier<List<ApiKeyModel>> {
  @override
  Future<List<ApiKeyModel>> build() => _fetch();

  Future<List<ApiKeyModel>> _fetch() {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.listApiKeys();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<ApiKeyModel> create(String name) async {
    final repo = ref.read(settingsRepositoryProvider);
    final key = await repo.createApiKey(name);
    await refresh();
    return key;
  }

  Future<bool> delete(int id) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.deleteApiKey(id);
    final success = result['success'] as bool? ?? false;
    if (success) await refresh();
    return success;
  }
}

final apiKeysProvider =
    AsyncNotifierProvider<ApiKeysNotifier, List<ApiKeyModel>>(
  ApiKeysNotifier.new,
);

// ═══════════════════════════════════════════════════════════════════════════
//  SENDER REQUESTS
// ═══════════════════════════════════════════════════════════════════════════

class SenderRequestsNotifier
    extends AsyncNotifier<PaginatedResponse<SenderRequestModel>> {
  int _currentPage = 1;

  @override
  Future<PaginatedResponse<SenderRequestModel>> build() => _fetch();

  Future<PaginatedResponse<SenderRequestModel>> _fetch() {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.listSenderRequests(page: _currentPage);
  }

  Future<void> refresh() async {
    _currentPage = 1;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> loadPage(int page) async {
    _currentPage = page;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.createSenderRequest(data);
    await refresh();
    return result;
  }

  Future<bool> delete(int id) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.deleteSenderRequest(id);
    final success = result['success'] as bool? ?? false;
    if (success) await refresh();
    return success;
  }

  Future<Map<String, dynamic>> uploadDocument(
      int id, MultipartFile file) async {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.uploadSenderDocument(id, file);
  }

  Future<Map<String, dynamic>> uploadCommercialRegister(
      int id, MultipartFile file) async {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.uploadCommercialRegister(id, file);
  }

  Future<Map<String, dynamic>> initiatePayment(int id) async {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.initiateSenderPayment(id);
  }
}

final senderRequestsProvider = AsyncNotifierProvider<SenderRequestsNotifier,
    PaginatedResponse<SenderRequestModel>>(
  SenderRequestsNotifier.new,
);

// ═══════════════════════════════════════════════════════════════════════════
//  CONTRACTS
// ═══════════════════════════════════════════════════════════════════════════

class ContractsNotifier
    extends AsyncNotifier<PaginatedResponse<ContractModel>> {
  int _currentPage = 1;

  @override
  Future<PaginatedResponse<ContractModel>> build() => _fetch();

  Future<PaginatedResponse<ContractModel>> _fetch() {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.listContracts(page: _currentPage);
  }

  Future<void> refresh() async {
    _currentPage = 1;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> loadPage(int page) async {
    _currentPage = page;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.createContract(data);
    await refresh();
    return result;
  }

  Future<bool> delete(int id) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.deleteContract(id);
    final success = result['success'] as bool? ?? false;
    if (success) await refresh();
    return success;
  }

  Future<Map<String, dynamic>> uploadDocument(
      int id, MultipartFile file) async {
    final repo = ref.read(settingsRepositoryProvider);
    return repo.uploadContractDocument(id, file);
  }
}

final contractsProvider = AsyncNotifierProvider<ContractsNotifier,
    PaginatedResponse<ContractModel>>(
  ContractsNotifier.new,
);
