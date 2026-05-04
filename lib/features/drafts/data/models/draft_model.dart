import 'package:orbit_app/features/drafts/data/models/draft_data_model.dart';

/// Represents a single saved message draft as returned by the V3 API.
///
/// Draft list items returned by `POST /messages/drafts/list` have shape:
/// ```json
/// {
///   "id": 12,
///   "message_type": "to_number",
///   "draft_data": { ... },
///   "created_at": "2026-05-04T12:34:56Z",
///   "updated_at": "2026-05-04T12:34:56Z"
/// }
/// ```
///
/// Some endpoints (e.g. `GET /messages/drafts/{id}`) may inline
/// `draft_data` keys at the top level — this model handles both shapes.
class DraftModel {
  const DraftModel({
    required this.id,
    required this.messageType,
    required this.draftData,
    required this.createdAt,
    this.updatedAt,
  });

  /// Server-side identifier for this draft.
  final int id;

  /// One of the four message type variants.
  final DraftMessageType messageType;

  /// The full payload that would be re-sent on resume.
  final DraftDataModel draftData;

  /// When the draft was first saved.
  final DateTime createdAt;

  /// When the draft was last updated, if reported by the server.
  final DateTime? updatedAt;

  factory DraftModel.fromJson(Map<String, dynamic> json) {
    // Some endpoints return `draft_data` as a JSON string. Be defensive.
    final rawDraftData = json['draft_data'];
    Map<String, dynamic> draftDataJson;
    if (rawDraftData is Map<String, dynamic>) {
      draftDataJson = rawDraftData;
    } else if (rawDraftData is Map) {
      draftDataJson = rawDraftData.cast<String, dynamic>();
    } else {
      // Fallback: treat the row itself as the draft_data payload.
      draftDataJson = Map<String, dynamic>.from(json);
    }

    return DraftModel(
      id: _parseInt(json['id']) ?? 0,
      messageType: DraftMessageType.fromValue(
        json['message_type'] as String?,
      ),
      draftData: DraftDataModel.fromJson(draftDataJson),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_type': messageType.value,
      'draft_data': draftData.toJson(),
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Returns a short preview of the message body, suitable for cards.
  /// Empty bodies fall back to a placeholder.
  String preview({int maxLength = 80}) {
    final body = draftData.messageBody.trim();
    if (body.isEmpty) return '';
    if (body.length <= maxLength) return body;
    return '${body.substring(0, maxLength)}...';
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
