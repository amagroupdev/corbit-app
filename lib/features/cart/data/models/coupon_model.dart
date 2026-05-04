/// Represents a coupon that has been applied to the cart.
class CouponModel {
  const CouponModel({
    required this.code,
    required this.discountAmount,
    this.discountType = 'fixed',
    this.description,
  });

  /// The coupon code (e.g. "WELCOME20").
  final String code;

  /// Discount applied to the cart in SAR.
  final double discountAmount;

  /// 'fixed' | 'percentage' (default 'fixed')
  final String discountType;

  /// Optional human-readable description.
  final String? description;

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      code: (json['code'] ?? '').toString(),
      discountAmount: _parseDouble(
              json['discount_amount'] ?? json['amount'] ?? json['value']) ??
          0.0,
      discountType: (json['discount_type'] ?? json['type'] ?? 'fixed')
          .toString(),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'discount_amount': discountAmount,
        'discount_type': discountType,
        if (description != null) 'description': description,
      };

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
