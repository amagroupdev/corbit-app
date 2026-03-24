import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/questionnaires/data/models/questionnaire_model.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';

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

  String _statusLabel(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    switch (questionnaire.status) {
      case 'sent':
        return t.translate('questionnaireSent');
      case 'draft':
        return t.translate('questionnaireDraft');
      default:
        return t.translate('questionnaireUnsent');
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
                        _statusLabel(context),
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
                      tooltip: AppLocalizations.of(context)!.translate('recipientsLabel'),
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      icon: Icons.check_circle_outline,
                      label: '${questionnaire.responseCount}',
                      tooltip: AppLocalizations.of(context)!.translate('repliesLabel'),
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
                        tooltip: AppLocalizations.of(context)!.translate('submit'),
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
                        tooltip: AppLocalizations.of(context)!.translate('delete'),
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
