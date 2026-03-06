import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/features/balance/data/models/balance_model.dart';
import 'package:orbit_app/features/balance/data/models/bank_model.dart';
import 'package:orbit_app/features/balance/data/models/offer_model.dart';
import 'package:orbit_app/features/balance/data/models/price_tier_model.dart';
import 'package:orbit_app/features/balance/data/models/transaction_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Remote data source for all balance, transaction, and transfer operations.
///
/// Each method maps 1:1 to an API v3 endpoint.
class BalanceRemoteDatasource {
  BalanceRemoteDatasource(this._client);

  final ApiClient _client;

  // ─── Balance Info ────────────────────────────────────────────────

  /// GET /api/v3/balance/current
  Future<BalanceModel> getCurrentBalance() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/balance/current',
    );

    final body = response.data!;
    final data = body['data'] as Map<String, dynamic>? ?? body;
    return BalanceModel.fromJson(data);
  }

  /// GET /api/v3/balance/summary
  Future<BalanceSummaryModel> getBalanceSummary() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/balance/summary',
    );

    final body = response.data!;
    final data = body['data'] as Map<String, dynamic>? ?? body;
    return BalanceSummaryModel.fromJson(data);
  }

  /// GET /api/v3/balance/prices
  Future<List<PriceTierModel>> getPriceTiers() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/balance/prices',
    );

    final body = response.data!;
    final rawData = body['data'];
    if (rawData is List) {
      return rawData
          .map((item) =>
              PriceTierModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// GET /api/v3/balance/banks
  Future<List<BankModel>> getBanks() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/balance/banks',
    );

    final body = response.data!;
    final rawData = body['data'];
    if (rawData is List) {
      return rawData
          .map((item) => BankModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// GET /api/v3/balance/offers
  Future<List<OfferModel>> getOffers() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/balance/offers',
      );

      final body = response.data!;
      final rawData = body['data'];
      if (rawData is List) {
        return rawData
            .map((item) => OfferModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      // Endpoint may return 500; return empty list gracefully.
      return [];
    }
  }

  // ─── Transactions ────────────────────────────────────────────────

  /// GET /api/v3/balance/transactions
  Future<PaginatedResponse<TransactionModel>> getTransactions({
    int page = 1,
    int perPage = 15,
    String? search,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    };

    final response = await _client.get<Map<String, dynamic>>(
      '/balance/transactions',
      queryParameters: queryParams,
    );

    final body = response.data!;
    final payload = body['data'] as Map<String, dynamic>? ?? body;

    return PaginatedResponse<TransactionModel>.fromJson(
      payload,
      itemFromJson: (item) =>
          TransactionModel.fromJson(item as Map<String, dynamic>),
    );
  }

  // ─── Purchase ────────────────────────────────────────────────────

  /// POST /api/v3/balance/purchase/calculate
  Future<Map<String, dynamic>> calculatePurchase({
    required int amount,
    required String paymentMethod,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/balance/purchase/calculate',
      data: {'amount': amount, 'payment_method': paymentMethod},
    );
    final body = response.data!;
    return body['data'] as Map<String, dynamic>? ?? body;
  }

  /// POST /api/v3/balance/purchase -- online (Noon) payment
  Future<Map<String, dynamic>> purchaseOnline({
    required int amount,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/balance/purchase',
      data: {
        'amount': amount,
        'payment_method': 'online',
      },
    );
    return response.data ?? {};
  }

  /// POST /api/v3/balance/purchase -- bank transfer
  Future<Map<String, dynamic>> purchaseBankTransfer({
    required int amount,
    required int bankId,
    required String depositorName,
    required String transferDate,
    String? receiptFilePath,
    String? receiptFileName,
  }) async {
    if (receiptFilePath != null && receiptFileName != null) {
      final file = await MultipartFile.fromFile(
        receiptFilePath,
        filename: receiptFileName,
      );

      final response = await _client.upload<Map<String, dynamic>>(
        '/balance/purchase',
        file: file,
        fileFieldName: 'receipt',
        data: {
          'amount': amount,
          'payment_method': 'bank_transfer',
          'bank_id': bankId,
          'depositor_name': depositorName,
          'transfer_date': transferDate,
        },
      );
      return response.data ?? {};
    }

    final response = await _client.post<Map<String, dynamic>>(
      '/balance/purchase',
      data: {
        'amount': amount,
        'payment_method': 'bank_transfer',
        'bank_id': bankId,
        'depositor_name': depositorName,
        'transfer_date': transferDate,
      },
    );
    return response.data ?? {};
  }

  /// POST /api/v3/balance/purchase -- STC Pay
  Future<Map<String, dynamic>> purchaseStcPay({
    required int amount,
    required String phoneNumber,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/balance/purchase',
      data: {
        'amount': amount,
        'payment_method': 'stc_pay',
        'phone': phoneNumber,
      },
    );
    return response.data ?? {};
  }

  /// POST /api/v3/balance/purchase/verify-otp -- STC Pay OTP verification
  Future<Map<String, dynamic>> verifyStcPayOtp({
    required String otp,
    required String transactionId,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/balance/purchase/verify-otp',
      data: {
        'otp': otp,
        'transaction_id': transactionId,
      },
    );
    return response.data ?? {};
  }

  /// POST /api/v3/balance/purchase -- SADAD
  Future<Map<String, dynamic>> purchaseSadad({
    required int amount,
    required String phoneNumber,
    required String nationalId,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/balance/purchase',
      data: {
        'amount': amount,
        'payment_method': 'sadad',
        'phone_number': phoneNumber,
        'national_id': nationalId,
      },
    );
    return response.data ?? {};
  }

  // ─── Transfer ────────────────────────────────────────────────────

  /// POST /api/v3/transfer
  Future<Map<String, dynamic>> transferBalance({
    required String phoneNumber,
    required int amount,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/transfer',
      data: {
        'phone': phoneNumber,
        'amount': amount,
      },
    );
    return response.data ?? {};
  }

  /// GET /api/v3/transfer/history
  Future<List<Map<String, dynamic>>> getTransferHistory() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/transfer/history',
    );

    final body = response.data!;
    final rawData = body['data'];
    if (rawData is List) {
      return rawData
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }
    return [];
  }
}

// ─── Provider ──────────────────────────────────────────────────────

final balanceRemoteDatasourceProvider =
    Provider<BalanceRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BalanceRemoteDatasource(apiClient);
});
