import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/constants/feature_flags.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/certifications/data/repositories/certifications_repository.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// Wave 9 Certifications settings screen with Noor + Madrasati tabs.
///
/// - `GET  /certifications/settings`
/// - `POST /certifications/settings/noor`
/// - `POST /certifications/settings/madrasati`
class CertificationsSettingsScreen extends ConsumerStatefulWidget {
  const CertificationsSettingsScreen({super.key});

  @override
  ConsumerState<CertificationsSettingsScreen> createState() =>
      _CertificationsSettingsScreenState();
}

class _CertificationsSettingsScreenState
    extends ConsumerState<CertificationsSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _noorController = TextEditingController();
  final _madrasatiController = TextEditingController();

  bool _loading = true;
  String? _error;
  bool _savingNoor = false;
  bool _savingMadrasati = false;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: kMadrasatiEnabled ? 2 : 1, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noorController.dispose();
    _madrasatiController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(certificationsRepositoryProvider);
      final settings = await repo.getSettings();
      if (!mounted) return;
      _noorController.text = settings.noorMessageBody ?? '';
      _madrasatiController.text = settings.madrasatiMessageBody ?? '';
      setState(() => _loading = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _saveNoor() async {
    setState(() => _savingNoor = true);
    try {
      final repo = ref.read(certificationsRepositoryProvider);
      await repo.updateNoorSettings(messageBody: _noorController.text.trim());
      if (!mounted) return;
      setState(() => _savingNoor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!
              .translate('certificationsSettingsSaved')),
          backgroundColor: AppColors.success,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _savingNoor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _saveMadrasati() async {
    setState(() => _savingMadrasati = true);
    try {
      final repo = ref.read(certificationsRepositoryProvider);
      await repo.updateMadrasatiSettings(
          messageBody: _madrasatiController.text.trim());
      if (!mounted) return;
      setState(() => _savingMadrasati = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!
              .translate('certificationsSettingsSaved')),
          backgroundColor: AppColors.success,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _savingMadrasati = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(t.translate('certificationsSettings')),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: t.translate('certificationsSettingsNoor')),
            if (kMadrasatiEnabled)
              Tab(text: t.translate('certificationsSettingsMadrasati')),
          ],
        ),
      ),
      body: _buildBody(t),
    );
  }

  Widget _buildBody(AppLocalizations t) {
    if (_loading) return AppLoading.circular();
    if (_error != null) {
      return AppErrorWidget(message: _error!, onRetry: _load);
    }
    return TabBarView(
      controller: _tabController,
      children: [
        _platformPanel(
          controller: _noorController,
          saveLabel: t.translate('certificationsSettingsSaved'),
          isSaving: _savingNoor,
          onSave: _saveNoor,
          t: t,
        ),
        if (kMadrasatiEnabled)
          _platformPanel(
            controller: _madrasatiController,
            saveLabel: t.translate('certificationsSettingsSaved'),
            isSaving: _savingMadrasati,
            onSave: _saveMadrasati,
            t: t,
          ),
      ],
    );
  }

  Widget _platformPanel({
    required TextEditingController controller,
    required String saveLabel,
    required bool isSaving,
    required VoidCallback onSave,
    required AppLocalizations t,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: t.translate('certificationsSettingsMessageBody'),
            controller: controller,
            maxLines: 6,
          ),
          const SizedBox(height: 20),
          AppButton.primary(
            text: t.translate('save'),
            isLoading: isSaving,
            onPressed: onSave,
            icon: Icons.save_outlined,
          ),
        ],
      ),
    );
  }
}

