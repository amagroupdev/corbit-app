import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/balance/presentation/controllers/balance_controller.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// Screen for transferring balance to another user.
///
/// Features:
/// - Phone number input
/// - Amount input
/// - Confirm and send
/// - Transfer history list below
class TransferBalanceScreen extends ConsumerStatefulWidget {
  const TransferBalanceScreen({super.key});

  @override
  ConsumerState<TransferBalanceScreen> createState() =>
      _TransferBalanceScreenState();
}

class _TransferBalanceScreenState extends ConsumerState<TransferBalanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();

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
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t.translate('confirmTransfer'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          t.translateWithParams('transferConfirmMessage', {'amount': amount.toString(), 'phone': phone}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              t.translate('cancel'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              t.translate('confirm'),
              style: const TextStyle(
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
        SnackBar(
          content: Text(t.translate('transferSuccess')),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transferBalanceControllerProvider);
    final t = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');
    final numberFormat = NumberFormat('#,##0', 'ar');

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          t.translate('transferBalance'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transfer form
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
                    const SizedBox(height: 20),

                    // Phone field
                    AppTextField(
                      label: t.translate('recipientPhone'),
                      hint: '05xxxxxxxx',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return t.translate('phoneRequired');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Amount field
                    AppTextField(
                      label: t.translate('smsCountLabel'),
                      hint: t.translate('enterCount'),
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.sms_outlined, size: 20),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return t.translate('countRequired');
                        }
                        final amount = int.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return t.translate('enterValidCount');
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
                      text: t.translate('transferButton'),
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
            Text(
              t.translate('transferHistory'),
              style: const TextStyle(
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
                    Text(
                      t.translate('noPreviousTransfers'),
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
                          '${numberFormat.format(amount)} ${t.translate('messageUnit')}',
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
      ),
    );
  }
}
