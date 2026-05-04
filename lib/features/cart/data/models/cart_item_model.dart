/// A single line item in the user's cart.
///
/// Maps to a cart item returned by `GET /cart`. Items can represent a
/// balance package, an addon/service, or a sender-name purchase.
class CartItemModel {
  const CartItemModel({
    required this.id,
    required this.itemType,
    required this.itemId,
    required this.title,
    this.subtitle,
    this.iconUrl,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    this.senderId,
    this.addonId,
    this.metadata = const {},
  });

  /// Cart item ID (used for delete).
  final int id;

  /// 'package' | 'service' | 'sender'
  final String itemType;

  /// The underlying entity ID (package id, addon id, sender id).
  final int itemId;

  /// Display title (e.g. "10,000 SMS").
  final String title;

  /// Optional subtitle (e.g. "Standard tier").
  final String? subtitle;

  /// Optional icon URL.
  final String? iconUrl;

  /// Per-unit price in SAR.
  final double unitPrice;

  /// Number of units (default 1).
  final int quantity;

  /// Line total in SAR (`unitPrice * quantity` after any per-line discount).
  final double lineTotal;

  /// Sender ID — only present for `itemType == 'sender'`.
  final int? senderId;

  /// Addon ID — only present for `itemType == 'service'`.
  final int? addonId;

  /// Any extra fields the server returned that we don't model.
  final Map<String, dynamic> metadata;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: _parseInt(json['id']) ?? 0,
      itemType: (json['item_type'] ?? json['type'] ?? '').toString(),
      itemId: _parseInt(json['item_id']) ?? _parseInt(json['id']) ?? 0,
      title: (json['title'] ?? json['name'] ?? '').toString(),
      subtitle: json['subtitle']?.toString() ??
          json['description']?.toString(),
      iconUrl: json['icon_url']?.toString() ?? json['icon']?.toString(),
      unitPrice: _parseDouble(json['unit_price'] ?? json['price']) ?? 0.0,
      quantity: _parseInt(json['quantity']) ?? 1,
      lineTotal: _parseDouble(
              json['line_total'] ?? json['total'] ?? json['amount']) ??
          0.0,
      senderId: _parseInt(json['sender_id']),
      addonId: _parseInt(json['addon_id']),
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : const {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'item_type': itemType,
        'item_id': itemId,
        'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (iconUrl != null) 'icon_url': iconUrl,
        'unit_price': unitPrice,
        'quantity': quantity,
        'line_total': lineTotal,
        if (senderId != null) 'sender_id': senderId,
        if (addonId != null) 'addon_id': addonId,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
