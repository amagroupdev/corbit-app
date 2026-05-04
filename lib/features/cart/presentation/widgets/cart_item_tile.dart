import 'package:flutter/material.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/cart/data/models/cart_item_model.dart';

/// A single line in the cart screen.
class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.onRemove,
    this.removing = false,
  });

  final CartItemModel item;
  final VoidCallback onRemove;
  final bool removing;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icon / placeholder.
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _iconFor(item.itemType),
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Title + subtitle + line total.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle != null && item.subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.lineTotal.toStringAsFixed(2)} SAR',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // Remove button.
            IconButton(
              tooltip: t?.translate('cartItemRemove') ?? 'Remove',
              icon: removing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              color: theme.colorScheme.error,
              onPressed: removing ? null : onRemove,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'package':
        return Icons.sms_outlined;
      case 'service':
        return Icons.extension_outlined;
      case 'sender':
        return Icons.badge_outlined;
      default:
        return Icons.shopping_bag_outlined;
    }
  }
}
