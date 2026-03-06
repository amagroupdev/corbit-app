/// Generic pagination wrapper that maps to Laravel's paginated JSON format.
///
/// The ORBIT SMS V3 API returns paginated data in the following shape:
/// ```json
/// {
///   "data": [ ... ],
///   "current_page": 1,
///   "per_page": 15,
///   "total": 42,
///   "last_page": 3,
///   "from": 1,
///   "to": 15
/// }
/// ```
///
/// The generic type [T] represents the type of each item in the `data`
/// list. Pass an [itemFromJson] deserializer to [PaginatedResponse.fromJson]
/// to automatically parse each item.
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
    this.from,
    this.to,
  });

  /// The list of items on the current page.
  final List<T> data;

  /// The current page number (1-indexed).
  final int currentPage;

  /// The number of items per page.
  final int perPage;

  /// The total number of items across all pages.
  final int total;

  /// The last page number.
  final int lastPage;

  /// The index of the first item on this page (1-indexed), or `null`
  /// if the page is empty.
  final int? from;

  /// The index of the last item on this page (1-indexed), or `null`
  /// if the page is empty.
  final int? to;

  /// Returns `true` if there are more pages after the current one.
  bool get hasMore => currentPage < lastPage;

  /// Returns `true` if this is the first page.
  bool get isFirstPage => currentPage == 1;

  /// Returns `true` if this is the last page.
  bool get isLastPage => currentPage >= lastPage;

  /// Returns `true` if the data list is empty.
  bool get isEmpty => data.isEmpty;

  /// Returns `true` if the data list is not empty.
  bool get isNotEmpty => data.isNotEmpty;

  /// The next page number, or `null` if already on the last page.
  int? get nextPage => hasMore ? currentPage + 1 : null;

  /// The previous page number, or `null` if already on the first page.
  int? get previousPage => currentPage > 1 ? currentPage - 1 : null;

  /// Total number of pages.
  int get totalPages => lastPage;

  /// Deserializes a JSON map into a [PaginatedResponse<T>].
  ///
  /// [json] is the decoded response body (or the nested pagination
  /// object within the response body).
  /// [itemFromJson] converts each raw item in the `data` array into
  /// the target type [T].
  ///
  /// Example:
  /// ```dart
  /// final paginated = PaginatedResponse<Contact>.fromJson(
  ///   responseData,
  ///   itemFromJson: (item) => Contact.fromJson(item as Map<String, dynamic>),
  /// );
  /// ```
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json, {
    required T Function(dynamic json) itemFromJson,
  }) {
    final rawData = json['data'];
    final List<T> items = rawData is List
        ? rawData.map((item) => itemFromJson(item)).toList()
        : <T>[];

    return PaginatedResponse<T>(
      data: items,
      currentPage: _parseInt(json['current_page']) ?? 1,
      perPage: _parseInt(json['per_page']) ?? 15,
      total: _parseInt(json['total']) ?? 0,
      lastPage: _parseInt(json['last_page']) ?? 1,
      from: _parseInt(json['from']),
      to: _parseInt(json['to']),
    );
  }

  /// Converts this pagination model back to a JSON map.
  ///
  /// [itemToJson] converts each item of type [T] into a JSON-serializable
  /// form. If omitted, items are included as-is.
  Map<String, dynamic> toJson({
    dynamic Function(T item)? itemToJson,
  }) {
    return {
      'data': itemToJson != null
          ? data.map((item) => itemToJson(item)).toList()
          : data,
      'current_page': currentPage,
      'per_page': perPage,
      'total': total,
      'last_page': lastPage,
      'from': from,
      'to': to,
    };
  }

  /// Creates a new [PaginatedResponse] by transforming each item with [convert].
  ///
  /// Useful for mapping from one model type to another (e.g. DTO -> domain).
  PaginatedResponse<R> map<R>(R Function(T item) convert) {
    return PaginatedResponse<R>(
      data: data.map(convert).toList(),
      currentPage: currentPage,
      perPage: perPage,
      total: total,
      lastPage: lastPage,
      from: from,
      to: to,
    );
  }

  /// Creates an empty [PaginatedResponse].
  factory PaginatedResponse.empty() {
    return const PaginatedResponse(
      data: [],
      currentPage: 1,
      perPage: 15,
      total: 0,
      lastPage: 1,
      from: null,
      to: null,
    );
  }

  // ─── Private helpers ──────────────────────────────────────────────

  /// Safely parses an integer from a dynamic value that might be an
  /// int, a double, or a numeric string.
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  String toString() =>
      'PaginatedResponse(page: $currentPage/$lastPage, '
      'perPage: $perPage, total: $total, items: ${data.length})';
}
