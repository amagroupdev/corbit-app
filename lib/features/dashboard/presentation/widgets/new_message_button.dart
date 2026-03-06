import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/constants/app_theme.dart';
import 'package:orbit_app/routing/route_names.dart';

/// The "New Message" dropdown button shown on the dashboard.
///
/// Displays an orange filled button with a dropdown arrow.
/// On tap it opens a bottom sheet listing message type options:
///   - Normal SMS
///   - Group SMS
///   - Long SMS
///   - Voice SMS
///   - File SMS
///
/// Each option navigates to the send-message screen with the
/// corresponding `message_type` extra parameter.
class NewMessageButton extends StatelessWidget {
  const NewMessageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        onTap: () => _showMessageTypeSheet(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_circle_outline,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              const Text(
                '\u0631\u0633\u0627\u0644\u0629 \u062C\u062F\u064A\u062F\u0629', // رسالة جديدة
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageTypeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MessageTypeSheet(parentContext: context),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message Type Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _MessageTypeSheet extends StatelessWidget {
  const _MessageTypeSheet({required this.parentContext});

  /// The outer context used for navigation (since bottom-sheet context
  /// does not have access to the shell's GoRouter).
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle bar ─────────────────────────────────────────
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // ── Title ──────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    '\u0627\u062E\u062A\u0631 \u0646\u0648\u0639 \u0627\u0644\u0631\u0633\u0627\u0644\u0629', // اختر نوع الرسالة
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 4),

            // ── Options ────────────────────────────────────────────
            _MessageTypeOption(
              icon: Icons.sms_outlined,
              title: '\u0631\u0633\u0627\u0626\u0644 \u0639\u0627\u062F\u064A\u0629', // رسائل عادية
              subtitle: '\u0625\u0631\u0633\u0627\u0644 \u0631\u0633\u0627\u0626\u0644 \u0646\u0635\u064A\u0629 \u0642\u0635\u064A\u0631\u0629', // إرسال رسائل نصية قصيرة
              color: AppColors.primary,
              onTap: () => _navigateToSendMessage(context, 'from_numbers'),
            ),
            _MessageTypeOption(
              icon: Icons.people_outlined,
              title: '\u0631\u0633\u0627\u0626\u0644 \u0644\u0644\u0645\u062C\u0645\u0648\u0639\u0627\u062A', // رسائل للمجموعات
              subtitle: '\u0625\u0631\u0633\u0627\u0644 \u0631\u0633\u0627\u0626\u0644 \u0644\u0645\u062C\u0645\u0648\u0639\u0627\u062A \u062C\u0647\u0627\u062A \u0627\u0644\u0627\u062A\u0635\u0627\u0644', // إرسال رسائل لمجموعات جهات الاتصال
              color: AppColors.success,
              onTap: () => _navigateToSendMessage(context, 'to_groups'),
            ),
            _MessageTypeOption(
              icon: Icons.text_snippet_outlined,
              title: '\u0631\u0633\u0627\u0626\u0644 \u0637\u0648\u064A\u0644\u0629', // رسائل طويلة
              subtitle: '\u0625\u0631\u0633\u0627\u0644 \u0631\u0633\u0627\u0626\u0644 \u0646\u0635\u064A\u0629 \u0637\u0648\u064A\u0644\u0629', // إرسال رسائل نصية طويلة
              color: AppColors.info,
              onTap: () => _navigateToSendMessage(context, 'long_sms'),
            ),
            _MessageTypeOption(
              icon: Icons.mic_outlined,
              title: '\u0631\u0633\u0627\u0626\u0644 \u0635\u0648\u062A\u064A\u0629', // رسائل صوتية
              subtitle: '\u0625\u0631\u0633\u0627\u0644 \u0631\u0633\u0627\u0626\u0644 \u0635\u0648\u062A\u064A\u0629 \u0645\u0633\u062C\u0644\u0629', // إرسال رسائل صوتية مسجلة
              color: AppColors.warning,
              onTap: () => _navigateToSendMessage(context, 'voice_sms'),
            ),
            _MessageTypeOption(
              icon: Icons.attach_file_outlined,
              title: '\u0631\u0633\u0627\u0626\u0644 \u0645\u0644\u0641', // رسائل ملف
              subtitle: '\u0625\u0631\u0633\u0627\u0644 \u0631\u0633\u0627\u0626\u0644 \u0645\u0639 \u0645\u0644\u0641\u0627\u062A \u0645\u0631\u0641\u0642\u0629', // إرسال رسائل مع ملفات مرفقة
              color: AppColors.balancePurpleStart,
              onTap: () => _navigateToSendMessage(context, 'file_sms'),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _navigateToSendMessage(BuildContext sheetContext, String messageType) {
    Navigator.of(sheetContext).pop();
    parentContext.pushNamed(
      RouteNames.sendMessage,
      extra: {'message_type': messageType},
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single Option Row
// ─────────────────────────────────────────────────────────────────────────────

class _MessageTypeOption extends StatelessWidget {
  const _MessageTypeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingMd,
          ),
          child: Row(
            children: [
              // Icon circle
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),

              const SizedBox(width: AppTheme.spacingMd),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
