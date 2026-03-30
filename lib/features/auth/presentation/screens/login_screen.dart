import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:orbit_app/features/auth/presentation/widgets/login_tab_toggle.dart';
import 'package:orbit_app/features/auth/presentation/widgets/phone_input_field.dart';
import 'package:orbit_app/core/storage/secure_storage.dart';

/// Login screen for ORBIT SMS V3.
///
/// Adapts the web portal design to mobile: white card on a light gray
/// background, ORBIT logo, tab toggle between phone and username login,
/// remember-me checkbox, and links to forgot password and registration.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  LoginMode _loginMode = LoginMode.phone;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String _fullPhoneNumber = '';

  // Server-side validation errors from API
  Map<String, List<String>> _serverErrors = {};

  @override
  void dispose() {
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _handleLogin() {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;

    final username = _loginMode == LoginMode.phone
        ? _fullPhoneNumber
        : _usernameController.text.trim();

    ref.read(loginControllerProvider.notifier).login(
          username: username,
          password: _passwordController.text,
        );
  }

  void _clearFieldError(String key) {
    if (_serverErrors.containsKey(key)) {
      setState(() => _serverErrors.remove(key));
    }
  }

  Future<void> _enterGuestMode() async {
    final storage = ref.read(secureStorageProvider);
    await storage.setGuestMode(true);
    ref.read(authStateProvider.notifier).setAuthenticated();
    if (mounted) context.go('/');
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
    final loginState = ref.watch(loginControllerProvider);
    final t = AppLocalizations.of(context)!;

    // Auto-redirect to dashboard if already authenticated (e.g. has stored token).
    ref.listen<AsyncValue<bool>>(authStateProvider, (prev, next) {
      final isAuth = next.valueOrNull ?? false;
      if (isAuth) {
        context.go('/');
      }
    });

    // Listen for state changes to navigate or show errors.
    ref.listen<LoginState>(loginControllerProvider, (prev, next) {
      // Store field-specific errors for inline display
      if (next.fieldErrors != null && next.fieldErrors!.isNotEmpty) {
        setState(() => _serverErrors = Map.from(next.fieldErrors!));
      }

      // Show generic error in snackbar
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
        } else if (response.requires2fa ||
            (response.verificationUuid != null &&
                response.verificationUuid!.isNotEmpty)) {
          // Navigate to 2FA if requires_2fa is true OR if a verification UUID
          // was returned (server may omit the flag but still require OTP).
          context.push('/two-factor', extra: {
            'verification_uuid': response.verificationUuid,
          });
        } else if (response.requiresPhoneVerification) {
          context.push('/verify-otp', extra: {
            'user_id': response.userId,
          });
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Logo
                _buildLogo(),
                const SizedBox(height: 32),

                // Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        Text(
                          t.translate('welcomeBackTitle'),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.translate('signInToAccount'),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Tab toggle
                        LoginTabToggle(
                          selectedMode: _loginMode,
                          onChanged: (mode) =>
                              setState(() => _loginMode = mode),
                        ),
                        const SizedBox(height: 20),

                        // Phone or Username input
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _loginMode == LoginMode.phone
                              ? _buildPhoneField(t)
                              : _buildUsernameField(t),
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        _buildPasswordField(t),
                        const SizedBox(height: 12),

                        // Remember me + Forgot password
                        _buildRememberRow(t),
                        const SizedBox(height: 24),

                        // Login button
                        _buildLoginButton(loginState.isLoading, t),
                        const SizedBox(height: 16),

                        // Terms
                        _buildTermsText(t),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Try the app button
                _buildTryAppButton(t),
                const SizedBox(height: 12),

                // Create account link
                _buildCreateAccountLink(t),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-widgets
  // ---------------------------------------------------------------------------

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/orbit-logo-dark.png',
      height: 60,
    );
  }

  Widget _buildPhoneField(AppLocalizations t) {
    return Column(
      key: const ValueKey('phone_field'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.translate('phone'),
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        PhoneInputField(
          controller: _phoneController,
          onChanged: (value) {
            _fullPhoneNumber = value;
            _clearFieldError('username');
            _clearFieldError('phone');
          },
          hintText: '5XXXXXXXX',
        ),
        _fieldErrorWidget('username'),
        _fieldErrorWidget('phone'),
      ],
    );
  }

  Widget _buildUsernameField(AppLocalizations t) {
    return Column(
      key: const ValueKey('username_field'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.translate('username'),
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _usernameController,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _clearFieldError('username'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return t.translate('pleaseEnterUsername');
            }
            return null;
          },
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: t.translate('enterUsername'),
            hintStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: AppColors.inputHint,
            ),
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.textSecondary,
              size: 22,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        _fieldErrorWidget('username'),
      ],
    );
  }

  Widget _buildPasswordField(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.translate('password'),
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(),
          onChanged: (_) => _clearFieldError('password'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return t.translate('pleaseEnterPassword');
            }
            if (value.length < 6) {
              return t.translate('passwordMinLength6');
            }
            return null;
          },
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: t.translate('enterPassword'),
            hintStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: AppColors.inputHint,
            ),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        _fieldErrorWidget('password'),
      ],
    );
  }

  Widget _buildRememberRow(AppLocalizations t) {
    return Row(
      children: [
        // Remember me
        GestureDetector(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) =>
                      setState(() => _rememberMe = value ?? false),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: const BorderSide(color: AppColors.borderDark),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                t.translate('rememberMe'),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Forgot password
        GestureDetector(
          onTap: () => context.push('/forgot-password'),
          child: Text(
            t.translate('forgotPassword'),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isLoading, AppLocalizations t) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                t.translate('login'),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildTermsText(AppLocalizations t) {
    return Text.rich(
      TextSpan(
        text: t.translate('loginBySigningIn'),
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        children: [
          TextSpan(
            text: t.translate('usagePolicy'),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push('/terms-pdf'),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTryAppButton(AppLocalizations t) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _enterGuestMode,
        icon: const Icon(Icons.explore_outlined, size: 20),
        label: Text(
          t.translate('tryTheApp'),
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateAccountLink(AppLocalizations t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          t.translate('dontHaveAccount'),
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => context.push('/register'),
          child: Text(
            t.translate('createAccount'),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
