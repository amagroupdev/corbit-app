import 'package:flutter/material.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';

/// Defines the two login modes available on the login screen.
enum LoginMode { phone, username }

/// An animated toggle switch that lets the user choose between
/// logging in via phone number or username.
///
/// Mirrors the tab toggle component from the ORBIT web portal: two rounded
/// segments with the active segment highlighted in the primary color.
class LoginTabToggle extends StatelessWidget {
  const LoginTabToggle({
    super.key,
    required this.selectedMode,
    required this.onChanged,
  });

  /// The currently selected login mode.
  final LoginMode selectedMode;

  /// Called when the user taps a different tab.
  final ValueChanged<LoginMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTab(
            label: t.translate('loginTabPhone'),
            icon: Icons.phone_android_rounded,
            mode: LoginMode.phone,
          ),
          _buildTab(
            label: t.translate('loginTabUsername'),
            icon: Icons.person_outline_rounded,
            mode: LoginMode.username,
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required IconData icon,
    required LoginMode mode,
  }) {
    final isSelected = selectedMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) onChanged(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.textOnPrimary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.textOnPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
