import 'package:flutter/material.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/cart/data/models/payment_method_model.dart';

/// Vertical list of [CartPaymentMethodModel] tiles. Tapping a tile
/// emits the selection through [onSelected].
class CartPaymentMethodSelector extends StatelessWidget {
  const CartPaymentMethodSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.methods = CartPaymentMethodModel.defaults,
  });

  final String selected;
  final ValueChanged<String> onSelected;
  final List<CartPaymentMethodModel> methods;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final method in methods) ...[
          _Tile(
            method: method,
            label: t?.translate(method.labelKey) ?? method.labelKey,
            isSelected: method.id == selected,
            onTap: () => onSelected(method.id),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.method,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final CartPaymentMethodModel method;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.primaryBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(method.icon,
                color: isSelected ? AppColors.primary : Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : null,
                ),
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
