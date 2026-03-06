/// Data model representing an SMS offer package.
///
/// Maps to the JSON returned by GET /api/v3/balance/offers.
class OfferModel {
  const OfferModel({
    required this.id,
    this.title = '',
    this.description = '',
    this.price = 0,
    this.smsCredit = 0,
    this.addons = const [],
    this.expiredAt,
    this.isPopular = false,
  });

  /// Unique identifier.
  final int id;

  /// Offer title.
  final String title;

  /// Offer description.
  final String description;

  /// Offer price in SAR.
  final double price;

  /// Number of SMS credits included.
  final int smsCredit;

  /// List of addon descriptions included in this offer.
  final List<String> addons;

  /// When this offer expires.
  final DateTime? expiredAt;

  /// Whether this offer is highlighted as popular.
  final bool isPopular;

  /// Price per SMS for this offer.
  double get pricePerSms => smsCredit > 0 ? price / smsCredit : 0;

  /// Deserializes a JSON map into an [OfferModel].
  factory OfferModel.fromJson(Map<String, dynamic> json) {
    final rawAddons = json['addons'];
    List<String> parsedAddons = [];
    if (rawAddons is List) {
      parsedAddons = rawAddons.map((e) => e.toString()).toList();
    }

    return OfferModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: _parseDouble(json['price']) ?? 0,
      smsCredit: json['sms_credit'] as int? ?? 0,
      addons: parsedAddons,
      expiredAt: json['expired_at'] != null
          ? DateTime.tryParse(json['expired_at'].toString())
          : null,
      isPopular: json['is_popular'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'sms_credit': smsCredit,
      'addons': addons,
      'expired_at': expiredAt?.toIso8601String(),
      'is_popular': isPopular,
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
      'OfferModel(id: $id, title: $title, price: $price, smsCredit: $smsCredit)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfferModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
