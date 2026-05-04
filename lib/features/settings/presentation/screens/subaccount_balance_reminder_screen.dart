import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// Wave 9 — Balance reminder per sub-account.
///
/// `GET  /settings/sub-accounts/{id}/balance-reminder`
/// `POST /settings/sub-accounts/{id}/balance-reminder`
class SubAccountBalanceReminderScreen extends ConsumerStatefulWidget {
  const SubAccountBalanceReminderScreen({
    required this.subAccountId,
    super.key,
  });

  final int subAccountId;

  @override
  ConsumerState<SubAccountBalanceReminderScreen> createState() =>
      _SubAccountBalanceReminderScreenState();
}

class _SubAccountBalanceReminderScreenState
    extends ConsumerState<SubAccountBalanceReminderScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _enabled = false;
  final _thresholdController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ds = ref.read(settingsRemoteDatasourceProvider);
      final data = await ds.subAccountBalanceReminder(widget.subAccountId);
      if (!mounted) return;
      _enabled = data['is_enabled'] as bool? ?? false;
      _thresholdController.text = (data['threshold'] ?? '').toString();
      _emailController.text = data['email'] as String? ?? '';
      _phoneController.text = data['phone'] as String? ?? '';
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final ds = ref.read(settingsRemoteDatasourceProvider);
      await ds.updateSubAccountBalanceReminder(
        id: widget.subAccountId,
        isEnabled: _enabled,
        threshold: int.tryParse(_thresholdController.text.trim()) ?? 0,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
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
        title: Text(t.translate('subaccountBalanceReminder')),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _buildBody(t),
    );
  }

  Widget _buildBody(AppLocalizations t) {
    if (_loading) return AppLoading.circular();
    if (_error != null) {
      return AppErrorWidget(message: _error!, onRetry: _load);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            title: Text(t.translate('subaccountReminderEnabled')),
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          AppTextField(
            label: t.translate('subaccountReminderThreshold'),
            controller: _thresholdController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: t.translate('email'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: t.translate('phone'),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          AppButton.primary(
            text: t.translate('save'),
            icon: Icons.save_outlined,
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
