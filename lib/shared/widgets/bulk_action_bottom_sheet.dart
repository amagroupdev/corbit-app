import 'package:flutter/material.dart';

import 'package:orbit_app/core/constants/app_colors.dart';

/// One row inside a [BulkActionBottomSheet]. The [onTap] handler is
/// invoked with the parent [BuildContext] **after** the sheet has
/// already popped, so callers can safely show snackbars / dialogs.
class BulkAction {
  const BulkAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool isDestructive;
  final VoidCallback onTap;
}

/// Modal bottom sheet that lists context-aware bulk actions for the
/// currently selected items (Wave 6 — bulk operations).
///
/// Use it when the AppBar is too cramped to fit every action — e.g.
/// numbers screen needs delete + move + copy + share. Pass a
/// pre-formatted [title] (typically "3 numbers selected").
///
/// Example:
/// ```dart
/// BulkActionBottomSheet.show(
///   context: context,
///   title: t.translateWithParams('bulkSelectCount', {'count': '$count'}),
///   actions: [
///     BulkAction(icon: Icons.drive_file_move, label: t('bulkMove'),  onTap: _move),
///     BulkAction(icon: Icons.content_copy,    label: t('bulkCopy'),  onTap: _copy),
///     BulkAction(
///       icon: Icons.delete_outline,
///       label: t('bulkDelete'),
///       isDestructive: true,
///       onTap: _delete,
///     ),
///   ],
/// );
/// ```
class BulkActionBottomSheet extends StatelessWidget {
  const BulkActionBottomSheet({
    required this.title,
    required this.actions,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<BulkAction> actions;

  /// Presents the sheet. The future completes when the sheet closes.
  static Future<void> show({
    required BuildContext context,
    required String title,
    required List<BulkAction> actions,
    String? subtitle,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BulkActionBottomSheet(
        title: title,
        subtitle: subtitle,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final action in actions)
              _BulkActionTile(
                action: action,
                onTap: () {
                  Navigator.of(context).pop();
                  action.onTap();
                },
              ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _BulkActionTile extends StatelessWidget {
  const _BulkActionTile({required this.action, required this.onTap});

  final BulkAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        action.isDestructive ? AppColors.error : AppColors.textPrimary;
    final iconBg = action.isDestructive
        ? AppColors.errorSurface
        : AppColors.primarySurface;
    final iconColor =
        action.isDestructive ? AppColors.error : AppColors.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(action.icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  if (action.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
