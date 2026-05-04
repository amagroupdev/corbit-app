import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/messages/data/models/dynamic_text_model.dart';
import 'package:orbit_app/features/messages/presentation/controllers/messages_controller.dart';

/// Bottom sheet that lists the dynamic-text variables exposed by the
/// gateway (`/messages/dynamic-texts`) and lets the user insert one
/// into the active message body at the current cursor position.
///
/// The list is fetched via [dynamicTextsProvider] which caches the
/// response for the lifetime of the provider, so opening the picker a
/// second time does not re-hit the network.
class DynamicTextsPicker {
  /// Opens the picker as a modal bottom sheet.
  ///
  /// Returns the selected [DynamicTextModel], or null if dismissed.
  static Future<DynamicTextModel?> show(BuildContext context) {
    return showModalBottomSheet<DynamicTextModel>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _DynamicTextsSheet(),
    );
  }
}

class _DynamicTextsSheet extends ConsumerWidget {
  const _DynamicTextsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final asyncTexts = ref.watch(dynamicTextsProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.alternate_email,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    t.translate('dynamicTextsTitle'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Flexible(
              child: asyncTexts.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  ),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      t.translate('dynamicTextsEmpty'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                data: (texts) {
                  if (texts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          t.translate('dynamicTextsEmpty'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: texts.length,
                    itemBuilder: (context, index) {
                      final variable = texts[index];
                      return ListTile(
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            variable.token,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                        title: Text(
                          variable.label,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: variable.description != null &&
                                variable.description!.isNotEmpty
                            ? Text(
                                variable.description!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              )
                            : null,
                        onTap: () => Navigator.pop(context, variable),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
