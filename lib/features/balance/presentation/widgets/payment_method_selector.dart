import 'package:flutter/material.dart';

import 'package:orbit_app/core/constants/app_colors.dart';

/// A widget that displays payment method options in a grid.
///
/// Each method is a selectable card with an icon and label.
/// The currently selected method is highlighted with the primary color.
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    required this.selectedMethod,
    required this.onMethodSelected,
    super.key,
  });

  /// Currently selected payment method key.
  final String selectedMethod;

  /// Callback when a payment method is tapped.
  final ValueChanged<String> onMethodSelected;

  static const List<_PaymentMethodOption> _methods = [
    _PaymentMethodOption(
      key: 'online',
      label: '\u062F\u0641\u0639 \u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A',
      subtitle: 'Noon Payments',
      icon: Icons.credit_card,
    ),
    _PaymentMethodOption(
      key: 'bank_transfer',
      label: '\u062A\u062D\u0648\u064A\u0644 \u0628\u0646\u0643\u064A',
      subtitle: '\u062D\u0648\u0627\u0644\u0629 \u0645\u0635\u0631\u0641\u064A\u0629',
      icon: Icons.account_balance,
    ),
    _PaymentMethodOption(
      key: 'sadad',
      label: '\u0633\u062F\u0627\u062F',
      subtitle: 'SADAD',
      icon: Icons.payment,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '\u0637\u0631\u064A\u0642\u0629 \u0627\u0644\u062F\u0641\u0639',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.6,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _methods.length,
          itemBuilder: (context, index) {
            final method = _methods[index];
            final isSelected = selectedMethod == method.key;

            return GestureDetector(
              onTap: () => onMethodSelected(method.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primarySurface
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.borderLight,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      method.icon,
                      size: 28,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      method.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      method.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.7)
                            : AppColors.textHint,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PaymentMethodOption {
  const _PaymentMethodOption({
    required this.key,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  final String key;
  final String label;
  final String subtitle;
  final IconData icon;
}
