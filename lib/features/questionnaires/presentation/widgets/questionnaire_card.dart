import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/questionnaires/data/models/questionnaire_model.dart';

/// A card widget displaying a questionnaire summary.
class QuestionnaireCard extends StatelessWidget {
  const QuestionnaireCard({
    required this.questionnaire,
    this.onTap,
    this.onSend,
    this.onDelete,
    super.key,
  });

  final QuestionnaireModel questionnaire;
  final VoidCallback? onTap;
  final VoidCallback? onSend;
  final VoidCallback? onDelete;

  Color get _statusColor {
    switch (questionnaire.status) {
      case 'sent':
        return AppColors.success;
      case 'draft':
        return AppColors.warning;
      default:
        return AppColors.textHint;
    }
  }

  String get _statusLabel {
    switch (questionnaire.status) {
      case 'sent':
        return '\u0645\u0631\u0633\u0644'; // مرسل
      case 'draft':
        return '\u0645\u0633\u0648\u062F\u0629'; // مسودة
      default:
        return '\u063A\u064A\u0631 \u0645\u0631\u0633\u0644'; // غير مرسل
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = intl.DateFormat('yyyy/MM/dd', 'ar');

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
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.quiz_outlined,
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
                            questionnaire.title,
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
                            dateFormat.format(questionnaire.createdAt),
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
                        _statusLabel,
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
                // Stats row
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.people_outline,
                      label: '${questionnaire.recipientCount}',
                      tooltip: '\u0627\u0644\u0645\u0633\u062A\u0644\u0645\u064A\u0646', // المستلمين
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      icon: Icons.check_circle_outline,
                      label: '${questionnaire.responseCount}',
                      tooltip: '\u0627\u0644\u0631\u062F\u0648\u062F', // الردود
                    ),
                    const Spacer(),
                    if (onSend != null && !questionnaire.isSent)
                      IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        onPressed: onSend,
                        splashRadius: 20,
                        tooltip: '\u0625\u0631\u0633\u0627\u0644', // إرسال
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: AppColors.error,
                        ),
                        onPressed: onDelete,
                        splashRadius: 20,
                        tooltip: '\u062D\u0630\u0641', // حذف
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

class _StatChip extends StatelessWidget {
  const _StatChip({
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
