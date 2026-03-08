import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/groups/presentation/controllers/groups_controller.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// Screen for importing phone numbers from Excel files.
///
/// Provides two tabs:
/// - **Standard Import**: Upload an Excel file directly (max 5000 rows)
/// - **Custom Import**: Upload with column mapping (phone, name, identifier)
class ImportNumbersScreen extends ConsumerStatefulWidget {
  const ImportNumbersScreen({super.key});

  @override
  ConsumerState<ImportNumbersScreen> createState() =>
      _ImportNumbersScreenState();
}

class _ImportNumbersScreenState extends ConsumerState<ImportNumbersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // File state
  String? _filePath;
  String? _fileName;

  // Custom import fields
  final _phoneColumnController = TextEditingController(text: 'A');
  final _nameColumnController = TextEditingController();
  final _identifierColumnController = TextEditingController();
  final _groupNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneColumnController.dispose();
    _nameColumnController.dispose();
    _identifierColumnController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _filePath = result.files.single.path!;
        _fileName = result.files.single.name;
      });

      // Reset import state when a new file is picked.
      ref.read(importControllerProvider.notifier).reset();
    }
  }

  Future<void> _startStandardImport() async {
    if (_filePath == null || _fileName == null) return;

    await ref.read(importControllerProvider.notifier).importStandard(
          filePath: _filePath!,
          fileName: _fileName!,
        );
  }

  Future<void> _startCustomImport() async {
    if (_filePath == null || _fileName == null) return;

    final phoneColumn = _phoneColumnController.text.trim();
    final groupColumn = _groupNameController.text.trim();

    if (phoneColumn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('\u0639\u0645\u0648\u062F \u0631\u0642\u0645 \u0627\u0644\u0647\u0627\u062A\u0641 \u0645\u0637\u0644\u0648\u0628'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (groupColumn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('\u0639\u0645\u0648\u062F \u0627\u0644\u0645\u062C\u0645\u0648\u0639\u0629 \u0645\u0637\u0644\u0648\u0628'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await ref.read(importControllerProvider.notifier).importCustom(
          filePath: _filePath!,
          fileName: _fileName!,
          phoneColumn: phoneColumn,
          groupColumn: groupColumn,
          nameColumn: _nameColumnController.text.trim().isNotEmpty
              ? _nameColumnController.text.trim()
              : null,
          identifierColumn:
              _identifierColumnController.text.trim().isNotEmpty
                  ? _identifierColumnController.text.trim()
                  : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(importControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          '\u0627\u0633\u062A\u064A\u0631\u0627\u062F \u0623\u0631\u0642\u0627\u0645',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: '\u0627\u0633\u062A\u064A\u0631\u0627\u062F \u0639\u0627\u062F\u064A'),
            Tab(text: '\u0627\u0633\u062A\u064A\u0631\u0627\u062F \u0645\u062E\u0635\u0635'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Standard import tab
          _buildStandardTab(importState),

          // Custom import tab
          _buildCustomTab(importState),
        ],
      ),
    );
  }

  Widget _buildStandardTab(ImportState importState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.infoSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.infoBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '\u0627\u0644\u062D\u062F \u0627\u0644\u0623\u0642\u0635\u0649 5000 \u0633\u0637\u0631. \u0627\u0644\u0645\u0644\u0641 \u064A\u062C\u0628 \u0623\u0646 \u064A\u062D\u062A\u0648\u064A \u0639\u0644\u0649 \u0623\u0639\u0645\u062F\u0629: \u0627\u0644\u0627\u0633\u0645\u060C \u0631\u0642\u0645 \u0627\u0644\u0647\u0627\u062A\u0641',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.infoDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // File picker area
          _buildFilePicker(),
          const SizedBox(height: 24),

          // Upload button
          if (_filePath != null && !importState.isComplete)
            AppButton.primary(
              text: '\u0631\u0641\u0639 \u0627\u0644\u0645\u0644\u0641',
              onPressed: importState.isUploading ? null : _startStandardImport,
              isLoading: importState.isUploading,
              icon: Icons.cloud_upload_outlined,
            ),

          // Progress
          if (importState.isUploading) ...[
            const SizedBox(height: 16),
            _buildProgressIndicator(importState.progress),
          ],

          // Result
          if (importState.isComplete) ...[
            const SizedBox(height: 16),
            _buildResultCard(importState.result!),
          ],

          // Error
          if (importState.error != null) ...[
            const SizedBox(height: 16),
            _buildErrorCard(importState.error!),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomTab(ImportState importState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.infoSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.infoBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '\u062D\u062F\u062F \u0623\u0639\u0645\u062F\u0629 \u0627\u0644\u0645\u0644\u0641 \u0644\u0631\u0628\u0637\u0647\u0627 \u0628\u0627\u0644\u062D\u0642\u0648\u0644 \u0627\u0644\u0645\u0637\u0644\u0648\u0628\u0629',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.infoDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // File picker area
          _buildFilePicker(),
          const SizedBox(height: 24),

          // Column mapping fields
          AppTextField(
            label: '\u0639\u0645\u0648\u062F \u0631\u0642\u0645 \u0627\u0644\u0647\u0627\u062A\u0641 *',
            hint: '\u0645\u062B\u0627\u0644: A \u0623\u0648 phone',
            controller: _phoneColumnController,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          AppTextField(
            label: '\u0639\u0645\u0648\u062F \u0627\u0644\u0627\u0633\u0645 (\u0627\u062E\u062A\u064A\u0627\u0631\u064A)',
            hint: '\u0645\u062B\u0627\u0644: B \u0623\u0648 name',
            controller: _nameColumnController,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          AppTextField(
            label: '\u0639\u0645\u0648\u062F \u0627\u0644\u0645\u0639\u0631\u0641 (\u0627\u062E\u062A\u064A\u0627\u0631\u064A)',
            hint: '\u0645\u062B\u0627\u0644: C \u0623\u0648 identifier',
            controller: _identifierColumnController,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          AppTextField(
            label: '\u0639\u0645\u0648\u062F \u0627\u0644\u0645\u062C\u0645\u0648\u0639\u0629 *',
            hint: '\u0645\u062B\u0627\u0644: D \u0623\u0648 group',
            controller: _groupNameController,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),

          // Upload button
          if (_filePath != null && !importState.isComplete)
            AppButton.primary(
              text: '\u0631\u0641\u0639 \u0627\u0644\u0645\u0644\u0641',
              onPressed: importState.isUploading ? null : _startCustomImport,
              isLoading: importState.isUploading,
              icon: Icons.cloud_upload_outlined,
            ),

          // Progress
          if (importState.isUploading) ...[
            const SizedBox(height: 16),
            _buildProgressIndicator(importState.progress),
          ],

          // Result
          if (importState.isComplete) ...[
            const SizedBox(height: 16),
            _buildResultCard(importState.result!),
          ],

          // Error
          if (importState.error != null) ...[
            const SizedBox(height: 16),
            _buildErrorCard(importState.error!),
          ],
        ],
      ),
    );
  }

  Widget _buildFilePicker() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _filePath != null ? AppColors.primaryBorder : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _filePath != null
                  ? Icons.insert_drive_file_outlined
                  : Icons.cloud_upload_outlined,
              size: 48,
              color: _filePath != null ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              _fileName ?? '\u0627\u0636\u063A\u0637 \u0644\u0627\u062E\u062A\u064A\u0627\u0631 \u0645\u0644\u0641 Excel',
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    _filePath != null ? FontWeight.w600 : FontWeight.w400,
                color: _filePath != null
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\u0627\u0644\u0635\u064A\u063A \u0627\u0644\u0645\u062F\u0639\u0648\u0645\u0629: xlsx, xls, csv',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(double progress) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.borderLight,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(progress * 100).toInt()}%',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final successCount = result['success_count'] ?? result['imported'] ?? 0;
    final failedCount = result['failed_count'] ?? result['failed'] ?? 0;
    final totalCount = result['total'] ?? (successCount + failedCount);
    final message = result['message'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.successBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 24),
              const SizedBox(width: 8),
              const Text(
                '\u0627\u0643\u062A\u0645\u0644 \u0627\u0644\u0627\u0633\u062A\u064A\u0631\u0627\u062F',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.successDark,
                ),
              ),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 13, color: AppColors.successDark),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip(
                '\u0627\u0644\u0625\u062C\u0645\u0627\u0644\u064A',
                totalCount.toString(),
                AppColors.info,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                '\u0646\u0627\u062C\u062D',
                successCount.toString(),
                AppColors.success,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                '\u0641\u0627\u0634\u0644',
                failedCount.toString(),
                AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: AppButton.secondary(
              text: '\u0631\u0641\u0639 \u0645\u0644\u0641 \u0622\u062E\u0631',
              onPressed: () {
                ref.read(importControllerProvider.notifier).reset();
                setState(() {
                  _filePath = null;
                  _fileName = null;
                });
              },
              icon: Icons.upload_file,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.errorDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
