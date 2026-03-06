/// Data model representing a bank available for bank transfer payments.
///
/// Maps to the JSON returned by GET /api/v3/balance/banks.
class BankModel {
  const BankModel({
    required this.id,
    this.bankName = '',
    this.accountName = '',
    this.accountNumber = '',
    this.iban = '',
    this.logo,
  });

  /// Unique identifier.
  final int id;

  /// Name of the bank (e.g. "Al Rajhi Bank").
  final String bankName;

  /// Account holder name.
  final String accountName;

  /// Bank account number.
  final String accountNumber;

  /// IBAN number.
  final String iban;

  /// URL to the bank's logo image.
  final String? logo;

  /// Deserializes a JSON map into a [BankModel].
  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      id: json['id'] as int? ?? 0,
      bankName: json['bank_name'] as String? ?? '',
      accountName: json['account_name'] as String? ?? '',
      accountNumber: json['account_number'] as String? ?? '',
      iban: json['iban'] as String? ?? '',
      logo: json['logo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bank_name': bankName,
      'account_name': accountName,
      'account_number': accountNumber,
      'iban': iban,
      'logo': logo,
    };
  }

  @override
  String toString() => 'BankModel(id: $id, bankName: $bankName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
