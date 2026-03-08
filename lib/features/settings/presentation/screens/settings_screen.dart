import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/settings/data/models/sub_account_model.dart';
import 'package:orbit_app/features/settings/presentation/controllers/settings_controller.dart';
import 'package:orbit_app/features/settings/presentation/widgets/settings_item.dart';
import 'package:orbit_app/features/settings/presentation/widgets/settings_section.dart';
import 'package:orbit_app/routing/route_names.dart';

/// Main settings screen with grouped list items organized by category.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // ── Profile Header ──────────────────────────────────────
            _buildProfileHeader(context, profileAsync),

            // ── الحساب (Account) ────────────────────────────────────
            SettingsSection(
              title: 'الحساب',
              icon: Icons.person_outline_rounded,
              children: [
                SettingsItem(
                  icon: Icons.person_rounded,
                  title: 'الملف الشخصي',
                  subtitle: 'تعديل البيانات الشخصية',
                  onTap: () => context.pushNamed(RouteNames.profile),
                ),
                SettingsItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'تغيير كلمة المرور',
                  subtitle: 'تحديث كلمة المرور الحالية',
                  onTap: () => context.pushNamed(RouteNames.changePassword),
                ),
              ],
            ),

            // ── الإدارة (Management) ────────────────────────────────
            SettingsSection(
              title: 'الإدارة',
              icon: Icons.admin_panel_settings_outlined,
              children: [
                SettingsItem(
                  icon: Icons.people_outline_rounded,
                  title: 'الحسابات الفرعية',
                  subtitle: 'إدارة المستخدمين الفرعيين',
                  onTap: () => context.pushNamed(RouteNames.subAccounts),
                ),
                SettingsItem(
                  icon: Icons.security_rounded,
                  title: 'الأدوار والصلاحيات',
                  subtitle: 'إدارة أدوار المستخدمين',
                  onTap: () => context.pushNamed(RouteNames.roles),
                ),
              ],
            ),

            // ── المالية (Financial) ─────────────────────────────────
            SettingsSection(
              title: 'المالية',
              icon: Icons.account_balance_wallet_outlined,
              children: [
                SettingsItem(
                  icon: Icons.receipt_long_rounded,
                  title: 'الفواتير',
                  subtitle: 'عرض وتحميل الفواتير',
                  onTap: () => context.pushNamed(RouteNames.invoices),
                ),
                SettingsItem(
                  icon: Icons.notifications_active_outlined,
                  title: 'تنبيه الرصيد',
                  subtitle: 'إعدادات التنبيه عند انخفاض الرصيد',
                  onTap: () => _showBalanceReminderSheet(context, ref),
                ),
              ],
            ),

            // ── التقنية (Technical) ─────────────────────────────────
            SettingsSection(
              title: 'التقنية',
              icon: Icons.code_rounded,
              children: [
                SettingsItem(
                  icon: Icons.vpn_key_rounded,
                  title: 'مفاتيح API',
                  subtitle: 'إدارة مفاتيح الوصول للواجهة البرمجية',
                  onTap: () => context.pushNamed(RouteNames.apiKeys),
                ),
              ],
            ),

            // ── المرسلين (Senders) ──────────────────────────────────
            SettingsSection(
              title: 'المرسلين',
              icon: Icons.send_rounded,
              children: [
                SettingsItem(
                  icon: Icons.badge_outlined,
                  title: 'أسماء المرسلين',
                  subtitle: 'طلب وإدارة أسماء المرسلين',
                  onTap: () => context.pushNamed(RouteNames.senderNames),
                ),
                SettingsItem(
                  icon: Icons.description_outlined,
                  title: 'العقود',
                  subtitle: 'إدارة العقود والمستندات',
                  onTap: () => context.pushNamed(RouteNames.contracts),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    AsyncValue<Map<String, dynamic>> profileAsync,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: profileAsync.when(
        data: (profile) => Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: profile['profile_photo_url'] != null &&
                      (profile['profile_photo_url'] as String).isNotEmpty
                  ? NetworkImage(profile['profile_photo_url'] as String)
                  : null,
              child: profile['profile_photo_url'] == null ||
                      (profile['profile_photo_url'] as String? ?? '').isEmpty
                  ? const Icon(Icons.person, size: 32, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile['name'] as String? ?? 'المستخدم',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile['email'] as String? ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => context.pushNamed(RouteNames.profile),
              icon: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        ),
        error: (_, __) => Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(Icons.person, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'المستخدم',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBalanceReminderSheet(BuildContext context, WidgetRef ref) {
    final reminderAsync = ref.read(balanceReminderProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BalanceReminderSheet(
        initialData: reminderAsync.valueOrNull,
      ),
    );
  }
}

/// Bottom sheet for editing balance reminder settings.
class _BalanceReminderSheet extends ConsumerStatefulWidget {
  const _BalanceReminderSheet({this.initialData});

  final BalanceReminderModel? initialData;

  @override
  ConsumerState<_BalanceReminderSheet> createState() =>
      _BalanceReminderSheetState();
}

class _BalanceReminderSheetState extends ConsumerState<_BalanceReminderSheet> {
  late bool _isEnabled;
  late final TextEditingController _thresholdController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.initialData?.isEnabled ?? false;
    _thresholdController = TextEditingController(
      text: (widget.initialData?.threshold ?? 0).toString(),
    );
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'تنبيه الرصيد',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'سيتم تنبيهك عندما ينخفض رصيدك عن الحد المحدد.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Enable toggle
            SwitchListTile(
              title: const Text(
                'تفعيل التنبيه',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              value: _isEnabled,
              onChanged: (value) => setState(() => _isEnabled = value),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),

            // Threshold input
            if (_isEnabled) ...[
              const Text(
                'الحد الأدنى للرصيد',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _thresholdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'مثال: 100',
                  hintStyle: const TextStyle(color: AppColors.inputHint),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'حفظ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final reminder = BalanceReminderModel(
        isEnabled: _isEnabled,
        threshold: int.tryParse(_thresholdController.text) ?? 0,
      );

      final success =
          await ref.read(balanceReminderProvider.notifier).updateReminder(reminder);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حفظ إعدادات التنبيه بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حدث خطأ أثناء الحفظ'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
