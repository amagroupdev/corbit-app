import 'package:flutter/material.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/groups/data/models/number_model.dart';

/// A list tile widget representing a phone number entry within a group.
///
/// Supports swipe-to-delete and long-press for edit. When the host
/// screen is in multi-select mode (Wave 6) the swipe is disabled, a
/// checkbox + selection highlight appears, and tap routes to the
/// selection toggle handler.
class NumberListItem extends StatelessWidget {
  const NumberListItem({
    required this.numberModel,
    this.onEdit,
    this.onDelete,
    this.onTap,
    this.onLongPress,
    this.isMultiSelectMode = false,
    this.isSelected = false,
    super.key,
  });

  final NumberModel numberModel;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isMultiSelectMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final tile = InkWell(
      onTap: onTap,
      onLongPress: onLongPress ?? onEdit,
      borderRadius: BorderRadius.circular(12),
      splashColor: AppColors.primarySurface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
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
            // Avatar circle with initials
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _getInitials(numberModel.name),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name and number
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (numberModel.name.isNotEmpty)
                    Text(
                      numberModel.name,
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
                    numberModel.number,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: numberModel.name.isEmpty
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: numberModel.name.isEmpty
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                  if (numberModel.identifier != null &&
                      numberModel.identifier!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      numberModel.identifier!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Edit icon (hidden in multi-select)
            if (!isMultiSelectMode && onEdit != null)
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: AppColors.textHint,
                ),
                onPressed: onEdit,
                splashRadius: 20,
              ),
          ],
        ),
      ),
    );

    if (isMultiSelectMode) return tile;

    return Dismissible(
      key: ValueKey('number_${numberModel.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        onDelete?.call();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: tile,
    );
  }

  /// Returns up to 2 initials from the name, or a phone icon placeholder.
  String _getInitials(String name) {
    if (name.isEmpty) return '#';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
