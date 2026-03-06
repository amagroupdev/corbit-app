/// Generic wrapper for standard API JSON responses.
///
/// The ORBIT SMS V3 API returns responses in a consistent shape:
/// ```json
/// {
///   "success": true,
///   "message": "Operation completed.",
///   "data": { ... },
///   "errors": null
/// }
/// ```
///
/// The generic type [T] represents the shape of the `data` field.
/// Pass a [fromJsonT] deserializer to [ApiResponse.fromJson] so
/// the data field is automatically parsed into the target type.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  /// Whether the request was successful.
  final bool success;

  /// Human-readable message from the server (e.g. "Login successful").
  final String message;

  /// The payload returned by the server, deserialized to type [T].
  ///
  /// May be `null` for responses that carry no data (e.g. delete endpoints).
  final T? data;

  /// Field-level validation errors returned by the server.
  ///
  /// Keys are field names; values are lists of error messages.
  /// Only present when the server returns validation errors (HTTP 422).
  final Map<String, List<String>>? errors;

  /// Deserializes a JSON map into an [ApiResponse<T>].
  ///
  /// [json] is the decoded response body.
  /// [fromJsonT] is an optional function that converts the raw `data`
  /// value into the target type [T]. If omitted, the raw `data` value
  /// is cast directly to [T].
  ///
  /// Example with a model deserializer:
  /// ```dart
  /// final response = ApiResponse<User>.fromJson(
  ///   json,
  ///   fromJsonT: (data) => User.fromJson(data as Map<String, dynamic>),
  /// );
  /// ```
  ///
  /// Example without a deserializer (when data is a primitive or you
  /// want the raw map):
  /// ```dart
  /// final response = ApiResponse<Map<String, dynamic>>.fromJson(json);
  /// ```
  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic json)? fromJsonT,
  }) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      errors: _parseErrors(json['errors']),
    );
  }

  /// Converts this response back to a JSON map.
  ///
  /// [toJsonT] is an optional function that converts [data] to a
  /// JSON-serializable form. If omitted, [data] is included as-is.
  Map<String, dynamic> toJson({
    dynamic Function(T value)? toJsonT,
  }) {
    return {
      'success': success,
      'message': message,
      'data': data != null && toJsonT != null ? toJsonT(data as T) : data,
      'errors': errors,
    };
  }

  /// Returns `true` if the response contains field-level errors.
  bool get hasErrors => errors != null && errors!.isNotEmpty;

  /// Returns the first error message for a given [field], or `null`.
  String? firstErrorFor(String field) {
    final fieldErrors = errors?[field];
    if (fieldErrors == null || fieldErrors.isEmpty) return null;
    return fieldErrors.first;
  }

  /// Returns all error messages flattened into a single list.
  List<String> get allErrors {
    if (errors == null) return [];
    return errors!.values.expand((list) => list).toList();
  }

  // ─── Private helpers ──────────────────────────────────────────────

  /// Parses the `errors` field from the JSON response.
  ///
  /// Handles both:
  /// - `{ "email": ["The email is required."] }` (standard Laravel)
  /// - `{ "email": "The email is required." }` (simplified)
  static Map<String, List<String>>? _parseErrors(dynamic raw) {
    if (raw == null) return null;
    if (raw is! Map<String, dynamic>) return null;

    final Map<String, List<String>> parsed = {};
    for (final entry in raw.entries) {
      if (entry.value is List) {
        parsed[entry.key] =
            (entry.value as List).map((e) => e.toString()).toList();
      } else if (entry.value is String) {
        parsed[entry.key] = [entry.value as String];
      }
    }

    return parsed.isEmpty ? null : parsed;
  }

  @override
  String toString() =>
      'ApiResponse(success: $success, message: $message, data: $data, errors: $errors)';
}
