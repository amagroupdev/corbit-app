import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/utils/validators.dart';
import 'package:orbit_app/features/settings/data/models/sender_request_model.dart';
import 'package:orbit_app/features/settings/presentation/controllers/settings_controller.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

import 'package:orbit_app/core/localization/app_localizations.dart';
/// Screen for managing sender name requests with status badges,
/// document uploads, and payment flow.
class SenderNamesScreen extends ConsumerWidget {
  const SenderNamesScreen({super.key, this.embedded = false});

  /// When true, renders without Scaffold/AppBar for embedding in tabs.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(senderRequestsProvider);

    final body = requestsAsync.when(
        data: (paginated) {
          if (paginated.isEmpty) {
            return AppEmptyState(
              icon: Icons.badge_outlined,
              title: AppLocalizations.of(context)!.translate('sender_empty'),
              description: AppLocalizations.of(context)!.translate('sender_empty_desc'),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(senderRequestsProvider.notifier).refresh(),
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: paginated.data.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final request = paginated.data[index];
                return _SenderRequestCard(
                  request: request,
                  onDelete: () => _deleteRequest(context, ref, request.id),
                  onUploadDocument: () =>
                      _uploadDocument(context, ref, request.id),
                  onInitiatePayment: () =>
                      _initiatePayment(context, ref, request.id),
                );
              },
            ),
          );
        },
        loading: () => AppLoading.listShimmer(),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () =>
              ref.read(senderRequestsProvider.notifier).refresh(),
        ),
      );

    if (embedded) return body;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('senderNames')),
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
      body: body,
    );
  }

  void _showCreateForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const _CreateSenderRequestScreen(),
      ),
    );
  }

  Future<void> _deleteRequest(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('sender_delete_title')),
        content: Text(AppLocalizations.of(context)!.translate('sender_delete_confirm')),
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
        await ref.read(senderRequestsProvider.notifier).delete(id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('sender_deleted')),
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
          .read(senderRequestsProvider.notifier)
          .uploadDocument(id, multipartFile);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('sender_doc_uploaded')),
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

  Future<void> _initiatePayment(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    try {
      final result = await ref
          .read(senderRequestsProvider.notifier)
          .initiatePayment(id);

      final paymentUrl = result['data']?['payment_url'] as String? ??
          result['payment_url'] as String?;

      if (context.mounted) {
        if (paymentUrl != null && paymentUrl.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('sender_payment_ready')),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] as String? ?? AppLocalizations.of(context)!.translate('operation_completed'),
              ),
              backgroundColor: AppColors.info,
            ),
          );
        }
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

// ── Sender Request Card ──────────────────────────────────────────────────

class _SenderRequestCard extends StatelessWidget {
  const _SenderRequestCard({
    required this.request,
    required this.onDelete,
    required this.onUploadDocument,
    required this.onInitiatePayment,
  });

  final SenderRequestModel request;
  final VoidCallback onDelete;
  final VoidCallback onUploadDocument;
  final VoidCallback onInitiatePayment;

  Color get _statusColor {
    return switch (request.status?.toLowerCase()) {
      'approved' || 'active' => AppColors.success,
      'rejected' => AppColors.error,
      'pending' => AppColors.warning,
      'payment_pending' => AppColors.info,
      _ => AppColors.textSecondary,
    };
  }

  Color get _statusBgColor {
    return switch (request.status?.toLowerCase()) {
      'approved' || 'active' => AppColors.successSurface,
      'rejected' => AppColors.errorSurface,
      'pending' => AppColors.warningSurface,
      'payment_pending' => AppColors.infoSurface,
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
                  Icons.badge_rounded,
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
                      request.name ?? AppLocalizations.of(context)!.translate('sender_status_unknown'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (request.organizationName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        request.organizationName!,
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
                  AppLocalizations.of(context)!.translate(request.statusLabelKey),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),

          if (request.isRejected &&
              request.rejectionReason != null &&
              request.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.rejectionReason!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 8),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (request.isPending) ...[
                TextButton.icon(
                  onPressed: onUploadDocument,
                  icon: const Icon(Icons.upload_file_rounded, size: 16),
                  label: Text(AppLocalizations.of(context)!.translate('sender_upload_doc')),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (request.status?.toLowerCase() == 'payment_pending')
                TextButton.icon(
                  onPressed: onInitiatePayment,
                  icon: const Icon(Icons.payment_rounded, size: 16),
                  label: Text(AppLocalizations.of(context)!.translate('sender_payment')),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.success,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              if (request.isPending)
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

// ── Create Sender Request Screen ─────────────────────────────────────────

class _CreateSenderRequestScreen extends ConsumerStatefulWidget {
  const _CreateSenderRequestScreen();

  @override
  ConsumerState<_CreateSenderRequestScreen> createState() =>
      _CreateSenderRequestScreenState();
}

class _CreateSenderRequestScreenState
    extends ConsumerState<_CreateSenderRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _organizationController = TextEditingController();
  String? _commercialRegisterPath;
  String? _documentPath;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('sender_create_title')),
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
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.infoBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.info, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.translate('sender_review_notice'),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            AppTextField(
              label: AppLocalizations.of(context)!.translate('sender_name_label'),
              hint: AppLocalizations.of(context)!.translate('sender_name_hint'),
              controller: _nameController,
              validator: (v) =>
                  Validators.validateRequired(v, fieldName: AppLocalizations.of(context)!.translate('sender_name_label')),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            AppTextField(
              label: AppLocalizations.of(context)!.translate('sender_org_label'),
              hint: AppLocalizations.of(context)!.translate('sender_org_hint'),
              controller: _organizationController,
              validator: (v) =>
                  Validators.validateRequired(v, fieldName: AppLocalizations.of(context)!.translate('sender_org_label')),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),

            // Commercial Register upload
            _buildFileUploadRow(
              label: AppLocalizations.of(context)!.translate('sender_commercial_register'),
              filePath: _commercialRegisterPath,
              onTap: () => _pickFile('commercial_register'),
            ),
            const SizedBox(height: 16),

            // Document upload
            _buildFileUploadRow(
              label: AppLocalizations.of(context)!.translate('sender_authorization_letter'),
              filePath: _documentPath,
              onTap: () => _pickFile('document'),
            ),
            const SizedBox(height: 32),

            AppButton.primary(
              text: AppLocalizations.of(context)!.translate('sender_submit'),
              onPressed: _isLoading ? null : _submit,
              isLoading: _isLoading,
              icon: Icons.send_rounded,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadRow({
    required String label,
    required String? filePath,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: filePath != null
                    ? AppColors.success
                    : AppColors.borderLight,
                style: filePath != null
                    ? BorderStyle.solid
                    : BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  filePath != null
                      ? Icons.check_circle_rounded
                      : Icons.cloud_upload_outlined,
                  color: filePath != null
                      ? AppColors.success
                      : AppColors.textHint,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    filePath != null
                        ? filePath.split('/').last
                        : AppLocalizations.of(context)!.translate('sender_upload_file'),
                    style: TextStyle(
                      fontSize: 14,
                      color: filePath != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile(String type) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      if (type == 'commercial_register') {
        _commercialRegisterPath = file.path;
      } else {
        _documentPath = file.path;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'organization_name': _organizationController.text.trim(),
      };

      final result = await ref
          .read(senderRequestsProvider.notifier)
          .create(data);

      final success = result['success'] as bool? ?? false;
      final senderId = result['data']?['id'] as int?;

      // Upload documents if available
      if (success && senderId != null) {
        if (_commercialRegisterPath != null) {
          final file = await MultipartFile.fromFile(
            _commercialRegisterPath!,
            filename: _commercialRegisterPath!.split('/').last,
          );
          await ref
              .read(senderRequestsProvider.notifier)
              .uploadCommercialRegister(senderId, file);
        }

        if (_documentPath != null) {
          final file = await MultipartFile.fromFile(
            _documentPath!,
            filename: _documentPath!.split('/').last,
          );
          await ref
              .read(senderRequestsProvider.notifier)
              .uploadDocument(senderId, file);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? AppLocalizations.of(context)!.translate('sender_submitted') : AppLocalizations.of(context)!.translate('sender_submit_failed'),
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
