import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/auth/data/repositories/auth_repository.dart'
    show Result;
import 'package:orbit_app/features/transfer_subaccounts/data/datasources/subaccount_transfer_remote_datasource.dart';
import 'package:orbit_app/features/transfer_subaccounts/data/models/subaccount_transfer_model.dart';

class SubaccountTransferRepository {
  SubaccountTransferRepository(this._datasource);

  final SubaccountTransferRemoteDatasource _datasource;

  Future<Result<List<SubaccountTransferModel>>> getHistory({
    int page = 1,
    int perPage = 15,
  }) {
    return _guard(() => _datasource.getHistory(page: page, perPage: perPage));
  }

  Future<Result<Map<String, dynamic>>> transfer({
    required String fromUsername,
    required String toUsername,
    required double amount,
    String? note,
  }) {
    return _guard(() => _datasource.transfer(
          fromUsername: fromUsername,
          toUsername: toUsername,
          amount: amount,
          note: note,
        ));
  }

  Future<Result<SubaccountTransferReportModel>> getReport({
    String? from,
    String? to,
    int? toId,
  }) {
    return _guard(() => _datasource.getReport(from: from, to: to, toId: toId));
  }

  Future<Result<Map<String, dynamic>>> exportTransfers({
    required String from,
    required String to,
    int? toId,
  }) {
    return _guard(
        () => _datasource.exportTransfers(from: from, to: to, toId: toId));
  }

  Future<Result<Map<String, dynamic>>> exportAllTransfers({
    String? from,
    String? to,
  }) {
    return _guard(() => _datasource.exportAllTransfers(from: from, to: to));
  }

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      final data = await body();
      return Result.success(data);
    } on ValidationException catch (e) {
      return Result.failure(e.message, fieldErrors: e.errors);
    } on ApiException catch (e) {
      return Result.failure(e.message);
    } catch (_) {
      return Result.failure('unexpectedError');
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────

final subaccountTransferRepositoryProvider =
    Provider<SubaccountTransferRepository>((ref) {
  final ds = ref.watch(subaccountTransferRemoteDatasourceProvider);
  return SubaccountTransferRepository(ds);
});
