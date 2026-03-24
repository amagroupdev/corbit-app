import 'package:flutter/material.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';

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
      labelKey: 'onlinePayment',
      subtitleKey: 'onlinePaymentNoon',
      icon: Icons.credit_card,
    ),
    _PaymentMethodOption(
      key: 'bank_transfer',
      labelKey: 'bankTransfer',
      subtitleKey: 'bankTransferRemittance',
      icon: Icons.account_balance,
    ),
    _PaymentMethodOption(
      key: 'sadad',
      labelKey: 'sadad',
      subtitleKey: 'sadad',
      icon: Icons.payment,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('paymentMethod'),
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
            final t = AppLocalizations.of(context)!;
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
                            color: AppColors.primary.withOpacity(0.1),
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
                      t.translate(method.labelKey),
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
                      t.translate(method.subtitleKey),
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.7)
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
    required this.labelKey,
    required this.subtitleKey,
    required this.icon,
  });

  final String key;
  final String labelKey;
  final String subtitleKey;
  final IconData icon;
}
