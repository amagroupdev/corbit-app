import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/features/balance/data/datasources/balance_remote_datasource.dart';
import 'package:orbit_app/features/balance/data/models/balance_model.dart';
import 'package:orbit_app/features/balance/data/models/bank_model.dart';
import 'package:orbit_app/features/balance/data/models/offer_model.dart';
import 'package:orbit_app/features/balance/data/models/price_tier_model.dart';
import 'package:orbit_app/features/balance/data/models/transaction_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository that wraps [BalanceRemoteDatasource] to provide a clean
/// interface for the presentation layer.
class BalanceRepository {
  BalanceRepository(this._datasource);

  final BalanceRemoteDatasource _datasource;

  // ─── Balance Info ────────────────────────────────────────────────

  Future<BalanceModel> getCurrentBalance() {
    return _datasource.getCurrentBalance();
  }

  Future<BalanceSummaryModel> getBalanceSummary() {
    return _datasource.getBalanceSummary();
  }

  Future<List<PriceTierModel>> getPriceTiers() {
    return _datasource.getPriceTiers();
  }

  Future<List<BankModel>> getBanks() {
    return _datasource.getBanks();
  }

  Future<List<OfferModel>> getOffers() {
    return _datasource.getOffers();
  }

  // ─── Transactions ────────────────────────────────────────────────

  Future<PaginatedResponse<TransactionModel>> getTransactions({
    int page = 1,
    int perPage = 15,
    String? search,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) {
    return _datasource.getTransactions(
      page: page,
      perPage: perPage,
      search: search,
      status: status,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  // ─── Purchase ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> calculatePurchase({
    required int amount,
    required String paymentMethod,
  }) {
    return _datasource.calculatePurchase(amount: amount, paymentMethod: paymentMethod);
  }

  Future<Map<String, dynamic>> purchaseOnline({
    required int amount,
  }) {
    return _datasource.purchaseOnline(amount: amount);
  }

  Future<Map<String, dynamic>> purchaseBankTransfer({
    required int amount,
    required int bankId,
    required String depositorName,
    required String transferDate,
    String? receiptFilePath,
    String? receiptFileName,
  }) {
    return _datasource.purchaseBankTransfer(
      amount: amount,
      bankId: bankId,
      depositorName: depositorName,
      transferDate: transferDate,
      receiptFilePath: receiptFilePath,
      receiptFileName: receiptFileName,
    );
  }

  Future<Map<String, dynamic>> purchaseStcPay({
    required int amount,
    required String phoneNumber,
  }) {
    return _datasource.purchaseStcPay(
      amount: amount,
      phoneNumber: phoneNumber,
    );
  }

  Future<Map<String, dynamic>> verifyStcPayOtp({
    required String otp,
    required String transactionId,
  }) {
    return _datasource.verifyStcPayOtp(
      otp: otp,
      transactionId: transactionId,
    );
  }

  Future<Map<String, dynamic>> purchaseSadad({
    required int amount,
    required String phoneNumber,
    required String nationalId,
  }) {
    return _datasource.purchaseSadad(
      amount: amount,
      phoneNumber: phoneNumber,
      nationalId: nationalId,
    );
  }

  // ─── Transfer ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> transferBalance({
    required String phoneNumber,
    required int amount,
  }) {
    return _datasource.transferBalance(
      phoneNumber: phoneNumber,
      amount: amount,
    );
  }

  Future<List<Map<String, dynamic>>> getTransferHistory() {
    return _datasource.getTransferHistory();
  }
}

// ─── Provider ──────────────────────────────────────────────────────

final balanceRepositoryProvider = Provider<BalanceRepository>((ref) {
  final datasource = ref.watch(balanceRemoteDatasourceProvider);
  return BalanceRepository(datasource);
});
