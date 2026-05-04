/// Model representing a voice message stored on the ORBIT platform.
///
/// The server responds with several possible field names depending on
/// endpoint (`file_url`, `url`, `voice_file_url`), so [fromJson] is
/// intentionally lenient.
class VoiceMessageModel {
  const VoiceMessageModel({
    required this.id,
    required this.name,
    required this.fileUrl,
    this.durationSeconds,
    this.createdAt,
  });

  /// Unique identifier.
  final int id;

  /// Display name (defaults to the auto-generated upload name).
  final String name;

  /// Direct URL to the audio file (m4a/mp3).
  final String fileUrl;

  /// Duration of the recording in seconds, when known.
  final int? durationSeconds;

  /// When the recording was uploaded.
  final DateTime? createdAt;

  /// Returns the duration as `mm:ss` if available, otherwise `--:--`.
  String get formattedDuration {
    final seconds = durationSeconds;
    if (seconds == null || seconds < 0) return '--:--';
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = remaining.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  factory VoiceMessageModel.fromJson(Map<String, dynamic> json) {
    return VoiceMessageModel(
      id: _parseInt(json['id']) ?? 0,
      name: (json['name'] as String?) ??
          (json['title'] as String?) ??
          (json['file_name'] as String?) ??
          '',
      fileUrl: (json['file_url'] as String?) ??
          (json['url'] as String?) ??
          (json['voice_file_url'] as String?) ??
          (json['path'] as String?) ??
          '',
      durationSeconds:
          _parseInt(json['duration']) ?? _parseInt(json['duration_seconds']),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'file_url': fileUrl,
      'duration': durationSeconds,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  VoiceMessageModel copyWith({
    int? id,
    String? name,
    String? fileUrl,
    int? durationSeconds,
    DateTime? createdAt,
  }) {
    return VoiceMessageModel(
      id: id ?? this.id,
      name: name ?? this.name,
      fileUrl: fileUrl ?? this.fileUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceMessageModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'VoiceMessageModel(id: $id, name: $name)';

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
