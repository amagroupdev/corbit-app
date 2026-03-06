import 'package:flutter/material.dart';
import 'package:orbit_app/core/constants/app_colors.dart';

/// A versatile, reusable button used across the ORBIT app.
///
/// Three factory constructors cover every common button style:
/// - [AppButton.primary]   -- filled orange button with white text
/// - [AppButton.secondary] -- outlined orange button
/// - [AppButton.text]      -- text-only orange button
class AppButton extends StatelessWidget {
  const AppButton._({
    required this.text,
    required this.onPressed,
    required this.variant,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width = double.infinity,
    super.key,
  });

  /// Filled button with the brand primary color and white text.
  factory AppButton.primary({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isDisabled = false,
    IconData? icon,
    double width = double.infinity,
    Key? key,
  }) {
    return AppButton._(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      icon: icon,
      width: width,
      key: key,
      variant: _ButtonVariant.primary,
    );
  }

  /// Outlined button with the brand primary color border and text.
  factory AppButton.secondary({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isDisabled = false,
    IconData? icon,
    double width = double.infinity,
    Key? key,
  }) {
    return AppButton._(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      icon: icon,
      width: width,
      key: key,
      variant: _ButtonVariant.secondary,
    );
  }

  /// Text-only button with the brand primary color.
  factory AppButton.text({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isDisabled = false,
    IconData? icon,
    double width = double.infinity,
    Key? key,
  }) {
    return AppButton._(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      icon: icon,
      width: width,
      key: key,
      variant: _ButtonVariant.text,
    );
  }

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final double width;
  final _ButtonVariant variant;

  static const double _height = 52;
  static const double _borderRadius = 12;

  bool get _effectivelyDisabled => isDisabled || isLoading || onPressed == null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _height,
      child: switch (variant) {
        _ButtonVariant.primary => _buildPrimary(),
        _ButtonVariant.secondary => _buildSecondary(),
        _ButtonVariant.text => _buildText(),
      },
    );
  }

  // ─── Primary (filled) ─────────────────────────────────────────

  Widget _buildPrimary() {
    return ElevatedButton(
      onPressed: _effectivelyDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
      child: _buildChild(Colors.white),
    );
  }

  // ─── Secondary (outlined) ─────────────────────────────────────

  Widget _buildSecondary() {
    return OutlinedButton(
      onPressed: _effectivelyDisabled ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.primary.withValues(alpha: 0.5),
        side: BorderSide(
          color: _effectivelyDisabled
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.primary,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
      child: _buildChild(AppColors.primary),
    );
  }

  // ─── Text ─────────────────────────────────────────────────────

  Widget _buildText() {
    return TextButton(
      onPressed: _effectivelyDisabled ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.primary.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
      child: _buildChild(AppColors.primary),
    );
  }

  // ─── Common child builder ─────────────────────────────────────

  Widget _buildChild(Color foreground) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == _ButtonVariant.primary ? Colors.white : AppColors.primary,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

enum _ButtonVariant { primary, secondary, text }
