import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/groups/data/models/group_model.dart';

/// A card widget that displays a group summary in the groups list.
///
/// Shows the group name, numbers count, creation date, and
/// an optional trashed indicator. Supports swipe-to-reveal actions.
///
/// Multi-select (Wave 6): when [isMultiSelectMode] is true the card
/// hides its swipe actions, draws a checkbox + selection highlight,
/// and routes [onTap] to selection toggling. [onLongPress] enters
/// multi-select mode from the host screen.
class GroupCard extends StatelessWidget {
  const GroupCard({
    required this.group,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onRestore,
    this.onLongPress,
    this.isMultiSelectMode = false,
    this.isSelected = false,
    super.key,
  });

  final GroupModel group;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onLongPress;
  final bool isMultiSelectMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final t = AppLocalizations.of(context)!;

    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primarySurface,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySurface : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: AppColors.primary, width: 2)
                : group.isTrashed
                    ? Border.all(color: AppColors.errorBorder, width: 1)
                    : null,
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: _buildRow(context, t, dateFormat),
        ),
      ),
    );

    // While in multi-select mode swipe gestures are disabled so the
    // user can scroll the list without triggering edit/delete.
    if (isMultiSelectMode) return card;

    return Dismissible(
      key: ValueKey('group_${group.id}'),
      direction: group.isTrashed
          ? DismissDirection.endToStart
          : DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit?.call();
          return false;
        } else {
          if (group.isTrashed) {
            onRestore?.call();
          } else {
            onDelete?.call();
          }
          return false;
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.info,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.edit_outlined, color: Colors.white, size: 24),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: group.isTrashed ? AppColors.success : AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          group.isTrashed ? Icons.restore_outlined : Icons.delete_outline,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: card,
    );
  }

  Widget _buildRow(
    BuildContext context,
    AppLocalizations t,
    DateFormat dateFormat,
  ) {
    return Row(
      children: [
        if (isMultiSelectMode) ...[
          Icon(
            isSelected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: isSelected ? AppColors.primary : AppColors.textHint,
            size: 22,
          ),
          const SizedBox(width: 8),
        ],
        // Group icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: group.isTrashed
                ? AppColors.errorSurface
                : AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            group.isTrashed ? Icons.delete_outlined : Icons.people,
            color: group.isTrashed ? AppColors.error : AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),

        // Group info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${group.numbersCount} ${t.translate('numberUnit')}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (group.createdAt != null) ...[
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(group.createdAt!),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Trashed badge or arrow
        if (group.isTrashed)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.errorSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              t.translate('trashed'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          )
        else if (!isMultiSelectMode)
          const Icon(
            Icons.chevron_right,
            color: AppColors.textHint,
            size: 24,
          ),
      ],
    );
  }
}
