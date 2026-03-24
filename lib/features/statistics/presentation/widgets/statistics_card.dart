import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/statistics/data/models/statistics_model.dart';

/// Displays a single statistics record as a styled card.
///
/// Shows student name, class, type, date, teacher (if applicable),
/// notes, and an SMS-sent indicator.
class StatisticsCard extends StatelessWidget {
  const StatisticsCard({
    required this.item,
    this.statisticsType = StatisticsType.absenceLateness,
    this.onTap,
    this.languageCode = 'ar',
    super.key,
  });

  final StatisticsItem item;
  final StatisticsType statisticsType;
  final VoidCallback? onTap;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd', languageCode);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.primarySurface,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Student name + type badge ────────────
                Row(
                  children: [
                    // Student avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _typeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          _typeIcon,
                          size: 20,
                          color: _typeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Student info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.studentName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.className != null ||
                              item.section != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              [
                                if (item.className != null) item.className,
                                if (item.section != null) item.section,
                              ].join(' - '),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Type badge
                    _TypeBadge(
                      label: item.subType ?? item.type,
                      color: _typeColor,
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 10),

                // ── Detail rows ──────────────────────────────────
                // Student number
                if (item.studentNumber != null &&
                    item.studentNumber!.isNotEmpty)
                  _DetailRow(
                    icon: Icons.badge_outlined,
                    label: AppLocalizations.of(context)!.translate('stat_student_number'),
                    value: item.studentNumber!,
                  ),

                // Date
                if (item.date != null)
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: AppLocalizations.of(context)!.translate('date'),
                    value: dateFormat.format(item.date!),
                  ),

                // Teacher name
                if (item.teacherName != null &&
                    item.teacherName!.isNotEmpty)
                  _DetailRow(
                    icon: Icons.person_outlined,
                    label: AppLocalizations.of(context)!.translate('stat_teacher'),
                    value: item.teacherName!,
                  ),

                // Semester
                if (item.semester != null && item.semester!.isNotEmpty)
                  _DetailRow(
                    icon: Icons.school_outlined,
                    label: AppLocalizations.of(context)!.translate('stat_semester'),
                    value: item.semester!,
                  ),

                // Group
                if (item.groupName != null && item.groupName!.isNotEmpty)
                  _DetailRow(
                    icon: Icons.groups_outlined,
                    label: AppLocalizations.of(context)!.translate('stat_group'),
                    value: item.groupName!,
                  ),

                // Count (for aggregated records)
                if (item.count > 0)
                  _DetailRow(
                    icon: Icons.numbers,
                    label: AppLocalizations.of(context)!.translate('stat_count'),
                    value: item.count.toString(),
                    valueColor: AppColors.primary,
                  ),

                // Notes
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.note_outlined,
                          size: 16,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.notes!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Footer: SMS status + parent phone ────────────
                const SizedBox(height: 10),
                Row(
                  children: [
                    // SMS sent indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.messageSent
                            ? AppColors.successSurface
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.messageSent
                                ? Icons.check_circle_outlined
                                : Icons.cancel_outlined,
                            size: 14,
                            color: item.messageSent
                                ? AppColors.success
                                : AppColors.textHint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.messageSent
                                ? AppLocalizations.of(context)!.translate('stat_sms_sent')
                                : AppLocalizations.of(context)!.translate('stat_sms_not_sent'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: item.messageSent
                                  ? AppColors.success
                                  : AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Parent phone
                    if (item.parentPhone != null &&
                        item.parentPhone!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.parentPhone!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
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

  Color get _typeColor {
    return switch (statisticsType) {
      StatisticsType.absenceLateness => _absenceColor,
      StatisticsType.customMessages => _customMessageColor,
      StatisticsType.teacherMessages => AppColors.info,
    };
  }

  Color get _absenceColor {
    final subType = (item.subType ?? item.type).toLowerCase();
    if (subType.contains('absence') || subType.contains('غياب')) {
      return AppColors.error;
    }
    if (subType.contains('latency') || subType.contains('تأخر')) {
      return AppColors.warning;
    }
    return AppColors.info;
  }

  Color get _customMessageColor {
    final subType = (item.subType ?? '').toLowerCase();
    if (subType.contains('weakness') || subType.contains('ضعف')) {
      return AppColors.warning;
    }
    if (subType.contains('offence') || subType.contains('مخالفة')) {
      return AppColors.error;
    }
    if (subType.contains('distinction') || subType.contains('تميز')) {
      return AppColors.success;
    }
    return AppColors.info;
  }

  IconData get _typeIcon {
    return switch (statisticsType) {
      StatisticsType.absenceLateness => Icons.event_busy_outlined,
      StatisticsType.customMessages => Icons.message_outlined,
      StatisticsType.teacherMessages => Icons.school_outlined,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Type Badge
// ─────────────────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail Row
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textHint,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
