/// Data model representing a price tier for SMS purchases.
///
/// Maps to the JSON returned by GET /api/v3/balance/prices.
class PriceTierModel {
  const PriceTierModel({
    required this.id,
    this.name = '',
    this.fromAmount = 0,
    this.toAmount = 0,
    this.pricePerSms = 0,
  });

  /// Unique identifier.
  final int id;

  /// Tier display name (e.g. "Basic", "Premium").
  final String name;

  /// Minimum amount for this tier.
  final int fromAmount;

  /// Maximum amount for this tier.
  final int toAmount;

  /// Cost per SMS in this tier (SAR).
  final double pricePerSms;

  /// Deserializes a JSON map into a [PriceTierModel].
  factory PriceTierModel.fromJson(Map<String, dynamic> json) {
    return PriceTierModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      fromAmount: json['from_amount'] as int? ?? 0,
      toAmount: json['to_amount'] as int? ?? 0,
      pricePerSms: _parseDouble(json['price_per_sms']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'from_amount': fromAmount,
      'to_amount': toAmount,
      'price_per_sms': pricePerSms,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  String toString() =>
      'PriceTierModel(id: $id, name: $name, pricePerSms: $pricePerSms)';
}
