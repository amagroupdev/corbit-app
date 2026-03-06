import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/utils/validators.dart';
import 'package:orbit_app/features/settings/data/models/sub_account_model.dart';
import 'package:orbit_app/features/settings/presentation/controllers/settings_controller.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_search_bar.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// Screen for managing sub-accounts: list, create, edit, delete, toggle status.
class SubAccountsScreen extends ConsumerStatefulWidget {
  const SubAccountsScreen({super.key});

  @override
  ConsumerState<SubAccountsScreen> createState() => _SubAccountsScreenState();
}

class _SubAccountsScreenState extends ConsumerState<SubAccountsScreen> {
  @override
  Widget build(BuildContext context) {
    final subAccountsAsync = ref.watch(subAccountsProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('الحسابات الفرعية'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSearchBar(
              hint: 'بحث في الحسابات الفرعية...',
              onChanged: (query) {
                ref.read(subAccountsProvider.notifier).search(query);
              },
            ),
          ),

          // List
          Expanded(
            child: subAccountsAsync.when(
              data: (paginated) {
                if (paginated.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'لا توجد حسابات فرعية',
                    description: 'اضغط على زر + لإنشاء حساب فرعي جديد',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(subAccountsProvider.notifier).refresh(),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: paginated.data.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final account = paginated.data[index];
                      return _SubAccountCard(
                        account: account,
                        onToggleStatus: () => _toggleStatus(account.id),
                        onDelete: () => _deleteAccount(account.id),
                        onTap: () => _showEditSheet(context, account),
                      );
                    },
                  ),
                );
              },
              loading: () => AppLoading.listShimmer(),
              error: (error, _) => AppErrorWidget(
                message: error.toString(),
                onRetry: () =>
                    ref.read(subAccountsProvider.notifier).refresh(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(int id) async {
    try {
      await ref.read(subAccountsProvider.notifier).toggleStatus(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteAccount(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب الفرعي'),
        content: const Text('هل أنت متأكد من حذف هذا الحساب الفرعي؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(subAccountsProvider.notifier).delete(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الحساب الفرعي'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('خطأ: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SubAccountFormSheet(),
    );
  }

  void _showEditSheet(BuildContext context, SubAccountModel account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SubAccountFormSheet(account: account),
    );
  }
}

// ── Sub-Account Card ─────────────────────────────────────────────────────

class _SubAccountCard extends StatelessWidget {
  const _SubAccountCard({
    required this.account,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onTap,
  });

  final SubAccountModel account;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(account.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(
                    (account.name ?? '?').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name ?? 'غير محدد',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        account.email ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (account.role != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.infoSurface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            account.role!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Status toggle
                Switch(
                  value: account.isActive,
                  onChanged: (_) => onToggleStatus(),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-Account Form Sheet ───────────────────────────────────────────────

class _SubAccountFormSheet extends ConsumerStatefulWidget {
  const _SubAccountFormSheet({this.account});

  final SubAccountModel? account;

  @override
  ConsumerState<_SubAccountFormSheet> createState() =>
      _SubAccountFormSheetState();
}

class _SubAccountFormSheetState extends ConsumerState<_SubAccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _apiAccess = false;
  bool _isActive = true;
  bool _isLoading = false;
  bool _showOtpField = false;
  int? _createdUserId;
  final _otpController = TextEditingController();

  bool get isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final a = widget.account!;
      _nameController.text = a.name ?? '';
      _emailController.text = a.email ?? '';
      _phoneController.text = a.phone ?? '';
      _apiAccess = a.apiAccess;
      _isActive = a.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
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

              Text(
                isEditing ? 'تعديل الحساب الفرعي' : 'إنشاء حساب فرعي',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              if (_showOtpField) ...[
                // OTP verification
                const Text(
                  'تم إرسال رمز التحقق إلى الجوال',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'رمز التحقق',
                  hint: 'أدخل رمز التحقق',
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      Validators.validateRequired(v, fieldName: 'رمز التحقق'),
                ),
                const SizedBox(height: 24),
                AppButton.primary(
                  text: 'تحقق',
                  onPressed: _isLoading ? null : _verifyOtp,
                  isLoading: _isLoading,
                ),
              ] else ...[
                AppTextField(
                  label: 'الاسم',
                  hint: 'أدخل الاسم',
                  controller: _nameController,
                  validator: (v) =>
                      Validators.validateRequired(v, fieldName: 'الاسم'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'البريد الإلكتروني',
                  hint: 'example@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'رقم الجوال',
                  hint: '05XXXXXXXX',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                if (!isEditing) ...[
                  AppTextField(
                    label: 'كلمة المرور',
                    hint: 'أدخل كلمة المرور',
                    controller: _passwordController,
                    obscureText: true,
                    validator: Validators.validatePassword,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                ],

                // API Access toggle
                SwitchListTile(
                  title: const Text(
                    'صلاحية API',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'السماح بالوصول عبر الواجهة البرمجية',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _apiAccess,
                  onChanged: (v) => setState(() => _apiAccess = v),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),

                // Active toggle
                SwitchListTile(
                  title: const Text(
                    'نشط',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),

                AppButton.primary(
                  text: isEditing ? 'حفظ التغييرات' : 'إنشاء',
                  onPressed: _isLoading ? null : _submit,
                  isLoading: _isLoading,
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'api_access': _apiAccess,
        'is_active': _isActive,
        if (!isEditing) 'password': _passwordController.text,
      };

      if (isEditing) {
        final result = await ref
            .read(subAccountsProvider.notifier)
            .updateSubAccount(widget.account!.id, data);
        final success = result['success'] as bool? ?? false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success ? 'تم تحديث الحساب الفرعي' : 'فشل التحديث',
              ),
              backgroundColor: success ? AppColors.success : AppColors.error,
            ),
          );
          if (success) Navigator.pop(context);
        }
      } else {
        final result =
            await ref.read(subAccountsProvider.notifier).create(data);
        final success = result['success'] as bool? ?? false;
        if (success) {
          _createdUserId = result['data']?['user_id'] as int? ??
              result['data']?['id'] as int?;
          if (_createdUserId != null) {
            setState(() => _showOtpField = true);
          } else {
            if (mounted) Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] as String? ?? 'فشل الإنشاء'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_createdUserId == null) return;

    setState(() => _isLoading = true);

    try {
      final result = await ref.read(subAccountsProvider.notifier).verifyOtp(
            otp: _otpController.text.trim(),
            userId: _createdUserId!,
          );

      final success = result['success'] as bool? ?? false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'تم إنشاء الحساب بنجاح' : 'رمز التحقق غير صحيح',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        if (success) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
