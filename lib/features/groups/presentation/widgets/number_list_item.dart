import 'package:flutter/material.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/groups/data/models/number_model.dart';

/// A list tile widget representing a phone number entry within a group.
///
/// Supports swipe-to-delete, long-press for edit, and displays the
/// contact name, phone number, and optional identifier.
class NumberListItem extends StatelessWidget {
  const NumberListItem({
    required this.numberModel,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final NumberModel numberModel;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
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
      child: InkWell(
        onLongPress: onEdit,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.primarySurface,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
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

              // Edit icon
              if (onEdit != null)
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
      ),
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
