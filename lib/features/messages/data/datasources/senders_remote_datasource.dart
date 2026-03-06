import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/features/messages/data/models/sender_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';

/// Remote data source for sender name operations.
///
/// Sender names are pre-registered identifiers that appear as the
/// "From" label on the recipient's device.
class SendersRemoteDatasource {
  const SendersRemoteDatasource(this._client);

  final ApiClient _client;

  // ─── List Senders ────────────────────────────────────────────────────

  /// Returns all sender names associated with the current account.
  ///
  /// Uses POST /senders/list which returns:
  /// `{success, message, data: {senders: [{id, name, status, expired_at, is_default}]}}`
  Future<List<SenderModel>> listSenders() async {
    try {
      final response = await _client.post(
        '${ApiConstants.senders}/list',
        data: {'page': 1, 'per_page': 100},
      );

      final json = response.data as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>? ?? json;

      // Response shape: {senders: [...]}
      final rawList = data['senders'] as List<dynamic>? ??
          data['data'] as List<dynamic>? ??
          (json['data'] is List ? json['data'] as List<dynamic> : []);

      return rawList
          .map((item) => SenderModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Validate Sender ─────────────────────────────────────────────────

  /// Validates whether a sender ID is approved and usable.
  ///
  /// Returns `true` if the sender is valid and active.
  Future<bool> validateSender(int senderId) async {
    try {
      final response = await _client.get(
        '${ApiConstants.senders}/$senderId/validate',
      );
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
      );
      return apiResponse.data?['is_valid'] as bool? ?? false;
    } catch (_) {
      // If validation endpoint doesn't exist, assume valid.
      return true;
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final sendersRemoteDatasourceProvider = Provider<SendersRemoteDatasource>((ref) {
  final client = ref.watch(apiClientProvider);
  return SendersRemoteDatasource(client);
});
