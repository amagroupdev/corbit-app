import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/balance/data/models/transaction_model.dart';

/// A card widget displaying a single transaction in the list.
///
/// Shows the amount, status badge, payment method, and date.
class TransactionCard extends StatelessWidget {
  const TransactionCard({
    required this.transaction,
    this.onTap,
    super.key,
  });

  final TransactionModel transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');
    final numberFormat = NumberFormat('#,##0', 'ar');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _statusIcon,
                size: 22,
                color: _statusColor,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${numberFormat.format(transaction.amount.toInt())} \u0631.\u0633',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      _buildStatusBadge(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _paymentMethodIcon,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        transaction.paymentMethodLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (transaction.smsCount > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '\u2022 ${numberFormat.format(transaction.smsCount)} SMS',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (transaction.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(transaction.createdAt!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        transaction.statusLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _statusColor,
        ),
      ),
    );
  }

  Color get _statusColor {
    return switch (transaction.status.toLowerCase()) {
      'approved' => AppColors.success,
      'pending' => AppColors.warning,
      'waiting' => AppColors.info,
      'rejected' => AppColors.error,
      _ => AppColors.textSecondary,
    };
  }

  IconData get _statusIcon {
    return switch (transaction.status.toLowerCase()) {
      'approved' => Icons.check_circle_outline,
      'pending' => Icons.access_time,
      'waiting' => Icons.hourglass_empty,
      'rejected' => Icons.cancel_outlined,
      _ => Icons.receipt_outlined,
    };
  }

  IconData get _paymentMethodIcon {
    return switch (transaction.paymentMethod.toLowerCase()) {
      'online' => Icons.credit_card,
      'bank_transfer' => Icons.account_balance,
      'stc_pay' => Icons.phone_android,
      'sadad' => Icons.payment,
      _ => Icons.payment,
    };
  }
}
