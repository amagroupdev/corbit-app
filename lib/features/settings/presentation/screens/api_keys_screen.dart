import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/utils/validators.dart';
import 'package:orbit_app/features/settings/data/models/api_key_model.dart';
import 'package:orbit_app/features/settings/presentation/controllers/settings_controller.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

import 'package:orbit_app/core/localization/app_localizations.dart';
/// Screen for managing API keys: list, create, copy, delete.
class ApiKeysScreen extends ConsumerWidget {
  const ApiKeysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keysAsync = ref.watch(apiKeysProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('apiKeys')),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: keysAsync.when(
        data: (keys) {
          if (keys.isEmpty) {
            return AppEmptyState(
              icon: Icons.vpn_key_rounded,
              title: AppLocalizations.of(context)!.translate('api_keys_empty'),
              description: AppLocalizations.of(context)!.translate('api_keys_empty_desc'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(apiKeysProvider.notifier).refresh(),
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: keys.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final key = keys[index];
                return _ApiKeyCard(
                  apiKey: key,
                  onCopy: () => _copyKey(context, key),
                  onDelete: () => _deleteKey(context, ref, key),
                );
              },
            ),
          );
        },
        loading: () => AppLoading.listShimmer(),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.read(apiKeysProvider.notifier).refresh(),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)!.translate('api_keys_create_title'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: AppTextField(
            label: AppLocalizations.of(context)!.translate('api_keys_name_label'),
            hint: AppLocalizations.of(context)!.translate('api_keys_name_hint'),
            controller: nameController,
            validator: (v) =>
                Validators.validateRequired(v, fieldName: AppLocalizations.of(context)!.translate('api_keys_name_label')),
            textInputAction: TextInputAction.done,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              Navigator.pop(dialogContext);

              try {
                final newKey = await ref
                    .read(apiKeysProvider.notifier)
                    .create(nameController.text.trim());

                if (context.mounted) {
                  _showNewKeyDialog(context, newKey);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${AppLocalizations.of(context)!.translate('error_prefix')}: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(AppLocalizations.of(context)!.translate('sub_accounts_create_btn')),
          ),
        ],
      ),
    );
  }

  void _showNewKeyDialog(BuildContext context, ApiKeyModel key) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.translate('api_keys_created'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('api_keys_save_warning'),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      key.key ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: key.key ?? ''));
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(dialogContext)!.translate('api_keys_copied')),
                          duration: Duration(seconds: 2),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    color: AppColors.primary,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(AppLocalizations.of(context)!.translate('api_keys_understood')),
          ),
        ],
      ),
    );
  }

  void _copyKey(BuildContext context, ApiKeyModel key) {
    Clipboard.setData(ClipboardData(text: key.key ?? ''));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.translate('api_keys_copied')),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _deleteKey(
    BuildContext context,
    WidgetRef ref,
    ApiKeyModel key,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('api_keys_delete_title')),
        content: Text(
          '${AppLocalizations.of(context)!.translate('api_keys_delete_confirm_prefix')} "${key.name}"?\n'
          '${AppLocalizations.of(context)!.translate('api_keys_delete_confirm_suffix')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppLocalizations.of(context)!.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(apiKeysProvider.notifier).delete(key.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('api_keys_deleted')),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.translate('error_prefix')}: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

// ── API Key Card ─────────────────────────────────────────────────────────

class _ApiKeyCard extends StatelessWidget {
  const _ApiKeyCard({
    required this.apiKey,
    required this.onCopy,
    required this.onDelete,
  });

  final ApiKeyModel apiKey;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.vpn_key_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      apiKey.name ?? AppLocalizations.of(context)!.translate('api_keys_no_name'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      apiKey.maskedKey,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (apiKey.createdAt != null)
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)!.translate('api_keys_created_at')}: ${apiKey.createdAt}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              // Copy button
              TextButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: Text(AppLocalizations.of(context)!.translate('copy')),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontSize: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 4),
              // Delete button
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: Text(AppLocalizations.of(context)!.translate('delete')),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  textStyle: const TextStyle(fontSize: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
