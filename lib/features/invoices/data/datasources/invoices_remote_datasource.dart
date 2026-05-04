import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/invoices/data/models/invoice_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Remote datasource for the V3 Settings → Invoices feature (Wave 9).
///
/// Wraps:
/// - `POST /settings/invoices/list`
/// - `GET  /settings/invoices/{id}`
/// - `GET  /settings/invoices/{id}/pdf`
class InvoicesRemoteDatasource {
  InvoicesRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// `POST /settings/invoices/list` — paginated invoices.
  Future<PaginatedResponse<InvoiceModel>> list({
    int page = 1,
    int perPage = 15,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.settingsInvoicesList,
        data: {
          'page': page,
          'per_page': perPage,
          if (status != null && status.isNotEmpty) 'status': status,
          if (dateFrom != null) 'date_from': dateFrom,
          if (dateTo != null) 'date_to': dateTo,
        },
      );

      final apiResponse = ApiResponse<PaginatedResponse<InvoiceModel>>.fromJson(
        response.data ?? const {},
        fromJsonT: (data) => PaginatedResponse<InvoiceModel>.fromJson(
          data as Map<String, dynamic>,
          itemFromJson: (item) =>
              InvoiceModel.fromJson(item as Map<String, dynamic>),
        ),
      );

      return apiResponse.data ?? PaginatedResponse<InvoiceModel>.empty();
    } on ApiException {
      rethrow;
    }
  }

  /// `GET /settings/invoices/{id}` — single invoice detail.
  Future<InvoiceModel> show(int id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.settingsInvoiceShow(id),
      );
      final raw = response.data?['data'];
      if (raw is Map<String, dynamic>) {
        return InvoiceModel.fromJson(raw);
      }
      throw const NotFoundException(
        message: 'Invoice not found',
      );
    } on ApiException {
      rethrow;
    }
  }

  /// `GET /settings/invoices/{id}/pdf` — returns the PDF download URL.
  Future<String> pdfUrl(int id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.settingsInvoicePdf(id),
      );
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final data = raw['data'];
        if (data is Map<String, dynamic>) {
          return data['url'] as String? ??
              data['pdf_url'] as String? ??
              data['file_url'] as String? ??
              '';
        }
        return raw['url'] as String? ?? '';
      }
      return '';
    } on ApiException {
      rethrow;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final invoicesRemoteDatasourceProvider =
    Provider<InvoicesRemoteDatasource>((ref) {
  return InvoicesRemoteDatasource(ref.watch(apiClientProvider));
});
