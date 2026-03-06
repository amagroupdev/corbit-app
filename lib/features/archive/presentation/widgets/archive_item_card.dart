import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/archive/data/models/archive_model.dart';

/// Displays a single archive message as a card with sender, recipient,
/// message preview, date, and status badge.
///
/// Supports multi-select mode with a leading checkbox and swipe-to-action
/// via [Dismissible].
class ArchiveItemCard extends StatelessWidget {
  const ArchiveItemCard({
    required this.item,
    this.isSelected = false,
    this.isMultiSelectMode = false,
    this.onTap,
    this.onLongPress,
    this.onToggleSelect,
    this.onDismissed,
    this.languageCode = 'ar',
    super.key,
  });

  final ArchiveItem item;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleSelect;
  final VoidCallback? onDismissed;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd - hh:mm a', languageCode);
    final formattedDate = dateFormat.format(item.sentAt);

    Widget card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primarySurface
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
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
          onTap: isMultiSelectMode ? onToggleSelect : onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.primarySurface,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Checkbox (multi-select) ──────────────────────
                if (isMultiSelectMode) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => onToggleSelect?.call(),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: const BorderSide(
                          color: AppColors.borderDark,
                          width: 1.5,
                        ),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],

                // ── Content ──────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header row: sender + status ────────────
                      Row(
                        children: [
                          // Sender avatar
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                item.senderName.isNotEmpty
                                    ? item.senderName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Sender name + recipient
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.senderName,
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
                                  item.recipientName != null &&
                                          item.recipientName!.isNotEmpty
                                      ? '${item.recipientName} (${item.recipientNumber})'
                                      : item.recipientNumber,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Status badge
                          _StatusBadge(
                            status: item.status,
                            languageCode: languageCode,
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ── Message preview ────────────────────────
                      Text(
                        item.messageBody,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // ── Footer: date + message count ───────────
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textHint,
                            ),
                          ),
                          const Spacer(),
                          if (item.messageCount > 1) ...[
                            Icon(
                              Icons.sms_outlined,
                              size: 14,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.messageCount} SMS',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                          if (item.cost != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.monetization_on_outlined,
                              size: 14,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.cost!.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Wrap with Dismissible for swipe actions (only when not in multi-select).
    if (!isMultiSelectMode && onDismissed != null) {
      card = Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async => true,
        onDismissed: (_) => onDismissed?.call(),
        background: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.delete_outline, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'حذف',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        child: card,
      );
    }

    return card;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Badge Widget
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    this.languageCode = 'ar',
  });

  final ArchiveMessageStatus status;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    final bgColor = _statusBgColor;
    final label = status.label(languageCode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color get _statusColor {
    return switch (status) {
      ArchiveMessageStatus.sent => AppColors.info,
      ArchiveMessageStatus.delivered => AppColors.success,
      ArchiveMessageStatus.pending => AppColors.warning,
      ArchiveMessageStatus.failed => AppColors.error,
      ArchiveMessageStatus.rejected => AppColors.badgeNeutral,
      ArchiveMessageStatus.scheduled => AppColors.messageScheduled,
      ArchiveMessageStatus.cancelled => AppColors.textSecondary,
      ArchiveMessageStatus.expired => AppColors.messageExpired,
      ArchiveMessageStatus.unknown => AppColors.textHint,
    };
  }

  Color get _statusBgColor {
    return switch (status) {
      ArchiveMessageStatus.sent => AppColors.infoSurface,
      ArchiveMessageStatus.delivered => AppColors.successSurface,
      ArchiveMessageStatus.pending => AppColors.warningSurface,
      ArchiveMessageStatus.failed => AppColors.errorSurface,
      ArchiveMessageStatus.rejected => const Color(0xFFF5F5F5),
      ArchiveMessageStatus.scheduled => const Color(0xFFF3EEFF),
      ArchiveMessageStatus.cancelled => const Color(0xFFF5F5F5),
      ArchiveMessageStatus.expired => const Color(0xFFEFEBE9),
      ArchiveMessageStatus.unknown => AppColors.surfaceVariant,
    };
  }
}
