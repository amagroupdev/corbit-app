import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/balance/presentation/controllers/balance_controller.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// Transfer Balance tab content.
///
/// Provides a form to transfer SMS balance to sub-accounts:
/// - Phone number input
/// - Amount input
/// - Confirm transfer
/// - Transfer history below the form
class TransferBalanceTab extends ConsumerStatefulWidget {
  const TransferBalanceTab({super.key});

  @override
  ConsumerState<TransferBalanceTab> createState() =>
      _TransferBalanceTabState();
}

class _TransferBalanceTabState extends ConsumerState<TransferBalanceTab>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transferBalanceControllerProvider.notifier).loadHistory();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;

    if (amount <= 0) return;

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '\u062A\u0623\u0643\u064A\u062F \u0627\u0644\u062A\u062D\u0648\u064A\u0644',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '\u0647\u0644 \u062A\u0631\u064A\u062F \u062A\u062D\u0648\u064A\u0644 $amount \u0631\u0633\u0627\u0644\u0629 \u0625\u0644\u0649 \u0627\u0644\u0631\u0642\u0645 $phone\u061F',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              '\u0625\u0644\u063A\u0627\u0621',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              '\u062A\u0623\u0643\u064A\u062F',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ref
        .read(transferBalanceControllerProvider.notifier)
        .transfer(phoneNumber: phone, amount: amount);

    if (success && mounted) {
      _phoneController.clear();
      _amountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('\u062A\u0645 \u0627\u0644\u062A\u062D\u0648\u064A\u0644 \u0628\u0646\u062C\u0627\u062D'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(transferBalanceControllerProvider);
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');
    final numberFormat = NumberFormat('#,##0', 'ar');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transfer form card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon header
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.swap_horiz,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      '\u062A\u062D\u0648\u064A\u0644 \u0631\u0635\u064A\u062F \u0625\u0644\u0649 \u062D\u0633\u0627\u0628 \u0641\u0631\u0639\u064A',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Phone field
                  AppTextField(
                    label: '\u0631\u0642\u0645 \u0627\u0644\u0647\u0627\u062A\u0641 \u0627\u0644\u0645\u0633\u062A\u0644\u0645',
                    hint: '05xxxxxxxx',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '\u0631\u0642\u0645 \u0627\u0644\u0647\u0627\u062A\u0641 \u0645\u0637\u0644\u0648\u0628';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Amount field
                  AppTextField(
                    label: '\u0639\u062F\u062F \u0627\u0644\u0631\u0633\u0627\u0626\u0644',
                    hint: '\u0623\u062F\u062E\u0644 \u0627\u0644\u0639\u062F\u062F',
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.sms_outlined, size: 20),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '\u0627\u0644\u0639\u062F\u062F \u0645\u0637\u0644\u0648\u0628';
                      }
                      final amount = int.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return '\u0623\u062F\u062E\u0644 \u0639\u062F\u062F\u0627\u064B \u0635\u062D\u064A\u062D\u0627\u064B';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Error
                  if (state.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.error!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.errorDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Transfer button
                  AppButton.primary(
                    text: '\u062A\u062D\u0648\u064A\u0644',
                    onPressed:
                        state.isTransferring ? null : _handleTransfer,
                    isLoading: state.isTransferring,
                    icon: Icons.send,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Transfer history
          const Text(
            '\u0633\u062C\u0644 \u0627\u0644\u062A\u062D\u0648\u064A\u0644\u0627\u062A',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          if (state.isLoadingHistory)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          else if (state.history.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.history_outlined,
                    size: 40,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '\u0644\u0627 \u062A\u0648\u062C\u062F \u062A\u062D\u0648\u064A\u0644\u0627\u062A \u0633\u0627\u0628\u0642\u0629',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ...state.history.map(
              (item) {
                final phone = item['phone']?.toString() ?? '';
                final amount = item['amount'] ?? 0;
                final createdAt = item['created_at'] != null
                    ? DateTime.tryParse(item['created_at'].toString())
                    : null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.infoSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          size: 20,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              phone,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              textDirection: TextDirection.ltr,
                            ),
                            if (createdAt != null)
                              Text(
                                dateFormat.format(createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${numberFormat.format(amount)} \u0631\u0633\u0627\u0644\u0629',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
