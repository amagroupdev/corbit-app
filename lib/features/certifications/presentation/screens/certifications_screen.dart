import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/certifications/data/models/certification_model.dart';
import 'package:orbit_app/features/certifications/data/repositories/certifications_repository.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';

/// Screen for managing certifications through the Noor system.
///
/// Provides Noor login, profile selection, send certification,
/// and an archive list.
class CertificationsScreen extends ConsumerStatefulWidget {
  const CertificationsScreen({super.key});

  @override
  ConsumerState<CertificationsScreen> createState() =>
      _CertificationsScreenState();
}

class _CertificationsScreenState extends ConsumerState<CertificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Noor login state
  bool _isLoggedIn = false;
  bool _isLoggingIn = false;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Profiles state
  List<NoorProfile> _profiles = [];
  int? _selectedProfileId;
  bool _profilesLoading = false;

  // Archive state
  List<CertificationModel> _archive = [];
  bool _archiveLoading = true;
  String? _archiveError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadArchive();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _noorLogin() async {
    if (_usernameController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('enterLoginCredentials')),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      final repo = ref.read(certificationsRepositoryProvider);
      await repo.noorLogin(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          _isLoggingIn = false;
        });
        _loadProfiles();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoggingIn = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _loadProfiles() async {
    setState(() => _profilesLoading = true);

    try {
      final repo = ref.read(certificationsRepositoryProvider);
      final profiles = await repo.getNoorProfiles();
      if (mounted) {
        setState(() {
          _profiles = profiles;
          _profilesLoading = false;
          if (profiles.isNotEmpty) {
            _selectedProfileId = profiles.first.id;
          }
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _profilesLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _loadArchive() async {
    setState(() {
      _archiveLoading = true;
      _archiveError = null;
    });

    try {
      final repo = ref.read(certificationsRepositoryProvider);
      final result = await repo.getArchive();
      if (mounted) {
        setState(() {
          _archive = result.data;
          _archiveLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _archiveError = e.message;
          _archiveLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('certifications')),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.translate('sendTab')),
            Tab(text: AppLocalizations.of(context)!.translate('archiveTab')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendTab(),
          _buildArchiveTab(),
        ],
      ),
    );
  }

  Widget _buildSendTab() {
    if (!_isLoggedIn) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Column(
                children: [
                  const Icon(Icons.school_outlined, size: 48, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.translate('noorLoginTitle'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: AppLocalizations.of(context)!.translate('username'),
                    hint: AppLocalizations.of(context)!.translate('enterUsername'),
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: AppLocalizations.of(context)!.translate('password'),
                    hint: AppLocalizations.of(context)!.translate('enterPassword'),
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 20),
                  AppButton.primary(
                    text: AppLocalizations.of(context)!.translate('login'),
                    onPressed: _noorLogin,
                    isLoading: _isLoggingIn,
                    icon: Icons.login_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_profilesLoading) return AppLoading.circular();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.successBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.translate('noorConnected'),
                  style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.translate('selectProfile'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ..._profiles.map(
            (profile) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _selectedProfileId = profile.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _selectedProfileId == profile.id ? AppColors.primarySurface : AppColors.surface,
                      border: Border.all(
                        color: _selectedProfileId == profile.id ? AppColors.primary : AppColors.border,
                        width: _selectedProfileId == profile.id ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedProfileId == profile.id ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: _selectedProfileId == profile.id ? AppColors.primary : AppColors.textHint,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              Text(profile.type, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppButton.primary(
            text: AppLocalizations.of(context)!.translate('sendCertifications'),
            onPressed: _selectedProfileId != null ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.translate('sendingCertifications')),
                  backgroundColor: AppColors.info,
                ),
              );
            } : null,
            icon: Icons.send_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveTab() {
    if (_archiveLoading) return AppLoading.listShimmer();
    if (_archiveError != null) {
      return AppErrorWidget(message: _archiveError!, onRetry: _loadArchive);
    }
    if (_archive.isEmpty) {
      return AppEmptyState(
        icon: Icons.school_outlined,
        title: AppLocalizations.of(context)!.translate('noCertifications'),
      );
    }

    final dateFormat = intl.DateFormat('yyyy/MM/dd', 'ar');

    return RefreshIndicator(
      onRefresh: _loadArchive,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _archive.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final cert = _archive[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.workspace_premium_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cert.recipientName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Text('${cert.recipientPhone} \u2022 ${dateFormat.format(cert.createdAt)}', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cert.isSent ? AppColors.successSurface : AppColors.warningSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    cert.isSent ? AppLocalizations.of(context)!.translate('sent') : AppLocalizations.of(context)!.translate('pending'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cert.isSent ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
