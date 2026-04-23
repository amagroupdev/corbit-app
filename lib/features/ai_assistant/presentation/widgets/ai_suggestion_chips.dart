import 'package:flutter/material.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/constants/app_theme.dart';
import 'package:orbit_app/core/constants/feature_flags.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';

/// Suggestion chips shown when the AI chat is empty.
///
/// Displays a set of pre-defined questions the user can tap to quickly
/// start a conversation with the assistant.
class AiSuggestionChips extends StatelessWidget {
  const AiSuggestionChips({
    required this.onChipTap,
    super.key,
  });

  /// Called when the user taps a suggestion chip with the chip text.
  final void Function(String text) onChipTap;

  static const _suggestionsAr = [
    'كيف أرسل رسالة؟',
    'وش خدمات Corbit؟',
    'وديني للإعدادات',
    'كيف أشحن رصيدي؟',
  ];

  static const _suggestionsEn = [
    'How to send a message?',
    'What are Corbit services?',
    'Take me to settings',
    'How to recharge?',
  ];

  /// Prompts that reference the recharge feature and must be hidden
  /// whenever [kRechargeEnabled] is false.
  static const _rechargePromptsAr = {'كيف أشحن رصيدي؟'};
  static const _rechargePromptsEn = {'How to recharge?'};

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isArabic = t?.isRtl ?? true;
    final allSuggestions = isArabic ? _suggestionsAr : _suggestionsEn;
    final rechargePrompts =
        isArabic ? _rechargePromptsAr : _rechargePromptsEn;
    final suggestions = kRechargeEnabled
        ? allSuggestions
        : allSuggestions
            .where((s) => !rechargePrompts.contains(s))
            .toList();

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Icon ───────────────────────────────────────────────────
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // ── Title ──────────────────────────────────────────────────
          Text(
            isArabic ? 'مساعد Corbit' : 'Corbit Assistant',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),

          // ── Subtitle ───────────────────────────────────────────────
          Text(
            isArabic
                ? 'كيف يمكنني مساعدتك اليوم؟'
                : 'How can I help you today?',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // ── Chips ──────────────────────────────────────────────────
          Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingSm,
            alignment: WrapAlignment.center,
            children: suggestions.map((text) {
              return ActionChip(
                label: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
                backgroundColor: AppColors.primarySurface,
                side: const BorderSide(
                  color: AppColors.primaryBorder,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
                onPressed: () => onChipTap(text),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
