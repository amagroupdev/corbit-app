import 'package:flutter/material.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/cart/data/models/cart_model.dart';

/// Renders the totals (subtotal / discount / total) for the cart screen.
class CartSummaryCard extends StatelessWidget {
  const CartSummaryCard({super.key, required this.cart});

  final CartModel cart;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Column(
        children: [
          _row(
            theme,
            label: t?.translate('cartSubtotal') ?? 'Subtotal',
            value: cart.subtotal,
            currency: cart.currency,
          ),
          if (cart.discount > 0) ...[
            const SizedBox(height: 8),
            _row(
              theme,
              label: t?.translate('cartDiscount') ?? 'Discount',
              value: -cart.discount,
              currency: cart.currency,
              valueColor: theme.colorScheme.error,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _row(
            theme,
            label: t?.translate('cartTotal') ?? 'Total',
            value: cart.total,
            currency: cart.currency,
            bold: true,
            big: true,
          ),
        ],
      ),
    );
  }

  Widget _row(
    ThemeData theme, {
    required String label,
    required double value,
    required String currency,
    Color? valueColor,
    bool bold = false,
    bool big = false,
  }) {
    final style = (big
            ? theme.textTheme.titleMedium
            : theme.textTheme.bodyMedium)
        ?.copyWith(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      color: valueColor,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          '${value.toStringAsFixed(2)} $currency',
          style: style?.copyWith(
            color: valueColor ?? (bold ? AppColors.primary : null),
          ),
        ),
      ],
    );
  }
}
