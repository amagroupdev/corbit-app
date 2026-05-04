import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// Wave 9 — Annual balance configuration for a sub-account.
///
/// `POST   /settings/sub-accounts/{id}/annual-balance`
/// `DELETE /settings/sub-accounts/{id}/annual-balance/{year}`
class SubAccountAnnualBalanceScreen extends ConsumerStatefulWidget {
  const SubAccountAnnualBalanceScreen({
    required this.subAccountId,
    super.key,
  });

  final int subAccountId;

  @override
  ConsumerState<SubAccountAnnualBalanceScreen> createState() =>
      _SubAccountAnnualBalanceScreenState();
}

class _SubAccountAnnualBalanceScreenState
    extends ConsumerState<SubAccountAnnualBalanceScreen> {
  final _yearController =
      TextEditingController(text: '${DateTime.now().year}');
  final _amountController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _yearController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final year = int.tryParse(_yearController.text.trim());
    final amount = double.tryParse(_amountController.text.trim());
    if (year == null || amount == null) return;

    setState(() => _busy = true);
    try {
      final ds = ref.read(settingsRemoteDatasourceProvider);
      await ds.subAccountAnnualBalance(
        id: widget.subAccountId,
        year: year,
        amount: amount,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _deleteYear() async {
    final year = int.tryParse(_yearController.text.trim());
    if (year == null) return;
    setState(() => _busy = true);
    try {
      final ds = ref.read(settingsRemoteDatasourceProvider);
      await ds.subAccountAnnualBalanceDelete(
        id: widget.subAccountId,
        year: year,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(t.translate('subaccountAnnualBalance')),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: t.translate('subaccountAnnualBalanceYear'),
              controller: _yearController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: t.translate('subaccountAnnualBalance'),
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            AppButton.primary(
              text: t.translate('save'),
              icon: Icons.save_outlined,
              isLoading: _busy,
              onPressed: _busy ? null : _save,
            ),
            const SizedBox(height: 12),
            AppButton.secondary(
              text: t.translate('delete'),
              icon: Icons.delete_outline,
              onPressed: _busy ? null : _deleteYear,
            ),
          ],
        ),
      ),
    );
  }
}
