import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/features/absence/data/datasources/absence_remote_datasource.dart';
import 'package:orbit_app/features/absence/data/models/absence_message_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository for absence & tardiness message operations.
///
/// Delegates to [AbsenceRemoteDatasource] for network calls.
class AbsenceRepository {
  const AbsenceRepository(this._remoteDatasource);

  final AbsenceRemoteDatasource _remoteDatasource;

  /// Fetches a paginated list of absence/tardiness messages.
  Future<PaginatedResponse<AbsenceMessageModel>> getMessages({
    int page = 1,
    String? search,
    String? messageType,
    String? status,
    String? senderName,
    String? classification,
    String? dateFrom,
    String? dateTo,
  }) {
    return _remoteDatasource.getMessages(
      page: page,
      search: search,
      messageType: messageType,
      status: status,
      senderName: senderName,
      classification: classification,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  /// Sends an absence message to parents/guardians.
  Future<void> sendAbsenceMessage({
    required int senderId,
    required String messageBody,
    required String messageType,
    required List<int> groupIds,
    List<String>? numbers,
  }) {
    return _remoteDatasource.sendAbsenceMessage(
      senderId: senderId,
      messageBody: messageBody,
      messageType: messageType,
      groupIds: groupIds,
      numbers: numbers,
    );
  }

  /// Fetches details of a specific absence message.
  Future<AbsenceMessageModel> getMessageDetail(int id) {
    return _remoteDatasource.getMessageDetail(id);
  }

  /// Fetches the delivery report for a specific absence message.
  Future<PaginatedResponse<Map<String, dynamic>>> getReport(
    int id, {
    int page = 1,
  }) {
    return _remoteDatasource.getReport(id, page: page);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

final absenceRepositoryProvider = Provider<AbsenceRepository>((ref) {
  return AbsenceRepository(ref.watch(absenceRemoteDatasourceProvider));
});
