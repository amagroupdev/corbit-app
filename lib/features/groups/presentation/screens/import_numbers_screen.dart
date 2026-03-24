import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/groups/presentation/controllers/groups_controller.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// Screen for importing phone numbers from Excel files or device contacts.
///
/// Provides three tabs:
/// - **Standard Import**: Upload an Excel file directly (max 5000 rows)
/// - **Custom Import**: Upload with column mapping (phone, name, identifier)
/// - **Contacts Import**: Pick contacts from device
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

  // Contacts state
  List<Contact> _selectedContacts = [];
  bool _isLoadingContacts = false;

  // Custom import fields
  final _phoneColumnController = TextEditingController(text: 'A');
  final _nameColumnController = TextEditingController();
  final _identifierColumnController = TextEditingController();
  final _groupNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    final t = AppLocalizations.of(context)!;

    if (phoneColumn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.translate('phoneColumnRequired')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (groupColumn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.translate('groupColumnRequired')),
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

  Future<void> _pickContacts() async {
    setState(() => _isLoadingContacts = true);
    final t = AppLocalizations.of(context)!;

    try {
      // Request permission
      final permGranted = await FlutterContacts.requestPermission();
      if (!permGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.translate('contactsPermissionRequired')),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() => _isLoadingContacts = false);
        return;
      }

      // Get all contacts with phone numbers
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      // Filter contacts that have at least one phone number
      final contactsWithPhones =
          contacts.where((c) => c.phones.isNotEmpty).toList();

      if (!mounted) return;

      // Show multi-select dialog
      final selected = await showDialog<List<Contact>>(
        context: context,
        builder: (context) => _ContactPickerDialog(
          contacts: contactsWithPhones,
          initialSelection: _selectedContacts,
        ),
      );

      if (selected != null) {
        setState(() => _selectedContacts = selected);
        // Reset import state when contacts change
        ref.read(importControllerProvider.notifier).reset();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.translate('contactsReadError')}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isLoadingContacts = false);
  }

  Future<void> _startContactsImport() async {
    if (_selectedContacts.isEmpty) return;
    final t = AppLocalizations.of(context)!;

    // Create a CSV file from selected contacts
    final buffer = StringBuffer();
    buffer.writeln('name,phone');
    for (final contact in _selectedContacts) {
      final name = (contact.displayName ?? '').replaceAll(',', ' ');
      final phone = contact.phones.first.number
          .replaceAll(' ', '')
          .replaceAll('-', '')
          .replaceAll('(', '')
          .replaceAll(')', '');
      buffer.writeln('$name,$phone');
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/contacts_import.csv');
      await file.writeAsString(buffer.toString());

      await ref.read(importControllerProvider.notifier).importStandard(
            filePath: file.path,
            fileName: 'contacts_import.csv',
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.translate('importFileError')}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(importControllerProvider);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          t.translate('importNumbers'),
          style: const TextStyle(fontWeight: FontWeight.w700),
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: t.translate('standardImport')),
            Tab(text: t.translate('customImport')),
            Tab(text: t.translate('contactsTab')),
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

          // Contacts import tab
          _buildContactsTab(importState),
        ],
      ),
    );
  }

  Widget _buildStandardTab(ImportState importState) {
    final t = AppLocalizations.of(context)!;
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
                    t.translate('standardImportInfo'),
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
              text: t.translate('uploadFileButton'),
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
    final t = AppLocalizations.of(context)!;
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
                    t.translate('customImportInfo'),
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
            label: t.translate('phoneColumnLabel'),
            hint: t.translate('phoneColumnHint'),
            controller: _phoneColumnController,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          AppTextField(
            label: t.translate('nameColumnLabel'),
            hint: t.translate('nameColumnHint'),
            controller: _nameColumnController,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          AppTextField(
            label: t.translate('identifierColumnLabel'),
            hint: t.translate('identifierColumnHint'),
            controller: _identifierColumnController,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          AppTextField(
            label: t.translate('groupColumnLabel'),
            hint: t.translate('groupColumnHint'),
            controller: _groupNameController,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),

          // Upload button
          if (_filePath != null && !importState.isComplete)
            AppButton.primary(
              text: t.translate('uploadFileButton'),
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

  Widget _buildContactsTab(ImportState importState) {
    final t = AppLocalizations.of(context)!;
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
                    t.translate('contactsImportInfo'),
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

          // Pick contacts button
          GestureDetector(
            onTap: _isLoadingContacts ? null : _pickContacts,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedContacts.isNotEmpty
                      ? AppColors.primaryBorder
                      : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  if (_isLoadingContacts)
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  else
                    Icon(
                      _selectedContacts.isNotEmpty
                          ? Icons.contacts
                          : Icons.contact_phone_outlined,
                      size: 48,
                      color: _selectedContacts.isNotEmpty
                          ? AppColors.primary
                          : AppColors.textHint,
                    ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedContacts.isNotEmpty
                        ? t.translateWithParams('selectedContactsCount', {'count': '${_selectedContacts.length}'})
                        : t.translate('tapToSelectContacts'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: _selectedContacts.isNotEmpty
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: _selectedContacts.isNotEmpty
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (_selectedContacts.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      t.translate('tapToEditSelection'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Show selected contacts summary
          if (_selectedContacts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _selectedContacts.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final contact = _selectedContacts[index];
                  final phone = contact.phones.isNotEmpty
                      ? contact.phones.first.number
                      : '';
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        (contact.displayName ?? '').isNotEmpty
                            ? (contact.displayName ?? '')[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    title: Text(
                      contact.displayName ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      phone,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() {
                          _selectedContacts.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Import button
          if (_selectedContacts.isNotEmpty && !importState.isComplete)
            AppButton.primary(
              text: t.translateWithParams('importContactsCount', {'count': '${_selectedContacts.length}'}),
              onPressed: importState.isUploading ? null : _startContactsImport,
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
    final t = AppLocalizations.of(context)!;
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
              _fileName ?? t.translate('tapToSelectExcel'),
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
              t.translate('supportedFormats'),
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
    final t = AppLocalizations.of(context)!;
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
              Text(
                t.translate('importCompleted'),
                style: const TextStyle(
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
                t.translate('total'),
                totalCount.toString(),
                AppColors.info,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                t.translate('importSuccessful'),
                successCount.toString(),
                AppColors.success,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                t.translate('importFailed'),
                failedCount.toString(),
                AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: AppButton.secondary(
              text: t.translate('importAnother'),
              onPressed: () {
                ref.read(importControllerProvider.notifier).reset();
                setState(() {
                  _filePath = null;
                  _fileName = null;
                  _selectedContacts = [];
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

// ═══════════════════════════════════════════════════════════════════════════
// CONTACT PICKER DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class _ContactPickerDialog extends StatefulWidget {
  const _ContactPickerDialog({
    required this.contacts,
    required this.initialSelection,
  });

  final List<Contact> contacts;
  final List<Contact> initialSelection;

  @override
  State<_ContactPickerDialog> createState() => _ContactPickerDialogState();
}

class _ContactPickerDialogState extends State<_ContactPickerDialog> {
  late final Set<String> _selectedIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.initialSelection
        .map((c) => c.id ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  List<Contact> get _filteredContacts {
    if (_searchQuery.isEmpty) return widget.contacts;
    final query = _searchQuery.toLowerCase();
    return widget.contacts.where((c) {
      final name = (c.displayName ?? '').toLowerCase();
      final phone =
          c.phones.isNotEmpty ? c.phones.first.number : '';
      return name.contains(query) || phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredContacts;
    final t = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.translate('selectContactsTitle'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${_selectedIds.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: t.translate('searchHint'),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            const SizedBox(height: 8),

            // Select all / deselect all
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedIds.addAll(
                          filtered.map((c) => c.id ?? '').where((id) => id.isNotEmpty),
                        );
                      });
                    },
                    child: Text(
                      t.translate('selectAll'),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        for (final c in filtered) {
                          _selectedIds.remove(c.id ?? '');
                        }
                      });
                    },
                    child: Text(
                      t.translate('deselectAllFiltered'),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            // Contact list
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final contact = filtered[index];
                  final contactId = contact.id ?? '';
                  final isSelected = _selectedIds.contains(contactId);
                  final phone = contact.phones.isNotEmpty
                      ? contact.phones.first.number
                      : '';

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          if (contactId.isNotEmpty) _selectedIds.add(contactId);
                        } else {
                          _selectedIds.remove(contactId);
                        }
                      });
                    },
                    title: Text(
                      contact.displayName ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      phone,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    secondary: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        (contact.displayName ?? '').isNotEmpty
                            ? (contact.displayName ?? '')[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.trailing,
                    dense: true,
                    activeColor: AppColors.primary,
                  );
                },
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(t.translate('cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final selected = widget.contacts
                            .where((c) => _selectedIds.contains(c.id ?? ''))
                            .toList();
                        Navigator.pop(context, selected);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        t.translateWithParams('confirmCount', {'count': '${_selectedIds.length}'}),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
