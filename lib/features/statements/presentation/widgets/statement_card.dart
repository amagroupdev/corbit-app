import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/statements/data/models/statement_response_model.dart';

/// Displays a single statement response as a card with name, phone,
/// response text, send/response times, and action icons.
///
/// Supports swipe-to-delete via [Dismissible].
class StatementCard extends StatelessWidget {
  const StatementCard({
    required this.item,
    this.onTap,
    this.onDelete,
    this.onExport,
    this.onViewMessage,
    this.onDownloadAttachment,
    this.onDismissed,
    this.languageCode = 'ar',
    super.key,
  });

  final StatementResponseItem item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onExport;
  final VoidCallback? onViewMessage;
  final VoidCallback? onDownloadAttachment;
  final VoidCallback? onDismissed;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd - hh:mm a', languageCode);
    final formattedSendTime = dateFormat.format(item.sendTime);
    final formattedResponseTime = dateFormat.format(item.responseTime);

    Widget card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 1,
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.primarySurface,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row: name + actions ────────────────────
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          item.name.isNotEmpty
                              ? item.name[0].toUpperCase()
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

                    // Name + phone number
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
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
                            item.phoneNumber,
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

                    // Action icons
                    _buildActionIcons(),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Response text preview ────────────────────────
                Text(
                  item.responseText,
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

                // ── Sender account ───────────────────────────────
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.senderAccount,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // ── Footer: times ────────────────────────────────
                Row(
                  children: [
                    // Send time
                    const Icon(
                      Icons.send_outlined,
                      size: 13,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        formattedSendTime,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Response time
                    const Icon(
                      Icons.reply_outlined,
                      size: 13,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        formattedResponseTime,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Wrap with Dismissible for swipe-to-delete.
    if (onDismissed != null) {
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
                '\u062D\u0630\u0641',
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

  Widget _buildActionIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // View message
        if (onViewMessage != null)
          _ActionIcon(
            icon: Icons.visibility_outlined,
            color: AppColors.info,
            onTap: onViewMessage!,
            tooltip: '\u0639\u0631\u0636 \u0627\u0644\u0631\u0633\u0627\u0644\u0629',
          ),

        // Download attachment
        if (item.attachmentUrl != null && item.attachmentUrl!.isNotEmpty)
          _ActionIcon(
            icon: Icons.attach_file_outlined,
            color: AppColors.warning,
            onTap: onDownloadAttachment ?? () {},
            tooltip: '\u062A\u062D\u0645\u064A\u0644 \u0627\u0644\u0645\u0631\u0641\u0642',
          ),

        // Export
        if (onExport != null)
          _ActionIcon(
            icon: Icons.file_download_outlined,
            color: AppColors.warning,
            onTap: onExport!,
            tooltip: '\u062A\u0635\u062F\u064A\u0631',
          ),

        // Delete
        if (onDelete != null)
          _ActionIcon(
            icon: Icons.delete_outline,
            color: AppColors.error,
            onTap: onDelete!,
            tooltip: '\u062D\u0630\u0641',
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Icon Widget
// ─────────────────────────────────────────────────────────────────────────────

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }
}
