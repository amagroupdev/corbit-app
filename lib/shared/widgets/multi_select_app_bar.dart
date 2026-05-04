import 'package:flutter/material.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';

/// A drop-in [PreferredSizeWidget] used as the [Scaffold.appBar] when a
/// list screen is in multi-select mode (Wave 6 — bulk operations).
///
/// Shows the current selection count, a Cancel/close button on the
/// leading side, an optional "Select all" toggle, and an arbitrary
/// list of trailing [actions] (delete, move, copy, resend …).
///
/// Tap on a single list item still opens its detail — multi-select is
/// **only** entered through long-press on the host screen, then this
/// widget replaces the regular AppBar while [selectedCount] > 0.
///
/// Example:
/// ```dart
/// appBar: isMultiSelect
///     ? MultiSelectAppBar(
///         selectedCount: selected.length,
///         onCancel: _exitMultiSelect,
///         onSelectAll: _selectAll,
///         actions: [
///           IconButton(icon: const Icon(Icons.delete_outline), onPressed: _bulkDelete),
///         ],
///       )
///     : AppBar(title: Text(t.translate('groups'))),
/// ```
class MultiSelectAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MultiSelectAppBar({
    required this.selectedCount,
    required this.onCancel,
    this.onSelectAll,
    this.actions,
    this.totalCount,
    super.key,
  });

  /// Number of items currently selected. Displayed in the title.
  final int selectedCount;

  /// Called when the user taps the leading close icon to leave
  /// multi-select mode.
  final VoidCallback onCancel;

  /// Optional handler for the trailing "select all" action. When null
  /// the action is hidden.
  final VoidCallback? onSelectAll;

  /// Trailing action widgets (typically [IconButton]s for delete,
  /// move, copy, resend …).
  final List<Widget>? actions;

  /// Optional total count rendered as `"3 / 12"` in the title when
  /// provided. Useful when "select all" is meaningful.
  final int? totalCount;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final title = totalCount == null
        ? t.translateWithParams('bulkSelectCount', {'count': '$selectedCount'})
        : '$selectedCount / $totalCount';

    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: onCancel,
        tooltip: t.translate('bulkCancel'),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      actions: [
        if (onSelectAll != null)
          TextButton(
            onPressed: onSelectAll,
            child: Text(
              t.translate('bulkSelectAll'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (actions != null) ...actions!,
        const SizedBox(width: 4),
      ],
    );
  }
}
