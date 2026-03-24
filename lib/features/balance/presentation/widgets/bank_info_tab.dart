import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/balance/data/models/bank_model.dart';
import 'package:orbit_app/features/balance/presentation/controllers/balance_controller.dart';

/// Bank Info tab content.
///
/// Displays bank account details for manual transfers.
/// Each bank card shows bank name, account holder, account number, and IBAN.
class BankInfoTab extends ConsumerStatefulWidget {
  const BankInfoTab({super.key});

  @override
  ConsumerState<BankInfoTab> createState() => _BankInfoTabState();
}

class _BankInfoTabState extends ConsumerState<BankInfoTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(buyBalanceControllerProvider.notifier).loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(buyBalanceControllerProvider);
    final banks = state.banks;

    if (banks.isEmpty && state.priceTiers.isEmpty) {
      // Still loading initial data
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (banks.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            AppLocalizations.of(context)!.translate('bankInfoTitle'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.translate('bankInfoSubtitle'),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Bank cards
          ...banks.map((bank) => _BankCard(bank: bank)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.account_balance_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.translate('noBankInfo'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.translate('bankInfoNotAdded'),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card displaying a single bank's account details.
class _BankCard extends StatelessWidget {
  const _BankCard({required this.bank});

  final BankModel bank;

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${AppLocalizations.of(context)!.translate('copiedLabel')} $label'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bank header with logo
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: bank.logo != null && bank.logo!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          bank.logo!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.account_balance,
                            size: 24,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.account_balance,
                        size: 24,
                        color: AppColors.textSecondary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  bank.bankName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Divider
          Container(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 16),

          // Account holder name
          _buildInfoRow(
            context,
            icon: Icons.person_outline,
            label: AppLocalizations.of(context)!.translate('accountName'),
            value: bank.accountName,
          ),
          const SizedBox(height: 14),

          // Account number
          _buildInfoRow(
            context,
            icon: Icons.numbers_outlined,
            label: AppLocalizations.of(context)!.translate('accountNumber'),
            value: bank.accountNumber,
            copiable: true,
          ),
          const SizedBox(height: 14),

          // IBAN
          if (bank.iban.isNotEmpty)
            _buildInfoRow(
              context,
              icon: Icons.credit_card_outlined,
              label: 'IBAN',
              value: bank.iban,
              copiable: true,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool copiable = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
        if (copiable)
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 18),
            color: AppColors.primary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _copyToClipboard(context, value, label),
            tooltip: AppLocalizations.of(context)!.translate('copyTooltip'),
          ),
      ],
    );
  }
}
