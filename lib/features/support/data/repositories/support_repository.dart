import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/support/data/datasources/support_remote_datasource.dart';
import 'package:orbit_app/features/support/data/models/ticket_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Thin repository layer over [SupportRemoteDataSource].
///
/// Re-throws [ApiException] so the controller layer can react to validation
/// errors (e.g. surface field-level messages on the create form).
class SupportRepository {
  const SupportRepository(this._remote);

  final SupportRemoteDataSource _remote;

  Future<PaginatedResponse<SupportTicketModel>> listTickets({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      return await _remote.listTickets(page: page, perPage: perPage);
    } on ApiException {
      rethrow;
    }
  }

  Future<SupportTicketModel> createTicket({required String title}) async {
    try {
      return await _remote.createTicket(title: title);
    } on ApiException {
      rethrow;
    }
  }
}

/// Riverpod provider for [SupportRepository].
final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  final remote = ref.watch(supportRemoteDataSourceProvider);
  return SupportRepository(remote);
});
