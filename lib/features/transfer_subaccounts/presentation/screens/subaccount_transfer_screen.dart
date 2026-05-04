import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/transfer_subaccounts/data/repositories/subaccount_transfer_repository.dart';
import 'package:orbit_app/routing/route_names.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// Form to send a balance transfer to another sub-account.
class SubaccountTransferScreen extends ConsumerStatefulWidget {
  const SubaccountTransferScreen({super.key});

  @override
  ConsumerState<SubaccountTransferScreen> createState() =>
      _SubaccountTransferScreenState();
}

class _SubaccountTransferScreenState
    extends ConsumerState<SubaccountTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            t?.translate('subaccountTransferTitle') ?? 'Sub-account Transfer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: t?.translate('subaccountTransferHistory') ?? 'History',
            onPressed: () =>
                context.pushNamed(RouteNames.subaccountTransferHistory),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppTextField(
                controller: _fromController,
                label: t?.translate('subaccountTransferFrom') ??
                    'From username',
                validator: _required(t),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _toController,
                label: t?.translate('subaccountTransferTo') ?? 'To username',
                validator: _required(t),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _amountController,
                label: t?.translate('subaccountTransferAmount') ?? 'Amount',
                keyboardType: TextInputType.number,
                validator: (v) {
                  final base = _required(t)(v);
                  if (base != null) return base;
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) {
                    return t?.translate('invalidAmount') ?? 'Invalid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              AppButton.primary(
                text: t?.translate('subaccountTransferConfirm') ?? 'Confirm',
                isLoading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? Function(String?) _required(AppLocalizations? t) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return t?.translate('fieldRequired') ?? 'Required';
      }
      return null;
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final repo = ref.read(subaccountTransferRepositoryProvider);
    final result = await repo.transfer(
      fromUsername: _fromController.text.trim(),
      toUsername: _toController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (result.isSuccess) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(t?.translate('subaccountTransferSuccess') ??
              'Transfer successful'),
        ),
      );
      _amountController.clear();
      _noteController.clear();
    } else {
      messenger?.showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(result.error ?? t?.translate('error') ?? 'Error'),
        ),
      );
    }
  }
}
