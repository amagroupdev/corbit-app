import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/features/support/data/models/ticket_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Remote data source for the V3 support tickets endpoints.
///
/// - `POST /support-tickets/list` — paginated list (auth required)
/// - `POST /support-tickets`      — create new ticket
class SupportRemoteDataSource {
  const SupportRemoteDataSource(this._client);

  final ApiClient _client;

  /// Returns a paginated list of tickets owned by the current user.
  Future<PaginatedResponse<SupportTicketModel>> listTickets({
    int page = 1,
    int perPage = ApiConstants.defaultPerPage,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.supportTicketsList,
      data: {
        'page': page,
        'per_page': perPage,
      },
    );

    final body = response.data ?? const <String, dynamic>{};
    final dataPayload = body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : body;

    return PaginatedResponse<SupportTicketModel>.fromJson(
      dataPayload,
      itemFromJson: (item) =>
          SupportTicketModel.fromJson(item as Map<String, dynamic>),
    );
  }

  /// Creates a new ticket. Per the Postman master collection the only
  /// required field is `title`.
  Future<SupportTicketModel> createTicket({required String title}) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.supportTickets,
      data: {'title': title},
    );

    final body = response.data ?? const <String, dynamic>{};
    final raw = body['data'];
    if (raw is Map<String, dynamic>) {
      return SupportTicketModel.fromJson(raw);
    }
    // Server returned no body — synthesize a placeholder so the caller
    // can show "submitted" feedback even if the echo is empty.
    return SupportTicketModel(
      id: 0,
      title: title,
    );
  }
}

/// Riverpod provider for [SupportRemoteDataSource].
final supportRemoteDataSourceProvider =
    Provider<SupportRemoteDataSource>((ref) {
  final client = ref.watch(apiClientProvider);
  return SupportRemoteDataSource(client);
});
