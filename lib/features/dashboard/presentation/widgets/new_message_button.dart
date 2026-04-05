import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/constants/app_theme.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
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
              Text(
                AppLocalizations.of(context)?.translate('newMessage') ?? 'New Message',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'IBMPlexSansArabic',
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)?.translate('selectMessageType') ?? 'Select Message Type',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 4),

            // ── Options ────────────────────────────────────────────
            Builder(builder: (ctx) {
              final t = AppLocalizations.of(ctx);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MessageTypeOption(
                    icon: Icons.sms_outlined,
                    title: t?.translate('normalSms') ?? 'Normal SMS',
                    subtitle: t?.translate('normalSmsDesc') ?? 'Send short text messages',
                    color: AppColors.primary,
                    onTap: () => _navigateToSendMessage(context, 'from_numbers'),
                  ),
                  _MessageTypeOption(
                    icon: Icons.people_outlined,
                    title: t?.translate('groupSms') ?? 'Group SMS',
                    subtitle: t?.translate('groupSmsDesc') ?? 'Send messages to contact groups',
                    color: AppColors.success,
                    onTap: () => _navigateToSendMessage(context, 'to_groups'),
                  ),
                  _MessageTypeOption(
                    icon: Icons.text_snippet_outlined,
                    title: t?.translate('longSms') ?? 'Long SMS',
                    subtitle: t?.translate('longSmsDesc') ?? 'Send long text messages',
                    color: AppColors.info,
                    onTap: () => _navigateToSendMessage(context, 'long_sms'),
                  ),
                  _MessageTypeOption(
                    icon: Icons.mic_outlined,
                    title: t?.translate('voiceSms') ?? 'Voice SMS',
                    subtitle: t?.translate('voiceSmsDesc') ?? 'Send recorded voice messages',
                    color: AppColors.warning,
                    onTap: () => _navigateToSendMessage(context, 'voice_sms'),
                  ),
                  _MessageTypeOption(
                    icon: Icons.attach_file_outlined,
                    title: t?.translate('fileSms') ?? 'File SMS',
                    subtitle: t?.translate('fileSmsDesc') ?? 'Send messages with attached files',
                    color: AppColors.balancePurpleStart,
                    onTap: () => _navigateToSendMessage(context, 'file_sms'),
                  ),
                ],
              );
            }),

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
                  color: color.withOpacity(0.1),
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
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        fontFamily: 'IBMPlexSansArabic',
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
