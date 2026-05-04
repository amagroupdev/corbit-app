import 'package:flutter/material.dart';

import 'package:orbit_app/core/constants/app_colors.dart';

/// Wrapper that adds a leading checkbox + selected highlight to any
/// list item when the host screen is in multi-select mode (Wave 6).
///
/// Important — multi-select must remain **opt-in**:
/// - default `tap` opens the item detail (passes through [onTap]),
/// - `long press` triggers [onEnterMultiSelect] to enter the mode,
/// - while [isMultiSelectMode] is true, `tap` toggles selection.
///
/// The widget never builds its own gesture area so callers can layer
/// it on top of existing cards/Dismissibles. Pass [child] as the
/// already-styled tile content.
///
/// Example:
/// ```dart
/// MultiSelectListTile(
///   isMultiSelectMode: state.isMultiSelect,
///   isSelected: state.selectedIds.contains(item.id),
///   onTap: () => context.pushNamed(...),
///   onEnterMultiSelect: () => _enterMultiSelect(item.id),
///   onToggleSelect: () => _toggleSelection(item.id),
///   child: GroupCard(group: item),
/// );
/// ```
class MultiSelectListTile extends StatelessWidget {
  const MultiSelectListTile({
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.child,
    this.onTap,
    this.onEnterMultiSelect,
    this.onToggleSelect,
    this.borderRadius = 12,
    super.key,
  });

  final bool isMultiSelectMode;
  final bool isSelected;
  final Widget child;

  /// Default tap when not in multi-select mode (open detail).
  final VoidCallback? onTap;

  /// Long press handler — should enter multi-select mode and select
  /// this item. Ignored while already in multi-select mode (in that
  /// case [onToggleSelect] handles the long press too, by tap).
  final VoidCallback? onEnterMultiSelect;

  /// Tap handler while in multi-select mode (toggle this item's
  /// selection state).
  final VoidCallback? onToggleSelect;

  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: isMultiSelectMode ? onToggleSelect : onTap,
        onLongPress: isMultiSelectMode ? onToggleSelect : onEnterMultiSelect,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: isSelected ? AppColors.primarySurface : null,
            border: isSelected
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isMultiSelectMode)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primary : AppColors.textHint,
                    size: 22,
                  ),
                ),
              Expanded(child: IgnorePointer(child: child)),
            ],
          ),
        ),
      ),
    );
  }
}
