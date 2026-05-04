import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/features/transfer_subaccounts/data/models/subaccount_transfer_model.dart';

/// Remote data source for `/transfer/subaccounts/*` endpoints.
class SubaccountTransferRemoteDatasource {
  SubaccountTransferRemoteDatasource(this._client);

  final ApiClient _client;

  /// GET /transfer/subaccounts/history
  Future<List<SubaccountTransferModel>> getHistory({
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.transferSubaccountsHistory,
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );

    final body = response.data ?? const {};
    final raw = body['data'];

    final List<dynamic> items;
    if (raw is List) {
      items = raw;
    } else if (raw is Map<String, dynamic> && raw['data'] is List) {
      items = raw['data'] as List;
    } else {
      items = const [];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(SubaccountTransferModel.fromJson)
        .toList();
  }

  /// POST /transfer/subaccounts
  Future<Map<String, dynamic>> transfer({
    required String fromUsername,
    required String toUsername,
    required double amount,
    String? note,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.transferSubaccounts,
      data: {
        'from_username': fromUsername,
        'to_username': toUsername,
        'amount': amount,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    final body = response.data ?? const <String, dynamic>{};
    if (body['data'] is Map<String, dynamic>) {
      return body['data'] as Map<String, dynamic>;
    }
    return body;
  }

  /// GET /transfer/subaccounts/report
  Future<SubaccountTransferReportModel> getReport({
    String? from,
    String? to,
    int? toId,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.transferSubaccountsReport,
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (toId != null) 'to_id': toId,
      },
    );

    final body = response.data ?? const {};
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return SubaccountTransferReportModel.fromJson(data);
    }
    return SubaccountTransferReportModel.fromJson(body);
  }

  /// POST /transfer/subaccounts/export
  Future<Map<String, dynamic>> exportTransfers({
    required String from,
    required String to,
    int? toId,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.transferSubaccountsExport,
      data: {
        'from': from,
        'to': to,
        if (toId != null) 'to_id': toId,
      },
    );
    return response.data ?? const {};
  }

  /// GET /transfer/export
  Future<Map<String, dynamic>> exportAllTransfers({
    String? from,
    String? to,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.transferExport,
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );
    return response.data ?? const {};
  }
}

// ─── Provider ────────────────────────────────────────────────────────

final subaccountTransferRemoteDatasourceProvider =
    Provider<SubaccountTransferRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SubaccountTransferRemoteDatasource(apiClient);
});
