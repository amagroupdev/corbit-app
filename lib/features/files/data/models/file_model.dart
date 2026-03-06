/// Model representing an uploaded file in the ORBIT platform.
class FileModel {
  const FileModel({
    required this.id,
    required this.name,
    required this.size,
    required this.type,
    required this.url,
    required this.createdAt,
  });

  /// Unique identifier.
  final int id;

  /// Original file name.
  final String name;

  /// File size in bytes.
  final int size;

  /// MIME type (e.g. 'application/pdf', 'image/png').
  final String type;

  /// Download URL.
  final String url;

  /// When the file was uploaded.
  final DateTime createdAt;

  /// Human-readable file size.
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Returns the file extension from the name.
  String get extension {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) return '';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  /// Whether this is an image file.
  bool get isImage =>
      type.startsWith('image/') ||
      ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].contains(extension);

  /// Whether this is a PDF file.
  bool get isPdf => type == 'application/pdf' || extension == 'pdf';

  /// Whether this is an Excel file.
  bool get isExcel =>
      extension == 'xlsx' ||
      extension == 'xls' ||
      type.contains('spreadsheet');

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      url: json['url'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'type': type,
      'url': url,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'FileModel(id: $id, name: $name, size: $formattedSize)';
}
