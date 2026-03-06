import 'package:orbit_app/features/addons/data/models/subscription_plan_model.dart';

/// Represents an addon/service available in the ORBIT SMS platform.
///
/// Addons extend the platform's functionality and can be subscribed to
/// individually, with optional trial periods.
class AddonModel {
  const AddonModel({
    required this.id,
    required this.key,
    required this.name,
    required this.description,
    this.bannerUrl,
    this.isComingSoon = false,
    this.isFree = false,
    this.isActive = false,
    this.subscriptionPlans = const [],
  });

  /// Unique identifier.
  final int id;

  /// Machine-readable key (e.g. 'short_links', 'questionnaires').
  final String key;

  /// Display name of the addon.
  final String name;

  /// Full description of the addon's features and capabilities.
  final String description;

  /// URL of the addon's banner image, if available.
  final String? bannerUrl;

  /// Whether the addon is coming soon and not yet available.
  final bool isComingSoon;

  /// Whether the addon is free to use.
  final bool isFree;

  /// Whether the addon is currently active for this account.
  final bool isActive;

  /// Available subscription plans for this addon.
  final List<SubscriptionPlanModel> subscriptionPlans;

  /// Returns the cheapest available plan, or `null` if no plans exist.
  SubscriptionPlanModel? get cheapestPlan {
    if (subscriptionPlans.isEmpty) return null;
    return subscriptionPlans.reduce(
      (a, b) => a.price <= b.price ? a : b,
    );
  }

  factory AddonModel.fromJson(Map<String, dynamic> json) {
    final plansJson = json['subscription_plans'] as List<dynamic>? ?? [];
    return AddonModel(
      id: json['id'] as int? ?? 0,
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      bannerUrl: json['banner_url'] as String?,
      isComingSoon: json['is_coming_soon'] as bool? ?? false,
      isFree: json['is_free'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? false,
      subscriptionPlans: plansJson
          .map((e) => SubscriptionPlanModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'name': name,
      'description': description,
      'banner_url': bannerUrl,
      'is_coming_soon': isComingSoon,
      'is_free': isFree,
      'is_active': isActive,
      'subscription_plans': subscriptionPlans.map((e) => e.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddonModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AddonModel(id: $id, key: $key, name: $name)';
}
