import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/utils/validators.dart';
import 'package:orbit_app/features/settings/presentation/controllers/settings_controller.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// Profile editing screen with photo, personal info form, and save.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _landphoneController = TextEditingController();
  final _organizationController = TextEditingController();

  String? _gender;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _landphoneController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  void _initializeForm(Map<String, dynamic> profile) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = profile['name'] as String? ?? '';
    _emailController.text = profile['email'] as String? ?? '';
    _phoneController.text = profile['phone'] as String? ?? '';
    _landphoneController.text = profile['landphone'] as String? ?? '';
    _organizationController.text =
        profile['organization_name'] as String? ?? '';
    _gender = profile['gender'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: profileAsync.when(
        data: (profile) {
          _initializeForm(profile);
          return _buildForm(profile);
        },
        loading: () => AppLoading.circular(message: 'جاري التحميل...'),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('خطأ: $error'),
              const SizedBox(height: 16),
              AppButton.secondary(
                text: 'إعادة المحاولة',
                onPressed: () => ref.read(profileProvider.notifier).refresh(),
                width: 200,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(Map<String, dynamic> profile) {
    final photoUrl = profile['profile_photo_url'] as String? ?? '';

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile Photo ───────────────────────────────────────
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.primarySurface,
                  backgroundImage:
                      photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: _isUploadingPhoto
                      ? const CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        )
                      : photoUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 48,
                              color: AppColors.primary,
                            )
                          : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _showPhotoOptions,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Name ────────────────────────────────────────────────
          AppTextField(
            label: 'الاسم',
            hint: 'أدخل اسمك الكامل',
            controller: _nameController,
            validator: (v) => Validators.validateRequired(v, fieldName: 'الاسم'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // ── Email ───────────────────────────────────────────────
          AppTextField(
            label: 'البريد الإلكتروني',
            hint: 'example@email.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // ── Phone ───────────────────────────────────────────────
          AppTextField(
            label: 'رقم الجوال',
            hint: '05XXXXXXXX',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: Validators.validatePhone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // ── Landphone ───────────────────────────────────────────
          AppTextField(
            label: 'رقم الهاتف الثابت',
            hint: 'اختياري',
            controller: _landphoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // ── Gender ──────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الجنس',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _gender,
                    isExpanded: true,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'اختر الجنس',
                        style: TextStyle(color: AppColors.inputHint),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    borderRadius: BorderRadius.circular(12),
                    items: const [
                      DropdownMenuItem(
                        value: 'male',
                        child: Text('ذكر'),
                      ),
                      DropdownMenuItem(
                        value: 'female',
                        child: Text('أنثى'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _gender = value),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Organization Name ───────────────────────────────────
          AppTextField(
            label: 'اسم المنظمة',
            hint: 'اختياري',
            controller: _organizationController,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 32),

          // ── Save Button ─────────────────────────────────────────
          AppButton.primary(
            text: 'حفظ التغييرات',
            onPressed: _isLoading ? null : _saveProfile,
            isLoading: _isLoading,
            icon: Icons.save_rounded,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.primary),
              title: const Text('الكاميرا'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.primary),
              title: const Text('المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppColors.error),
              title: const Text(
                'حذف الصورة',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _deletePhoto();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      // Use readAsBytes for cross-platform compatibility (web + mobile).
      final bytes = await pickedFile.readAsBytes();
      final fileName = pickedFile.name.isNotEmpty
          ? pickedFile.name
          : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = MultipartFile.fromBytes(
        bytes,
        filename: fileName,
      );

      final success =
          await ref.read(profileProvider.notifier).uploadPhoto(file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'تم تحديث الصورة بنجاح' : 'فشل تحديث الصورة',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
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
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _deletePhoto() async {
    setState(() => _isUploadingPhoto = true);

    try {
      final success =
          await ref.read(profileProvider.notifier).deletePhoto();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'تم حذف الصورة بنجاح' : 'فشل حذف الصورة',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
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
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        if (_landphoneController.text.trim().isNotEmpty)
          'landphone': _landphoneController.text.trim(),
        if (_gender != null) 'gender': _gender,
        if (_organizationController.text.trim().isNotEmpty)
          'organization_name': _organizationController.text.trim(),
      };

      final success =
          await ref.read(profileProvider.notifier).updateProfile(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'تم تحديث الملف الشخصي بنجاح'
                  : 'فشل تحديث الملف الشخصي',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
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
