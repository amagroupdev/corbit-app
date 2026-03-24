import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/messages/data/models/message_model.dart';

/// Card displaying a sent message's summary in the message center list.
///
/// Shows sender name, message preview, date, recipient count, and
/// a colored status badge.
class MessageCard extends StatelessWidget {
  const MessageCard({
    required this.message,
    this.onTap,
    super.key,
  });

  final SentMessageModel message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Top Row: Sender + Status Badge ────────────────────
            Row(
              children: [
                // Sender icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Sender name + date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.senderName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(context, message.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                _StatusBadge(status: message.status),
              ],
            ),

            const SizedBox(height: 12),

            // ─── Message Preview ──────────────────────────────────
            Text(
              message.messageBody,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
            ),

            const SizedBox(height: 12),

            // ─── Bottom Row: Stats ────────────────────────────────
            Row(
              children: [
                _StatChip(
                  icon: Icons.people_outline,
                  label: '${message.recipientCount}',
                  tooltip: AppLocalizations.of(context)!.translate('msg_recipients_count_tooltip'),
                ),
                const SizedBox(width: 16),
                if (message.deliveredCount != null)
                  _StatChip(
                    icon: Icons.check_circle_outline,
                    label: '${message.deliveredCount}',
                    tooltip: AppLocalizations.of(context)!.translate('msg_delivered_tooltip'),
                    color: AppColors.success,
                  ),
                if (message.deliveredCount != null) const SizedBox(width: 16),
                if (message.failedCount != null && message.failedCount! > 0)
                  _StatChip(
                    icon: Icons.error_outline,
                    label: '${message.failedCount}',
                    tooltip: AppLocalizations.of(context)!.translate('msg_failed_tooltip'),
                    color: AppColors.error,
                  ),
                const Spacer(),
                if (message.cost != null)
                  Text(
                    '${message.cost!.toStringAsFixed(1)} ${AppLocalizations.of(context)!.translate('msg_cost_unit')}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final t = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return t.translate('msg_time_now');
    if (diff.inHours < 1) return t.translateWithParams('msg_time_minutes_ago', {'count': '${diff.inMinutes}'});
    if (diff.inDays < 1) return t.translateWithParams('msg_time_hours_ago', {'count': '${diff.inHours}'});
    if (diff.inDays == 1) return t.translate('msg_time_yesterday');
    if (diff.inDays < 7) return t.translateWithParams('msg_time_days_ago', {'count': '${diff.inDays}'});

    final locale = t.currentLocaleCode;
    return DateFormat('yyyy/MM/dd - HH:mm', locale).format(date);
  }
}

// ─── Status Badge ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusColor.withOpacity(0.3)),
      ),
      child: Text(
        AppLocalizations.of(context)!.translate(status.labelKey),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _statusColor,
        ),
      ),
    );
  }

  Color get _statusColor {
    return switch (status) {
      MessageStatus.sent => AppColors.messageSent,
      MessageStatus.delivered => AppColors.messageDelivered,
      MessageStatus.pending => AppColors.messagePending,
      MessageStatus.failed => AppColors.messageFailed,
      MessageStatus.scheduled => AppColors.messageScheduled,
      MessageStatus.rejected => AppColors.messageRejected,
      MessageStatus.expired => AppColors.messageExpired,
    };
  }

  Color get _surfaceColor {
    return switch (status) {
      MessageStatus.sent => AppColors.infoSurface,
      MessageStatus.delivered => AppColors.successSurface,
      MessageStatus.pending => AppColors.warningSurface,
      MessageStatus.failed => AppColors.errorSurface,
      MessageStatus.scheduled => const Color(0xFFF3EEFF),
      MessageStatus.rejected => const Color(0xFFF5F5F5),
      MessageStatus.expired => const Color(0xFFEFEBE9),
    };
  }
}

// ─── Stat Chip ───────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    this.tooltip,
    this.color,
  });

  final IconData icon;
  final String label;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textSecondary;

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: effectiveColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: effectiveColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}
