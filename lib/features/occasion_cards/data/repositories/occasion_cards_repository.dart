import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/occasion_cards/data/datasources/occasion_cards_remote_datasource.dart';
import 'package:orbit_app/features/occasion_cards/data/models/occasion_card_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository for occasion-card operations.
///
/// Wraps [OccasionCardsRemoteDataSource] and re-throws [ApiException] so the
/// presentation layer can react to validation/auth errors uniformly.
class OccasionCardsRepository {
  const OccasionCardsRepository(this._remote);

  final OccasionCardsRemoteDataSource _remote;

  // ─── Templates ───────────────────────────────────────────────────────

  Future<List<OccasionCardTemplateModel>> getTemplates() async {
    try {
      return await _remote.fetchTemplates();
    } on ApiException {
      rethrow;
    }
  }

  // ─── Send ────────────────────────────────────────────────────────────

  Future<void> sendCard({
    required int templateId,
    required String message,
    List<int> groupIds = const [],
    List<String> numbers = const [],
    int? senderId,
    DateTime? scheduledAt,
  }) async {
    try {
      await _remote.send(
        templateId: templateId,
        message: message,
        groupIds: groupIds,
        numbers: numbers,
        senderId: senderId,
        scheduledAt: scheduledAt,
      );
    } on ApiException {
      rethrow;
    }
  }

  // ─── Preview ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> preview({
    required int templateId,
    required String message,
    List<int> groupIds = const [],
    List<String> numbers = const [],
  }) async {
    try {
      return await _remote.preview(
        templateId: templateId,
        message: message,
        groupIds: groupIds,
        numbers: numbers,
      );
    } on ApiException {
      rethrow;
    }
  }

  // ─── Archive (list) ──────────────────────────────────────────────────

  Future<PaginatedResponse<OccasionCardModel>> getArchive({
    int page = 1,
    String? search,
  }) async {
    try {
      return await _remote.fetchArchive(page: page, search: search);
    } on ApiException {
      rethrow;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

final occasionCardsRepositoryProvider =
    Provider<OccasionCardsRepository>((ref) {
  return OccasionCardsRepository(
    ref.watch(occasionCardsRemoteDataSourceProvider),
  );
});
