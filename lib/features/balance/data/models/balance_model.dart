/// Data model for the user's current balance.
///
/// Maps to the JSON returned by GET /api/v3/balance/current
/// and GET /api/v3/balance/summary.
class BalanceModel {
  const BalanceModel({
    this.balance = 0,
    this.formattedBalance = '0',
    this.expiredAt,
    this.remainingDays = 0,
    this.totalSent = 0,
    this.totalPurchased = 0,
    this.totalTransferred = 0,
    this.currency = 'SAR',
  });

  /// Current SMS credit balance.
  final double balance;

  /// Formatted balance string for display.
  final String formattedBalance;

  /// When the current balance package expires.
  final DateTime? expiredAt;

  /// Number of days remaining until expiry.
  final int remainingDays;

  /// Total messages sent (consumed).
  final int totalSent;

  /// Total amount purchased.
  final double totalPurchased;

  /// Total balance transferred to others.
  final int totalTransferred;

  /// Currency code.
  final String currency;

  /// Deserializes a JSON map into a [BalanceModel].
  factory BalanceModel.fromJson(Map<String, dynamic> json) {
    return BalanceModel(
      balance: _parseDouble(json['balance']) ?? 
               _parseDouble(json['current_balance']) ?? 0,
      formattedBalance: json['formatted_balance']?.toString() ??
          json['balance']?.toString() ??
          '0',
      expiredAt: json['expired_at'] != null
          ? DateTime.tryParse(json['expired_at'].toString())
          : (json['expiry_date'] != null
              ? DateTime.tryParse(json['expiry_date'].toString())
              : null),
      remainingDays: json['remaining_days'] as int? ?? 0,
      // API returns 'total_used' not 'total_sent'
      totalSent: json['total_sent'] as int? ?? 
                 json['total_used'] as int? ?? 0,
      totalPurchased: _parseDouble(json['total_purchased']) ?? 0,
      totalTransferred: json['total_transferred'] as int? ?? 
                        json['transferred'] as int? ?? 
                        json['transferred_balance'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'SAR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'formatted_balance': formattedBalance,
      'expired_at': expiredAt?.toIso8601String(),
      'remaining_days': remainingDays,
      'total_sent': totalSent,
      'total_purchased': totalPurchased,
      'total_transferred': totalTransferred,
      'currency': currency,
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
      'BalanceModel(balance: $balance, remainingDays: $remainingDays)';
}

/// Model for the balance summary endpoint.
class BalanceSummaryModel {
  const BalanceSummaryModel({
    this.currentBalance = 0,
    this.totalSent = 0,
    this.totalPurchased = 0,
    this.totalTransferred = 0,
    this.expiredAt,
    this.remainingDays = 0,
  });

  final double currentBalance;
  final int totalSent;
  final double totalPurchased;
  final int totalTransferred;
  final DateTime? expiredAt;
  final int remainingDays;

  factory BalanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return BalanceSummaryModel(
      currentBalance: _parseDouble(json['current_balance']) ?? 
                      _parseDouble(json['balance']) ?? 0,
      // API returns 'total_used', not 'total_sent'.
      totalSent: json['total_sent'] as int? ?? json['total_used'] as int? ?? 0,
      totalPurchased: _parseDouble(json['total_purchased']) ?? 0,
      totalTransferred: json['total_transferred'] as int? ?? 
                        json['transferred'] as int? ?? 
                        json['transferred_balance'] as int? ?? 0,
      expiredAt: json['expired_at'] != null
          ? DateTime.tryParse(json['expired_at'].toString())
          : (json['expiry_date'] != null
              ? DateTime.tryParse(json['expiry_date'].toString())
              : null),
      remainingDays: json['remaining_days'] as int? ?? 0,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
