import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/utils/validators.dart';
import 'package:orbit_app/features/settings/data/models/contract_model.dart';
import 'package:orbit_app/features/settings/presentation/controllers/settings_controller.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

import 'package:orbit_app/core/localization/app_localizations.dart';
/// Screen for managing contracts: list, create, upload documents, delete.
class ContractsScreen extends ConsumerWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsync = ref.watch(contractsProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('contracts')),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateForm(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: contractsAsync.when(
        data: (paginated) {
          if (paginated.isEmpty) {
            return AppEmptyState(
              icon: Icons.description_outlined,
              title: AppLocalizations.of(context)!.translate('contracts_empty'),
              description: AppLocalizations.of(context)!.translate('contracts_empty_desc'),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(contractsProvider.notifier).refresh(),
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: paginated.data.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final contract = paginated.data[index];
                return _ContractCard(
                  contract: contract,
                  onUploadDocument: () =>
                      _uploadDocument(context, ref, contract.id),
                  onDelete: () =>
                      _deleteContract(context, ref, contract.id),
                );
              },
            ),
          );
        },
        loading: () => AppLoading.listShimmer(),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () =>
              ref.read(contractsProvider.notifier).refresh(),
        ),
      ),
    );
  }

  void _showCreateForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const _CreateContractScreen(),
      ),
    );
  }

  Future<void> _uploadDocument(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    try {
      final multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: file.name,
      );
      await ref
          .read(contractsProvider.notifier)
          .uploadDocument(id, multipartFile);

      await ref.read(contractsProvider.notifier).refresh();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('contracts_doc_uploaded')),
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

  Future<void> _deleteContract(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('contracts_delete_title')),
        content: Text(AppLocalizations.of(context)!.translate('contracts_delete_confirm')),
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
        await ref.read(contractsProvider.notifier).delete(id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('contracts_deleted')),
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

// ── Contract Card ────────────────────────────────────────────────────────

class _ContractCard extends StatelessWidget {
  const _ContractCard({
    required this.contract,
    required this.onUploadDocument,
    required this.onDelete,
  });

  final ContractModel contract;
  final VoidCallback onUploadDocument;
  final VoidCallback onDelete;

  Color get _statusColor {
    return switch (contract.status?.toLowerCase()) {
      'active' => AppColors.success,
      'pending' => AppColors.warning,
      'expired' => AppColors.error,
      'cancelled' => AppColors.textSecondary,
      _ => AppColors.textSecondary,
    };
  }

  Color get _statusBgColor {
    return switch (contract.status?.toLowerCase()) {
      'active' => AppColors.successSurface,
      'pending' => AppColors.warningSurface,
      'expired' => AppColors.errorSurface,
      _ => AppColors.surfaceVariant,
    };
  }

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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contract.organizationName ?? '${AppLocalizations.of(context)!.translate('contracts_contract_prefix')} #${contract.id}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (contract.organizationType != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        contract.organizationType!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.of(context)!.translate(contract.statusLabelKey),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),

          if (contract.startDate != null || contract.endDate != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 6),
                Text(
                  '${contract.startDate ?? '-'} - ${contract.endDate ?? '-'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 8),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onUploadDocument,
                icon: const Icon(Icons.upload_file_rounded, size: 16),
                label: Text(AppLocalizations.of(context)!.translate('contracts_upload_doc')),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: Text(AppLocalizations.of(context)!.translate('delete')),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Create Contract Screen ───────────────────────────────────────────────

class _CreateContractScreen extends ConsumerStatefulWidget {
  const _CreateContractScreen();

  @override
  ConsumerState<_CreateContractScreen> createState() =>
      _CreateContractScreenState();
}

class _CreateContractScreenState
    extends ConsumerState<_CreateContractScreen> {
  final _formKey = GlobalKey<FormState>();
  final _organizationController = TextEditingController();
  final _notesController = TextEditingController();
  String? _documentPath;
  bool _isLoading = false;

  @override
  void dispose() {
    _organizationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('contracts_create_title')),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              label: AppLocalizations.of(context)!.translate('contracts_org_label'),
              hint: AppLocalizations.of(context)!.translate('contracts_org_hint'),
              controller: _organizationController,
              validator: (v) =>
                  Validators.validateRequired(v, fieldName: AppLocalizations.of(context)!.translate('contracts_org_label')),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            AppTextField(
              label: AppLocalizations.of(context)!.translate('contracts_notes_label'),
              hint: AppLocalizations.of(context)!.translate('contracts_notes_hint'),
              controller: _notesController,
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),

            // Document upload
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.translate('contracts_document_label'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDocument,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _documentPath != null
                            ? AppColors.success
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _documentPath != null
                              ? Icons.check_circle_rounded
                              : Icons.cloud_upload_outlined,
                          size: 40,
                          color: _documentPath != null
                              ? AppColors.success
                              : AppColors.textHint,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _documentPath != null
                              ? _documentPath!.split('/').last
                              : AppLocalizations.of(context)!.translate('contracts_upload_doc_btn'),
                          style: TextStyle(
                            fontSize: 14,
                            color: _documentPath != null
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            AppButton.primary(
              text: AppLocalizations.of(context)!.translate('contracts_create_button'),
              onPressed: _isLoading ? null : _submit,
              isLoading: _isLoading,
              icon: Icons.add_rounded,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _documentPath = file.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = <String, dynamic>{
        'organization_name': _organizationController.text.trim(),
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
      };

      final result =
          await ref.read(contractsProvider.notifier).create(data);

      final success = result['success'] as bool? ?? false;
      final contractId = result['data']?['id'] as int?;

      // Upload document if available
      if (success && contractId != null && _documentPath != null) {
        final file = await MultipartFile.fromFile(
          _documentPath!,
          filename: _documentPath!.split('/').last,
        );
        await ref
            .read(contractsProvider.notifier)
            .uploadDocument(contractId, file);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? AppLocalizations.of(context)!.translate('contracts_created') : AppLocalizations.of(context)!.translate('contracts_create_failed'),
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        if (success) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.translate('error_prefix')}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
