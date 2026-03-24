import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/constants/sa_regions.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:orbit_app/features/auth/presentation/widgets/phone_input_field.dart';

/// Multi-step registration screen for ORBIT SMS V3.
///
/// Steps:
///   1. Account type selection (Individual, School, Company, Government)
///   2. Personal info (name, email, phone, username, password, gender, region, city)
///   3. Document upload (varies by account type)
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  static const _totalSteps = 3;

  // Step 1: Account type
  int _selectedAccountType = 1; // 1=Individual, 2=School, 3=Company, 4=Government

  // Account type options with translation keys instead of hardcoded labels.
  static const List<_AccountTypeOption> _accountTypes = [
    _AccountTypeOption(id: 1, labelKey: 'userTypeIndividual', icon: Icons.person_outline_rounded),
    _AccountTypeOption(id: 2, labelKey: 'userTypeSchool', icon: Icons.school_outlined),
    _AccountTypeOption(id: 3, labelKey: 'userTypeCompany', icon: Icons.business_outlined),
    _AccountTypeOption(id: 4, labelKey: 'userTypeGovernment', icon: Icons.account_balance_outlined),
    _AccountTypeOption(id: 5, labelKey: 'userTypeCharity', icon: Icons.volunteer_activism_outlined),
  ];

  // Step 2: Personal info
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _fullPhoneNumber = '';
  String? _selectedGender;
  String? _selectedRegion;
  String? _selectedCity;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Server-side validation errors from API (field_name -> [errors])
  Map<String, List<String>> _serverErrors = {};

  // Step 3: Documents
  PlatformFile? _documentFile;
  XFile? _profilePhoto;
  final _organizationNameController = TextEditingController();
  final _ministerialNumberController = TextEditingController();
  final _freelanceDocNumberController = TextEditingController();

  // Regions and cities – loaded from static data (no network needed)
  late final List<Map<String, dynamic>> _regions = SaRegions.regions
      .map((r) => {'id': r['id'].toString(), 'name': r['name'].toString()})
      .toList();
  List<Map<String, dynamic>> _cities = [];

  void _loadCities(String regionId) {
    final id = int.tryParse(regionId);
    final raw = id != null ? SaRegions.cities[id] : null;
    setState(() {
      _cities = (raw ?? [])
          .map((c) => {'id': c['id'].toString(), 'name': c['name'].toString()})
          .toList();
      _selectedCity = null;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _organizationNameController.dispose();
    _ministerialNumberController.dispose();
    _freelanceDocNumberController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _nextStep() {
    if (_currentStep == 1 && !_formKey.currentState!.validate()) return;

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _handleSubmit() async {
    // Clear previous server errors
    setState(() => _serverErrors = {});

    // Extract phone_without_dialcode by removing the country code prefix.
    String phoneWithoutDialcode = _phoneController.text.trim();
    if (phoneWithoutDialcode.startsWith('0')) {
      phoneWithoutDialcode = phoneWithoutDialcode.substring(1);
    }

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _fullPhoneNumber,
      'phone_without_dialcode': phoneWithoutDialcode,
      'username': _usernameController.text.trim(),
      'password': _passwordController.text,
      'password_confirmation': _confirmPasswordController.text,
      'user_type_id': _selectedAccountType,
      if (_selectedGender != null) 'gender': _selectedGender,
      if (_selectedRegion != null) 'region_id': int.tryParse(_selectedRegion!) ?? _selectedRegion,
      if (_selectedCity != null) 'city_id': int.tryParse(_selectedCity!) ?? _selectedCity,
    };

    // Individual-specific fields
    if (_selectedAccountType == 1) {
      if (_freelanceDocNumberController.text.trim().isNotEmpty) {
        data['freelance_document_number'] =
            _freelanceDocNumberController.text.trim();
      }
    }

    // Organization-specific fields
    if (_selectedAccountType != 1) {
      data['organization_name'] = _organizationNameController.text.trim();
      if (_ministerialNumberController.text.trim().isNotEmpty) {
        data['ministerial_number'] = _ministerialNumberController.text.trim();
      }
    }

    final files = <String, MultipartFile>{};

    if (_documentFile != null && _documentFile!.path != null) {
      // Use correct file key based on account type
      final fileKey = _selectedAccountType == 1
          ? 'freelance_document_file'
          : 'commercial_register_file';
      files[fileKey] = await MultipartFile.fromFile(
        _documentFile!.path!,
        filename: _documentFile!.name,
      );
    }

    if (_profilePhoto != null) {
      files['profile_photo'] = await MultipartFile.fromFile(
        _profilePhoto!.path,
        filename: _profilePhoto!.name,
      );
    }

    ref.read(registerControllerProvider.notifier).register(
          data: data,
          files: files.isNotEmpty ? files : null,
        );
  }

  // ---------------------------------------------------------------------------
  // File pickers
  // ---------------------------------------------------------------------------

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _documentFile = result.files.first);
    }
  }

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _profilePhoto = image);
    }
  }

  // ---------------------------------------------------------------------------
  // Server field error helpers
  // ---------------------------------------------------------------------------

  static const _step2FieldKeys = {
    'name', 'email', 'phone', 'phone_without_dialcode',
    'username', 'password', 'password_confirmation',
    'gender', 'region_id', 'city_id',
  };

  void _clearFieldError(String key) {
    if (_serverErrors.containsKey(key)) {
      setState(() => _serverErrors.remove(key));
    }
  }

  Widget _fieldErrorWidget(String key) {
    final errors = _serverErrors[key];
    if (errors == null || errors.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, right: 12),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 14, color: AppColors.error),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              errors.join('\n'),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerControllerProvider);
    final t = AppLocalizations.of(context)!;

    ref.listen<RegisterState>(registerControllerProvider, (prev, next) {
      // Handle field-specific errors (show inline)
      if (next.fieldErrors != null && next.fieldErrors!.isNotEmpty) {
        setState(() => _serverErrors = Map.from(next.fieldErrors!));

        // Navigate to the step that contains the first error
        final hasStep2Error =
            next.fieldErrors!.keys.any((k) => _step2FieldKeys.contains(k));
        if (hasStep2Error && _currentStep != 1) {
          setState(() => _currentStep = 1);
          _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }

      // Handle generic error (show snackbar)
      if (next.error != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                next.error!,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
      }

      // Handle success
      final response = next.response;
      if (response != null) {
        if (response.isAuthenticated) {
          context.go('/');
        } else if (response.requiresPhoneVerification) {
          context.push('/verify-otp', extra: {
            'user_id': response.userId,
          });
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: _prevStep,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
        title: Text(
          t.translate('registerNewAccount'),
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Logo
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Image.asset(
                'assets/images/orbit-logo-dark.png',
                height: 44,
              ),
            ),

            // Step indicator
            _buildStepIndicator(),
            const SizedBox(height: 16),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1AccountType(t),
                  _buildStep2PersonalInfo(t),
                  _buildStep3Documents(t),
                ],
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: registerState.isLoading
                      ? null
                      : () {
                          if (_currentStep < _totalSteps - 1) {
                            _nextStep();
                          } else {
                            _handleSubmit();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withOpacity(0.6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: registerState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _currentStep < _totalSteps - 1
                              ? t.translate('next')
                              : t.translate('createAccount'),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step indicator
  // ---------------------------------------------------------------------------

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(_totalSteps * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            return Expanded(
              child: Container(
                height: 3,
                color: stepIndex < _currentStep
                    ? AppColors.primary
                    : AppColors.borderLight,
              ),
            );
          }

          // Step circle
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < _currentStep;
          final isCurrent = stepIndex == _currentStep;

          return Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted || isCurrent
                  ? AppColors.primary
                  : AppColors.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted || isCurrent
                    ? AppColors.primary
                    : AppColors.borderDark,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isCurrent
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1: Account type
  // ---------------------------------------------------------------------------

  Widget _buildStep1AccountType(AppLocalizations t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            t.translate('selectAccountType'),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.translate('selectAccountTypeDesc'),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(_accountTypes.length, (index) {
            final type = _accountTypes[index];
            final isSelected = _selectedAccountType == type.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedAccountType = type.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primarySurface
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.inputBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          type.icon,
                          size: 24,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        t.translate(type.labelKey),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.borderDark,
                            width: 2,
                          ),
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                        alignment: Alignment.center,
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2: Personal info
  // ---------------------------------------------------------------------------

  Widget _buildStep2PersonalInfo(AppLocalizations t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              t.translate('personalInfo'),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.translate('enterPersonalInfo'),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Full name
            _buildLabel(t.translate('fullName')),
            const SizedBox(height: 8),
            _buildTextFormField(
              controller: _nameController,
              hint: t.translate('enterFullName'),
              icon: Icons.person_outline_rounded,
              onChanged: (_) => _clearFieldError('name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? t.translate('nameRequired') : null,
            ),
            _fieldErrorWidget('name'),
            const SizedBox(height: 16),

            // Email
            _buildLabel(t.translate('email')),
            const SizedBox(height: 8),
            _buildTextFormField(
              controller: _emailController,
              hint: 'example@mail.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => _clearFieldError('email'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return t.translate('emailRequiredMsg');
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(v.trim())) {
                  return t.translate('invalidEmailFormat');
                }
                return null;
              },
            ),
            _fieldErrorWidget('email'),
            const SizedBox(height: 16),

            // Phone number
            _buildLabel(t.translate('phone')),
            const SizedBox(height: 8),
            PhoneInputField(
              controller: _phoneController,
              onChanged: (value) {
                _fullPhoneNumber = value;
                _clearFieldError('phone');
                _clearFieldError('phone_without_dialcode');
              },
            ),
            _fieldErrorWidget('phone'),
            _fieldErrorWidget('phone_without_dialcode'),
            const SizedBox(height: 16),

            // Username
            _buildLabel(t.translate('username')),
            const SizedBox(height: 8),
            _buildTextFormField(
              controller: _usernameController,
              hint: t.translate('enterUsername'),
              icon: Icons.alternate_email_rounded,
              onChanged: (_) => _clearFieldError('username'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return t.translate('usernameRequiredMsg');
                if (v.trim().length < 3) return t.translate('usernameMinLength3');
                return null;
              },
            ),
            _fieldErrorWidget('username'),
            const SizedBox(height: 16),

            // Password
            _buildLabel(t.translate('password')),
            const SizedBox(height: 8),
            _buildPasswordFormField(
              controller: _passwordController,
              hint: t.translate('enterPassword'),
              obscure: _obscurePassword,
              onToggle: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              onChanged: (_) => _clearFieldError('password'),
              validator: (v) {
                if (v == null || v.isEmpty) return t.translate('passwordRequiredMsg');
                if (v.length < 8) return t.translate('passwordMinLength8');
                if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(v)) {
                  return t.translate('passwordNeedsSpecialChar');
                }
                return null;
              },
            ),
            _fieldErrorWidget('password'),
            const SizedBox(height: 16),

            // Confirm password
            _buildLabel(t.translate('confirmPassword')),
            const SizedBox(height: 8),
            _buildPasswordFormField(
              controller: _confirmPasswordController,
              hint: t.translate('confirmPasswordHint'),
              obscure: _obscureConfirmPassword,
              onToggle: () =>
                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              onChanged: (_) => _clearFieldError('password_confirmation'),
              validator: (v) {
                if (v != _passwordController.text) {
                  return t.translate('passwordsDoNotMatch');
                }
                return null;
              },
            ),
            _fieldErrorWidget('password_confirmation'),
            const SizedBox(height: 16),

            // Gender
            _buildLabel(t.translate('genderLabel')),
            const SizedBox(height: 8),
            _buildDropdown<String>(
              value: _selectedGender,
              hint: t.translate('selectGender'),
              items: [
                DropdownMenuItem(value: 'M', child: Text(t.translate('male'), style: const TextStyle(fontFamily: 'Cairo'))),
                DropdownMenuItem(value: 'F', child: Text(t.translate('female'), style: const TextStyle(fontFamily: 'Cairo'))),
              ],
              onChanged: (v) {
                setState(() => _selectedGender = v);
                _clearFieldError('gender');
              },
            ),
            _fieldErrorWidget('gender'),
            const SizedBox(height: 16),

            // Region
            _buildLabel(t.translate('regionLabel')),
            const SizedBox(height: 8),
            _buildDropdown<String>(
              value: _selectedRegion,
              hint: t.translate('selectRegion'),
              items: _regions
                  .map((r) => DropdownMenuItem(
                        value: r['id'] as String,
                        child: Text(r['name'] as String,
                            style: const TextStyle(fontFamily: 'Cairo')),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _selectedRegion = v;
                  _selectedCity = null;
                  _cities = [];
                });
                _clearFieldError('region_id');
                if (v != null) _loadCities(v);
              },
            ),
            _fieldErrorWidget('region_id'),
            const SizedBox(height: 16),

            // City
            _buildLabel(t.translate('cityLabel')),
            const SizedBox(height: 8),
            _buildDropdown<String>(
              value: _selectedCity,
              hint: _selectedRegion == null
                  ? t.translate('selectRegionFirst')
                  : t.translate('selectCity'),
              items: _cities
                  .map((c) => DropdownMenuItem(
                        value: c['id'] as String,
                        child: Text(c['name'] as String,
                            style: const TextStyle(fontFamily: 'Cairo')),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() => _selectedCity = v);
                _clearFieldError('city_id');
              },
            ),
            _fieldErrorWidget('city_id'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3: Documents
  // ---------------------------------------------------------------------------

  Widget _buildStep3Documents(AppLocalizations t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            t.translate('documentsTitle'),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.translate('uploadRequiredDocs'),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Organization fields (for non-individual accounts)
          if (_selectedAccountType != 1) ...[
            _buildLabel(_selectedAccountType == 2
                ? t.translate('schoolName')
                : _selectedAccountType == 3
                    ? t.translate('companyName')
                    : t.translate('entityName')),
            const SizedBox(height: 8),
            _buildTextFormField(
              controller: _organizationNameController,
              hint: t.translate('enterNameHint'),
              icon: Icons.business_outlined,
              onChanged: (_) => _clearFieldError('organization_name'),
            ),
            _fieldErrorWidget('organization_name'),
            const SizedBox(height: 16),

            _buildLabel(t.translate('ministerialOrCommercial')),
            const SizedBox(height: 8),
            _buildTextFormField(
              controller: _ministerialNumberController,
              hint: t.translate('enterNumber'),
              icon: Icons.numbers_rounded,
              onChanged: (_) => _clearFieldError('ministerial_number'),
            ),
            _fieldErrorWidget('ministerial_number'),
            const SizedBox(height: 16),
          ],

          // Freelance document number (for individuals)
          if (_selectedAccountType == 1) ...[
            _buildLabel(t.translate('freelanceDocNumber')),
            const SizedBox(height: 8),
            _buildTextFormField(
              controller: _freelanceDocNumberController,
              hint: t.translate('enterDocNumber'),
              icon: Icons.numbers_rounded,
              onChanged: (_) => _clearFieldError('freelance_document_number'),
            ),
            _fieldErrorWidget('freelance_document_number'),
            const SizedBox(height: 16),
          ],

          // Document upload
          _buildLabel(_selectedAccountType == 1
              ? t.translate('freelanceDoc')
              : t.translate('commercialOrOfficial')),
          const SizedBox(height: 8),
          _buildFileUploadArea(
            file: _documentFile,
            onTap: () {
              _pickDocument();
              _clearFieldError('freelance_document_file');
              _clearFieldError('commercial_register_file');
            },
            label: t.translate('tapToUploadDoc'),
            sublabel: 'PDF, JPG, PNG',
          ),
          _fieldErrorWidget('freelance_document_file'),
          _fieldErrorWidget('commercial_register_file'),
          const SizedBox(height: 24),

          // Profile photo
          _buildLabel(t.translate('profilePhotoOptional')),
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: _pickProfilePhoto,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.inputBorder),
                  image: _profilePhoto != null
                      ? DecorationImage(
                          image: FileImage(File(_profilePhoto!.path)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _profilePhoto == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_outlined,
                              color: AppColors.textSecondary, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            t.translate('uploadPhoto'),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : const Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.edit, size: 14, color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          _fieldErrorWidget('profile_photo'),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared widget builders
  // ---------------------------------------------------------------------------

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          color: AppColors.inputHint,
        ),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 22),
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.inputBorderFocused,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorderError),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPasswordFormField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          color: AppColors.inputHint,
        ),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: AppColors.textSecondary, size: 22),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.textSecondary,
            size: 22,
          ),
        ),
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.inputBorderFocused,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorderError),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(
        hint,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          color: AppColors.inputHint,
        ),
      ),
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppColors.textSecondary),
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.inputBorderFocused,
            width: 1.5,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildFileUploadArea({
    required PlatformFile? file,
    required VoidCallback onTap,
    required String label,
    required String sublabel,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.inputBorder,
            style: BorderStyle.solid,
          ),
        ),
        child: file != null
            ? Row(
                children: [
                  const Icon(Icons.insert_drive_file_outlined,
                      color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${(file.size / 1024).toStringAsFixed(1)} KB',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _documentFile = null),
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.error, size: 20),
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.cloud_upload_outlined,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal model
// ---------------------------------------------------------------------------

class _AccountTypeOption {
  const _AccountTypeOption({
    required this.id,
    required this.labelKey,
    required this.icon,
  });

  final int id;
  /// Translation key for the label (resolved at build time).
  final String labelKey;
  final IconData icon;
}
