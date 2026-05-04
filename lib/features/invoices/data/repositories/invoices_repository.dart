import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/features/invoices/data/datasources/invoices_remote_datasource.dart';
import 'package:orbit_app/features/invoices/data/models/invoice_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository for the Wave 9 Invoices feature.
class InvoicesRepository {
  const InvoicesRepository(this._remote);

  final InvoicesRemoteDatasource _remote;

  Future<PaginatedResponse<InvoiceModel>> list({
    int page = 1,
    int perPage = 15,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) =>
      _remote.list(
        page: page,
        perPage: perPage,
        status: status,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

  Future<InvoiceModel> show(int id) => _remote.show(id);

  Future<String> pdfUrl(int id) => _remote.pdfUrl(id);
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

final invoicesRepositoryProvider = Provider<InvoicesRepository>((ref) {
  return InvoicesRepository(ref.watch(invoicesRemoteDatasourceProvider));
});
