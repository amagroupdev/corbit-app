import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
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

  // Step 3: Documents
  PlatformFile? _documentFile;
  XFile? _profilePhoto;
  final _organizationNameController = TextEditingController();
  final _ministerialNumberController = TextEditingController();

  static const List<_AccountTypeOption> _accountTypes = [
    _AccountTypeOption(id: 1, label: '\u0641\u0631\u062f', icon: Icons.person_outline_rounded),
    _AccountTypeOption(id: 2, label: '\u0645\u062f\u0631\u0633\u0629', icon: Icons.school_outlined),
    _AccountTypeOption(id: 3, label: '\u0634\u0631\u0643\u0629', icon: Icons.business_outlined),
    _AccountTypeOption(id: 4, label: '\u062c\u0647\u0629 \u062d\u0643\u0648\u0645\u064a\u0629', icon: Icons.account_balance_outlined),
  ];

  static const List<Map<String, String>> _regions = [
    {'id': '1', 'name': '\u0627\u0644\u0631\u064a\u0627\u0636'},
    {'id': '2', 'name': '\u0645\u0643\u0629 \u0627\u0644\u0645\u0643\u0631\u0645\u0629'},
    {'id': '3', 'name': '\u0627\u0644\u0645\u062f\u064a\u0646\u0629 \u0627\u0644\u0645\u0646\u0648\u0631\u0629'},
    {'id': '4', 'name': '\u0627\u0644\u0642\u0635\u064a\u0645'},
    {'id': '5', 'name': '\u0627\u0644\u0634\u0631\u0642\u064a\u0629'},
    {'id': '6', 'name': '\u0639\u0633\u064a\u0631'},
    {'id': '7', 'name': '\u062a\u0628\u0648\u0643'},
    {'id': '8', 'name': '\u062d\u0627\u0626\u0644'},
    {'id': '9', 'name': '\u0627\u0644\u062d\u062f\u0648\u062f \u0627\u0644\u0634\u0645\u0627\u0644\u064a\u0629'},
    {'id': '10', 'name': '\u062c\u0627\u0632\u0627\u0646'},
    {'id': '11', 'name': '\u0646\u062c\u0631\u0627\u0646'},
    {'id': '12', 'name': '\u0627\u0644\u0628\u0627\u062d\u0629'},
    {'id': '13', 'name': '\u0627\u0644\u062c\u0648\u0641'},
  ];

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
    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _fullPhoneNumber,
      'username': _usernameController.text.trim(),
      'password': _passwordController.text,
      'password_confirmation': _confirmPasswordController.text,
      'user_type_id': _selectedAccountType,
      if (_selectedGender != null) 'gender': _selectedGender,
      if (_selectedRegion != null) 'region_id': _selectedRegion,
      if (_selectedCity != null) 'city_id': _selectedCity,
    };

    if (_selectedAccountType != 1) {
      data['organization_name'] = _organizationNameController.text.trim();
      if (_ministerialNumberController.text.trim().isNotEmpty) {
        data['ministerial_number'] = _ministerialNumberController.text.trim();
      }
    }

    final files = <String, MultipartFile>{};

    if (_documentFile != null && _documentFile!.path != null) {
      files['document'] = await MultipartFile.fromFile(
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
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerControllerProvider);

    ref.listen<RegisterState>(registerControllerProvider, (prev, next) {
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
      }

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
        title: const Text(
          '\u062a\u0633\u062c\u064a\u0644 \u062d\u0633\u0627\u0628 \u062c\u062f\u064a\u062f',
          style: TextStyle(
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
                  _buildStep1AccountType(),
                  _buildStep2PersonalInfo(),
                  _buildStep3Documents(),
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
                              ? '\u0627\u0644\u062a\u0627\u0644\u064a'
                              : '\u0625\u0646\u0634\u0627\u0621 \u0627\u0644\u062d\u0633\u0627\u0628',
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

  Widget _buildStep1AccountType() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            '\u0627\u062e\u062a\u0631 \u0646\u0648\u0639 \u0627\u0644\u062d\u0633\u0627\u0628',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '\u062d\u062f\u062f \u0646\u0648\u0639 \u062d\u0633\u0627\u0628\u0643 \u0644\u0644\u062d\u0635\u0648\u0644 \u0639\u0644\u0649 \u0627\u0644\u062e\u062f\u0645\u0627\u062a \u0627\u0644\u0645\u0646\u0627\u0633\u0628\u0629',
            style: TextStyle(
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
                        type.label,
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

  Widget _buildStep2PersonalInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              '\u0627\u0644\u0645\u0639\u0644\u0648\u0645\u0627\u062a \u0627\u0644\u0634\u062e\u0635\u064a\u0629',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '\u0623\u062f\u062e\u0644 \u0628\u064a\u0627\u0646\u0627\u062a\u0643 \u0627\u0644\u0634\u062e\u0635\u064a\u0629',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Full name
            _buildLabel('\u0627\u0644\u0627\u0633\u0645 \u0627\u0644\u0643\u0627\u0645\u0644'),
            const SizedBox(height: 8),
            _buildTextFormField(
              controller: _nameController,
              hint: '\u0623\u062f\u062e\u0644 \u0627\u0644\u0627\u0633\u0645 \u0627\u0644\u0643\u0627\u0645\u0644',
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? '\u0627\u0644\u0627\u0633\u0645 \u0645\u0637\u0644\u0648\u0628' : null,
            ),
            const SizedBox(height: 16),

            // Email
            _buildLabel('\u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a'),
            const SizedBox(height: 8),
            _buildTextFormField(
              controller: _emailController,
              hint: 'example@mail.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '\u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a \u0645\u0637\u0644\u0648\u0628';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(v.trim())) {
                  return '\u0628\u0631\u064a\u062f \u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a \u063a\u064a\u0631 \u0635\u0627\u0644\u062d';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone number
            _buildLabel('\u0631\u0642\u0645 \u0627\u0644\u062c\u0648\u0627\u0644'),
            const SizedBox(height: 8),
            PhoneInputField(
              controller: _phoneController,
              onChanged: (value) => _fullPhoneNumber = value,
            ),
            const SizedBox(height: 16),

            // Username
            _buildLabel('\u0625\u0633\u0645 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645'),
            const SizedBox(height: 8),
            _buildTextFormField(
              controller: _usernameController,
              hint: '\u0623\u062f\u062e\u0644 \u0625\u0633\u0645 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645',
              icon: Icons.alternate_email_rounded,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '\u0625\u0633\u0645 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645 \u0645\u0637\u0644\u0648\u0628';
                if (v.trim().length < 3) return '\u0627\u0644\u062d\u062f \u0627\u0644\u0623\u062f\u0646\u0649 3 \u0623\u062d\u0631\u0641';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password
            _buildLabel('\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631'),
            const SizedBox(height: 8),
            _buildPasswordFormField(
              controller: _passwordController,
              hint: '\u0623\u062f\u062e\u0644 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
              obscure: _obscurePassword,
              onToggle: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              validator: (v) {
                if (v == null || v.isEmpty) return '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u0645\u0637\u0644\u0648\u0628\u0629';
                if (v.length < 8) return '8 \u0623\u062d\u0631\u0641 \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm password
            _buildLabel('\u062a\u0623\u0643\u064a\u062f \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631'),
            const SizedBox(height: 8),
            _buildPasswordFormField(
              controller: _confirmPasswordController,
              hint: '\u0623\u0639\u062f \u0625\u062f\u062e\u0627\u0644 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
              obscure: _obscureConfirmPassword,
              onToggle: () =>
                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              validator: (v) {
                if (v != _passwordController.text) {
                  return '\u0643\u0644\u0645\u0627\u062a \u0627\u0644\u0645\u0631\u0648\u0631 \u063a\u064a\u0631 \u0645\u062a\u0637\u0627\u0628\u0642\u0629';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Gender
            _buildLabel('\u0627\u0644\u062c\u0646\u0633'),
            const SizedBox(height: 8),
            _buildDropdown<String>(
              value: _selectedGender,
              hint: '\u0627\u062e\u062a\u0631 \u0627\u0644\u062c\u0646\u0633',
              items: const [
                DropdownMenuItem(value: 'male', child: Text('\u0630\u0643\u0631', style: TextStyle(fontFamily: 'Cairo'))),
                DropdownMenuItem(value: 'female', child: Text('\u0623\u0646\u062b\u0649', style: TextStyle(fontFamily: 'Cairo'))),
              ],
              onChanged: (v) => setState(() => _selectedGender = v),
            ),
            const SizedBox(height: 16),

            // Region
            _buildLabel('\u0627\u0644\u0645\u0646\u0637\u0642\u0629'),
            const SizedBox(height: 8),
            _buildDropdown<String>(
              value: _selectedRegion,
              hint: '\u0627\u062e\u062a\u0631 \u0627\u0644\u0645\u0646\u0637\u0642\u0629',
              items: _regions
                  .map((r) => DropdownMenuItem(
                        value: r['id'],
                        child: Text(r['name']!,
                            style: const TextStyle(fontFamily: 'Cairo')),
                      ))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedRegion = v;
                _selectedCity = null;
              }),
            ),
            const SizedBox(height: 16),

            // City
            _buildLabel('\u0627\u0644\u0645\u062f\u064a\u0646\u0629'),
            const SizedBox(height: 8),
            _buildDropdown<String>(
              value: _selectedCity,
              hint: '\u0627\u062e\u062a\u0631 \u0627\u0644\u0645\u062f\u064a\u0646\u0629',
              items: const [
                DropdownMenuItem(value: '1', child: Text('\u0627\u0644\u0631\u064a\u0627\u0636', style: TextStyle(fontFamily: 'Cairo'))),
                DropdownMenuItem(value: '2', child: Text('\u062c\u062f\u0629', style: TextStyle(fontFamily: 'Cairo'))),
                DropdownMenuItem(value: '3', child: Text('\u0627\u0644\u062f\u0645\u0627\u0645', style: TextStyle(fontFamily: 'Cairo'))),
                DropdownMenuItem(value: '4', child: Text('\u0645\u0643\u0629', style: TextStyle(fontFamily: 'Cairo'))),
                DropdownMenuItem(value: '5', child: Text('\u0627\u0644\u0645\u062f\u064a\u0646\u0629', style: TextStyle(fontFamily: 'Cairo'))),
              ],
              onChanged: (v) => setState(() => _selectedCity = v),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3: Documents
  // ---------------------------------------------------------------------------

  Widget _buildStep3Documents() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            '\u0627\u0644\u0645\u0633\u062a\u0646\u062f\u0627\u062a',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '\u0627\u0631\u0641\u0639 \u0627\u0644\u0645\u0633\u062a\u0646\u062f\u0627\u062a \u0627\u0644\u0645\u0637\u0644\u0648\u0628\u0629 \u0644\u0625\u0643\u0645\u0627\u0644 \u0627\u0644\u062a\u0633\u062c\u064a\u0644',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Organization fields (for non-individual accounts)
          if (_selectedAccountType != 1) ...[
            _buildLabel(_selectedAccountType == 2
                ? '\u0627\u0633\u0645 \u0627\u0644\u0645\u062f\u0631\u0633\u0629'
                : _selectedAccountType == 3
                    ? '\u0627\u0633\u0645 \u0627\u0644\u0634\u0631\u0643\u0629'
                    : '\u0627\u0633\u0645 \u0627\u0644\u062c\u0647\u0629'),
            const SizedBox(height: 8),
            _buildTextFormField(
              controller: _organizationNameController,
              hint: '\u0623\u062f\u062e\u0644 \u0627\u0644\u0627\u0633\u0645',
              icon: Icons.business_outlined,
            ),
            const SizedBox(height: 16),

            _buildLabel('\u0627\u0644\u0631\u0642\u0645 \u0627\u0644\u0648\u0632\u0627\u0631\u064a / \u0627\u0644\u0633\u062c\u0644 \u0627\u0644\u062a\u062c\u0627\u0631\u064a'),
            const SizedBox(height: 8),
            _buildTextFormField(
              controller: _ministerialNumberController,
              hint: '\u0623\u062f\u062e\u0644 \u0627\u0644\u0631\u0642\u0645',
              icon: Icons.numbers_rounded,
            ),
            const SizedBox(height: 16),
          ],

          // Document upload
          _buildLabel(_selectedAccountType == 1
              ? '\u0648\u062b\u064a\u0642\u0629 \u0627\u0644\u0639\u0645\u0644 \u0627\u0644\u062d\u0631 (\u0627\u062e\u062a\u064a\u0627\u0631\u064a)'
              : '\u0627\u0644\u0633\u062c\u0644 \u0627\u0644\u062a\u062c\u0627\u0631\u064a / \u0627\u0644\u0648\u062b\u064a\u0642\u0629 \u0627\u0644\u0631\u0633\u0645\u064a\u0629'),
          const SizedBox(height: 8),
          _buildFileUploadArea(
            file: _documentFile,
            onTap: _pickDocument,
            label: '\u0627\u0636\u063a\u0637 \u0644\u0631\u0641\u0639 \u0627\u0644\u0645\u0633\u062a\u0646\u062f',
            sublabel: 'PDF, JPG, PNG',
          ),
          const SizedBox(height: 24),

          // Profile photo
          _buildLabel('\u0627\u0644\u0635\u0648\u0631\u0629 \u0627\u0644\u0634\u062e\u0635\u064a\u0629 (\u0627\u062e\u062a\u064a\u0627\u0631\u064a)'),
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
                          image: NetworkImage(_profilePhoto!.path),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _profilePhoto == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              color: AppColors.textSecondary, size: 28),
                          SizedBox(height: 4),
                          Text(
                            '\u0631\u0641\u0639 \u0635\u0648\u0631\u0629',
                            style: TextStyle(
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
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
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
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
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
    required this.label,
    required this.icon,
  });

  final int id;
  final String label;
  final IconData icon;
}
