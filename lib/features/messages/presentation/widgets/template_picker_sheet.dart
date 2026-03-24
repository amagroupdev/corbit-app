import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/messages/data/models/template_model.dart';
import 'package:orbit_app/features/messages/presentation/controllers/messages_controller.dart';

/// Bottom sheet listing available message templates.
///
/// Features:
/// - Search/filter templates by name or body
/// - Select a template to insert its body into the message composer
/// - Create new template option
class TemplatePickerSheet extends ConsumerStatefulWidget {
  const TemplatePickerSheet({
    this.scrollController,
    this.onCreateNew,
    super.key,
  });

  /// Optional scroll controller provided by [DraggableScrollableSheet].
  final ScrollController? scrollController;

  /// Callback when the user taps "Create new template".
  final VoidCallback? onCreateNew;

  /// Shows the template picker as a modal bottom sheet.
  ///
  /// Returns the selected [TemplateModel] or `null` if dismissed.
  static Future<TemplateModel?> show(
    BuildContext context, {
    VoidCallback? onCreateNew,
  }) {
    return showModalBottomSheet<TemplateModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return TemplatePickerSheet(
            scrollController: scrollController,
            onCreateNew: onCreateNew,
          );
        },
      ),
    );
  }

  @override
  ConsumerState<TemplatePickerSheet> createState() =>
      _TemplatePickerSheetState();
}

class _TemplatePickerSheetState extends ConsumerState<TemplatePickerSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TemplateModel> _filterTemplates(List<TemplateModel> templates) {
    if (_searchQuery.isEmpty) return templates;
    final query = _searchQuery.toLowerCase();
    return templates
        .where((t) =>
            t.name.toLowerCase().contains(query) ||
            t.body.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider);

    return Column(
      children: [
        // ─── Handle Bar ────────────────────────────────────────
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // ─── Header ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              const Icon(
                Icons.description_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.translate('msg_select_template'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Create new template
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onCreateNew?.call();
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  AppLocalizations.of(context)!.translate('msg_new_template'),
                  style: const TextStyle(fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ─── Search Bar ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.translate('msg_search_template'),
              hintStyle: const TextStyle(
                color: AppColors.textHint,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
                size: 20,
              ),
              filled: true,
              fillColor: AppColors.inputFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.inputBorderFocused,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),
        const Divider(height: 1),

        // ─── Template List ─────────────────────────────────────
        Expanded(
          child: templatesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.translate('msg_templates_load_failed'),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.invalidate(templatesProvider),
                    child: Text(AppLocalizations.of(context)!.translate('retry')),
                  ),
                ],
              ),
            ),
            data: (templates) {
              final filtered = _filterTemplates(templates);

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _searchQuery.isNotEmpty
                            ? Icons.search_off
                            : Icons.description_outlined,
                        color: AppColors.textHint,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty
                            ? AppLocalizations.of(context)!.translate('msg_no_matching_results')
                            : AppLocalizations.of(context)!.translate('msg_no_saved_templates'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                controller: widget.scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 20, endIndent: 20),
                itemBuilder: (context, index) {
                  final template = filtered[index];
                  return _TemplateListTile(
                    template: template,
                    onTap: () => Navigator.pop(context, template),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Template List Tile ──────────────────────────────────────────────────────

class _TemplateListTile extends StatelessWidget {
  const _TemplateListTile({
    required this.template,
    required this.onTap,
  });

  final TemplateModel template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.article_outlined,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.body,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
