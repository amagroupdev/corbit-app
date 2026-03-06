/// Represents a subscription plan for an addon/service.
///
/// Each addon can have multiple subscription plans with different
/// durations, prices, and trial periods.
class SubscriptionPlanModel {
  const SubscriptionPlanModel({
    required this.id,
    required this.price,
    required this.validDays,
    this.trialDays = 0,
  });

  /// Unique identifier.
  final int id;

  /// Price of the plan in SAR.
  final double price;

  /// Number of days the plan is valid for.
  final int validDays;

  /// Number of free trial days (0 means no trial).
  final int trialDays;

  /// Whether this plan offers a free trial.
  bool get hasTrial => trialDays > 0;

  /// Human-readable duration label.
  String get durationLabel {
    if (validDays >= 365) {
      final years = validDays ~/ 365;
      return years == 1
          ? '\u0633\u0646\u0629 \u0648\u0627\u062D\u062F\u0629' // سنة واحدة
          : '$years \u0633\u0646\u0648\u0627\u062A'; // سنوات
    }
    if (validDays >= 30) {
      final months = validDays ~/ 30;
      return months == 1
          ? '\u0634\u0647\u0631 \u0648\u0627\u062D\u062F' // شهر واحد
          : '$months \u0623\u0634\u0647\u0631'; // أشهر
    }
    return '$validDays \u064A\u0648\u0645'; // يوم
  }

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] as int? ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      validDays: json['valid_days'] as int? ?? 0,
      trialDays: json['trial_days'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'price': price,
      'valid_days': validDays,
      'trial_days': trialDays,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPlanModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SubscriptionPlanModel(id: $id, price: $price, validDays: $validDays)';
}
