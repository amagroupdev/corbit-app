import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/utils/validators.dart';
import 'package:orbit_app/features/settings/presentation/controllers/settings_controller.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// Screen for changing the user's password with strength indicator.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  double _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final password = _newPasswordController.text;
    double strength = 0;

    if (password.length >= 8) strength += 0.2;
    if (password.length >= 12) strength += 0.1;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~;]').hasMatch(password)) {
      strength += 0.2;
    }

    setState(() => _passwordStrength = strength.clamp(0, 1));
  }

  Color get _strengthColor {
    if (_passwordStrength < 0.3) return AppColors.error;
    if (_passwordStrength < 0.6) return AppColors.warning;
    if (_passwordStrength < 0.8) return AppColors.info;
    return AppColors.success;
  }

  String get _strengthLabel {
    if (_passwordStrength < 0.3) return 'ضعيفة';
    if (_passwordStrength < 0.6) return 'متوسطة';
    if (_passwordStrength < 0.8) return 'جيدة';
    return 'قوية';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('تغيير كلمة المرور'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Security icon header
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'تأكد من اختيار كلمة مرور قوية',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Current Password ──────────────────────────────────
            AppTextField(
              label: 'كلمة المرور الحالية',
              hint: 'أدخل كلمة المرور الحالية',
              controller: _currentPasswordController,
              obscureText: true,
              validator: (v) =>
                  Validators.validateRequired(v, fieldName: 'كلمة المرور الحالية'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // ── New Password ──────────────────────────────────────
            AppTextField(
              label: 'كلمة المرور الجديدة',
              hint: 'أدخل كلمة المرور الجديدة',
              controller: _newPasswordController,
              obscureText: true,
              validator: Validators.validatePassword,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            // ── Password Strength Indicator ───────────────────────
            if (_newPasswordController.text.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _passwordStrength,
                        backgroundColor: AppColors.border,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_strengthColor),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _strengthLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _strengthColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildPasswordRequirements(),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 16),

            // ── Confirm Password ──────────────────────────────────
            AppTextField(
              label: 'تأكيد كلمة المرور',
              hint: 'أعد إدخال كلمة المرور الجديدة',
              controller: _confirmPasswordController,
              obscureText: true,
              validator: (v) => Validators.validateConfirmPassword(
                v,
                _newPasswordController.text,
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 32),

            // ── Save Button ───────────────────────────────────────
            AppButton.primary(
              text: 'تغيير كلمة المرور',
              onPressed: _isLoading ? null : _changePassword,
              isLoading: _isLoading,
              icon: Icons.lock_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    final password = _newPasswordController.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _requirementRow('8 أحرف على الأقل', password.length >= 8),
        _requirementRow('حرف كبير واحد', RegExp(r'[A-Z]').hasMatch(password)),
        _requirementRow('حرف صغير واحد', RegExp(r'[a-z]').hasMatch(password)),
        _requirementRow('رقم واحد على الأقل', RegExp(r'[0-9]').hasMatch(password)),
        _requirementRow(
          'رمز خاص واحد',
          RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~;]')
              .hasMatch(password),
        ),
      ],
    );
  }

  Widget _requirementRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: met ? AppColors.success : AppColors.textHint,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: met ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result =
          await ref.read(profileProvider.notifier).changePassword(
                currentPassword: _currentPasswordController.text,
                newPassword: _newPasswordController.text,
                confirmPassword: _confirmPasswordController.text,
              );

      final success = result['success'] as bool? ?? false;
      final message =
          result['message'] as String? ?? 'تم تغيير كلمة المرور بنجاح';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );

        if (success) {
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          Navigator.of(context).pop();
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
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
