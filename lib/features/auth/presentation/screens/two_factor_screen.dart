import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:orbit_app/shared/widgets/otp_input.dart';

/// Two-factor authentication screen.
///
/// Displayed when the login endpoint responds with `requires_2fa: true`.
/// Collects a 6-digit OTP and verifies it using the `/verify-otp/2fa`
/// endpoint together with the [verificationUuid].
class TwoFactorScreen extends ConsumerStatefulWidget {
  const TwoFactorScreen({
    super.key,
    required this.verificationUuid,
  });

  /// UUID returned by the login endpoint to correlate this 2FA challenge.
  final String verificationUuid;

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen> {
  final _otpController = TextEditingController();
  String _currentCode = '';

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _handleVerify() {
    if (_currentCode.length < 4) return;

    ref.read(otpControllerProvider.notifier).verify2fa(
          code: _currentCode,
          verificationUuid: widget.verificationUuid,
        );
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpControllerProvider);

    ref.listen<OtpState>(otpControllerProvider, (prev, next) {
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
      if (response != null && response.isAuthenticated) {
        context.go('/');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  '\u0627\u0644\u062a\u062d\u0642\u0642 \u0628\u062e\u0637\u0648\u062a\u064a\u0646',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '\u0623\u062f\u062e\u0644 \u0631\u0645\u0632 \u0627\u0644\u062a\u062d\u0642\u0642 \u0627\u0644\u0645\u0631\u0633\u0644 \u0625\u0644\u0649 \u062c\u0647\u0627\u0632\u0643',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // PIN code fields – 4 visible boxes, accepts more silently
                OtpInput(
                  controller: _otpController,
                  boxCount: 4,
                  maxLength: 8,
                  autoFocus: true,
                  onChanged: (value) {
                    _currentCode = value;
                  },
                  onCompleted: (value) {
                    _currentCode = value;
                    _handleVerify();
                  },
                ),
                const SizedBox(height: 16),

                // Timer
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        '\u0635\u0644\u0627\u062d\u064a\u0629 \u0627\u0644\u0631\u0645\u0632 \u062a\u0646\u062a\u0647\u064a \u0628\u0639\u062f ${otpState.formattedTime} \u062f\u0642\u064a\u0642\u0629',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Verify button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: otpState.isLoading ? null : _handleVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: otpState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            '\u062a\u062d\u0642\u0642 \u0645\u0646 \u0627\u0644\u0631\u0645\u0632',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Resend info
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '\u0644\u0645 \u064a\u0635\u0644\u0643 \u0631\u0645\u0632 \u0627\u0644\u062a\u062d\u0642\u0642\u061f',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: otpState.canResend ? () => context.pop() : null,
                      child: Text(
                        '\u0625\u0639\u0627\u062f\u0629 \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: otpState.canResend
                              ? AppColors.primary
                              : AppColors.textDisabled,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
