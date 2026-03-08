import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/absence/data/models/absence_message_model.dart';

/// A card widget displaying an absence/tardiness message summary.
class AbsenceMessageCard extends StatelessWidget {
  const AbsenceMessageCard({
    required this.message,
    this.onView,
    this.onReport,
    super.key,
  });

  final AbsenceMessageModel message;
  final VoidCallback? onView;
  final VoidCallback? onReport;

  Color get _statusColor {
    return switch (message.status) {
      'accepted' || 'sent' => AppColors.success,
      'rejected' || 'failed' => AppColors.error,
      'expired' => AppColors.badgeNeutral,
      'under_review' || 'pending' => AppColors.warning,
      _ => AppColors.textHint,
    };
  }

  IconData get _messageTypeIcon {
    return switch (message.messageType) {
      'absence' => Icons.person_off_outlined,
      'tardiness' => Icons.schedule_outlined,
      _ => Icons.mail_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = intl.DateFormat('yyyy/MM/dd HH:mm', 'ar');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onView,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: icon, sender name, status badge
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _messageTypeIcon,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.senderName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message.messageTypeLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        message.statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Info row: send time, receive time, recipients
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.send_outlined,
                      label: dateFormat.format(message.sendTime),
                      tooltip: '\u0648\u0642\u062A \u0627\u0644\u0625\u0631\u0633\u0627\u0644', // وقت الإرسال
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: Icons.people_outline,
                      label: '${message.recipientCount}',
                      tooltip: '\u0639\u062F\u062F \u0627\u0644\u0645\u0633\u062A\u0644\u0645\u064A\u0646', // عدد المستلمين
                    ),
                    const Spacer(),
                    if (onView != null)
                      IconButton(
                        icon: const Icon(
                          Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        onPressed: onView,
                        splashRadius: 20,
                        tooltip: '\u0639\u0631\u0636', // عرض
                      ),
                    if (onReport != null)
                      IconButton(
                        icon: const Icon(
                          Icons.assessment_outlined,
                          size: 20,
                          color: AppColors.info,
                        ),
                        onPressed: onReport,
                        splashRadius: 20,
                        tooltip: '\u062A\u0642\u0631\u064A\u0631', // تقرير
                      ),
                  ],
                ),
                // Receive time row (if available)
                if (message.receiveTime != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.call_received_outlined,
                        label: dateFormat.format(message.receiveTime!),
                        tooltip: '\u0648\u0642\u062A \u0627\u0644\u0625\u0633\u062A\u0644\u0627\u0645', // وقت الإستلام
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.tooltip,
  });

  final IconData icon;
  final String label;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
