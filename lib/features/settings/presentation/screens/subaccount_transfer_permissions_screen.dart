import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';

/// Wave 9 — Sub-account transfer permissions.
///
/// `GET  /settings/sub-accounts/{id}/transfer-permissions`
/// `POST /settings/sub-accounts/{id}/transfer-permissions`
class SubAccountTransferPermissionsScreen extends ConsumerStatefulWidget {
  const SubAccountTransferPermissionsScreen({
    required this.subAccountId,
    super.key,
  });

  final int subAccountId;

  @override
  ConsumerState<SubAccountTransferPermissionsScreen> createState() =>
      _SubAccountTransferPermissionsScreenState();
}

class _SubAccountTransferPermissionsScreenState
    extends ConsumerState<SubAccountTransferPermissionsScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _allowTransfer = false;
  List<int> _allowedTargets = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ds = ref.read(settingsRemoteDatasourceProvider);
      final data = await ds.subAccountTransferPermissions(widget.subAccountId);
      if (!mounted) return;
      _allowTransfer = data['allow_transfer'] as bool? ?? false;
      final targets = data['allowed_targets'];
      _allowedTargets =
          targets is List ? targets.whereType<int>().toList() : const [];
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
      await ds.updateSubAccountTransferPermissions(
        id: widget.subAccountId,
        allowTransfer: _allowTransfer,
        allowedTargets: _allowedTargets,
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
        title: Text(t.translate('subaccountTransferPermissions')),
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
            title: Text(t.translate('subaccountAllowTransfer')),
            value: _allowTransfer,
            onChanged: (v) => setState(() => _allowTransfer = v),
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
          if (_allowedTargets.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${_allowedTargets.length} ${t.translate('subaccountTransferPermissions')}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
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
