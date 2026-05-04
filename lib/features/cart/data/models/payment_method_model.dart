import 'package:flutter/material.dart';

/// Identifier strings recognised by the server for the `payment_method`
/// field on `POST /cart/checkout`.
abstract final class CartPaymentMethods {
  static const String mada = 'mada';
  static const String visa = 'visa';
  static const String stcPay = 'stc_pay';
  static const String sadad = 'sadad';
  static const String bankTransfer = 'bank_transfer';

  /// All supported methods in display order.
  static const List<String> all = [
    mada,
    visa,
    stcPay,
    sadad,
    bankTransfer,
  ];
}

/// A presentational descriptor for a payment method.
@immutable
class CartPaymentMethodModel {
  const CartPaymentMethodModel({
    required this.id,
    required this.labelKey,
    required this.icon,
  });

  /// One of the strings from [CartPaymentMethods].
  final String id;

  /// Localization key for the human-readable label
  /// (e.g. `paymentMethodMada`).
  final String labelKey;

  /// Icon to render alongside the label.
  final IconData icon;

  /// The default catalogue used by the checkout screen.
  static const List<CartPaymentMethodModel> defaults = [
    CartPaymentMethodModel(
      id: CartPaymentMethods.mada,
      labelKey: 'paymentMethodMada',
      icon: Icons.credit_card,
    ),
    CartPaymentMethodModel(
      id: CartPaymentMethods.visa,
      labelKey: 'paymentMethodVisa',
      icon: Icons.credit_card_outlined,
    ),
    CartPaymentMethodModel(
      id: CartPaymentMethods.stcPay,
      labelKey: 'paymentMethodStcPay',
      icon: Icons.phone_iphone,
    ),
    CartPaymentMethodModel(
      id: CartPaymentMethods.sadad,
      labelKey: 'paymentMethodSadad',
      icon: Icons.account_balance,
    ),
    CartPaymentMethodModel(
      id: CartPaymentMethods.bankTransfer,
      labelKey: 'paymentMethodBank',
      icon: Icons.account_balance_wallet,
    ),
  ];
}
