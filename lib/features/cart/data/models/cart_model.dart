import 'package:orbit_app/features/cart/data/models/cart_item_model.dart';
import 'package:orbit_app/features/cart/data/models/coupon_model.dart';

/// The user's full shopping cart returned by `GET /cart`.
class CartModel {
  const CartModel({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    this.coupon,
    this.currency = 'SAR',
  });

  /// Cart server-side ID.
  final int id;

  /// Line items currently in the cart.
  final List<CartItemModel> items;

  /// Sum of all line totals before discount.
  final double subtotal;

  /// Discount applied (coupon, promotions). Always ≥ 0.
  final double discount;

  /// Final total = subtotal - discount.
  final double total;

  /// Currently applied coupon, or null if none.
  final CouponModel? coupon;

  /// Currency code (defaults to "SAR").
  final String currency;

  /// Returns true when the cart has no items.
  bool get isEmpty => items.isEmpty;

  /// Returns true when the cart has items.
  bool get isNotEmpty => items.isNotEmpty;

  /// Number of items in the cart.
  int get itemCount => items.length;

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final List<CartItemModel> items = rawItems is List
        ? rawItems
            .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
            .toList()
        : <CartItemModel>[];

    final couponJson = json['coupon'];
    final CouponModel? coupon =
        couponJson is Map<String, dynamic> ? CouponModel.fromJson(couponJson) : null;

    return CartModel(
      id: _parseInt(json['id']) ?? 0,
      items: items,
      subtotal: _parseDouble(json['subtotal']) ?? 0.0,
      discount: _parseDouble(json['discount']) ?? 0.0,
      total: _parseDouble(json['total']) ?? 0.0,
      coupon: coupon,
      currency: (json['currency'] ?? 'SAR').toString(),
    );
  }

  /// Empty (default) cart.
  factory CartModel.empty() => const CartModel(
        id: 0,
        items: [],
        subtotal: 0.0,
        discount: 0.0,
        total: 0.0,
      );

  CartModel copyWith({
    int? id,
    List<CartItemModel>? items,
    double? subtotal,
    double? discount,
    double? total,
    CouponModel? coupon,
    bool clearCoupon = false,
    String? currency,
  }) {
    return CartModel(
      id: id ?? this.id,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      coupon: clearCoupon ? null : (coupon ?? this.coupon),
      currency: currency ?? this.currency,
    );
  }

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
