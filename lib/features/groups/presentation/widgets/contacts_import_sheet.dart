import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/utils/formatters.dart';
import 'package:orbit_app/features/groups/presentation/controllers/groups_controller.dart';

/// Regex for Saudi mobile numbers (matches 05x, 5x, 966x, +966x patterns).
final _saudiPhoneRegex = RegExp(r'^(?:\+?966|0)?5[0-9]{8}$');

/// Checks if a phone number is a valid Saudi mobile number.
bool _isSaudiMobile(String phone) {
  final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  return _saudiPhoneRegex.hasMatch(cleaned);
}

/// Represents a single contact entry (one name + one phone number).
class _ContactEntry {
  final String name;
  final String phone;
  final String displayPhone;

  _ContactEntry({
    required this.name,
    required this.phone,
    required this.displayPhone,
  });
}

/// Result of expanding contacts - includes Saudi entries and skip count.
class _ExpandResult {
  final List<_ContactEntry> entries;
  final int totalPhones;
  final int skippedNonSaudi;

  _ExpandResult({
    required this.entries,
    required this.totalPhones,
    required this.skippedNonSaudi,
  });
}

/// Expands contacts into individual entries (one per Saudi phone number).
/// A contact with 3 Saudi numbers becomes 3 separate entries.
/// Also tracks how many non-Saudi numbers were skipped.
_ExpandResult _expandContacts(List<Contact> contacts) {
  final entries = <_ContactEntry>[];
  int totalPhones = 0;
  int skippedNonSaudi = 0;

  for (final contact in contacts) {
    final name = contact.displayName;
    for (final phone in contact.phones) {
      totalPhones++;
      final raw = phone.number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (_isSaudiMobile(raw)) {
        final formatted = Formatters.formatPhone(raw);
        entries.add(_ContactEntry(
          name: name,
          phone: formatted,
          displayPhone: phone.number,
        ));
      } else {
        skippedNonSaudi++;
      }
    }
  }

  return _ExpandResult(
    entries: entries,
    totalPhones: totalPhones,
    skippedNonSaudi: skippedNonSaudi,
  );
}

/// Bottom sheet that shows options to add contacts to a group.
/// Two options: add all contacts or select specific ones.
class ContactsImportSheet extends ConsumerStatefulWidget {
  const ContactsImportSheet({required this.groupId, super.key});

  final int groupId;

  @override
  ConsumerState<ContactsImportSheet> createState() =>
      _ContactsImportSheetState();
}

class _ContactsImportSheetState extends ConsumerState<ContactsImportSheet> {
  bool _isLoading = false;
  bool _isImporting = false;
  int _skippedNonSaudi = 0;
  int _saudiCount = 0;
  Map<String, dynamic>? _importResult;
  String? _error;

  @override
  void dispose() {
    // تأكد من إيقاف WakeLock إذا انغلق الشيت
    WakelockPlus.disable();
    super.dispose();
  }

  /// Builds a CSV from entries and uploads it in ONE request.
  Future<void> _uploadEntriesAsCsv(List<_ContactEntry> entries) async {
    // تفعيل WakeLock - منع السليب
    await WakelockPlus.enable();

    setState(() {
      _isImporting = true;
      _error = null;
    });

    try {
      // Get the group name for the CSV
      final state = ref.read(groupDetailControllerProvider);
      final groupName = state.group?.name ?? '';

      // Build CSV: group,name,phone
      final buffer = StringBuffer();
      buffer.writeln('group,name,phone');
      for (final entry in entries) {
        final name = entry.name.replaceAll(',', ' ');
        buffer.writeln('$groupName,$name,${entry.phone}');
      }

      // Write to temp file
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/contacts_import_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(buffer.toString());

      // Upload via custom import (one request for all contacts)
      final result = await ref
          .read(importControllerProvider.notifier)
          .importCustomForContacts(
            filePath: file.path,
            fileName: 'contacts_import.csv',
            phoneColumn: 'phone',
            groupColumn: 'group',
            nameColumn: 'name',
          );

      if (mounted) {
        setState(() {
          _isImporting = false;
          _importResult = result;
        });
      }

      // Clean up temp file
      try { await file.delete(); } catch (_) {}
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _error = 'خطأ في رفع جهات الاتصال: $e';
        });
      }
    } finally {
      // إيقاف WakeLock
      await WakelockPlus.disable();
    }
  }

  Future<void> _importAllContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final permGranted = await FlutterContacts.requestPermission(readonly: true);
      if (!permGranted) {
        setState(() {
          _isLoading = false;
          _error = 'يجب السماح بالوصول إلى جهات الاتصال';
        });
        return;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      final expandResult = _expandContacts(contacts);

      if (expandResult.entries.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'لا توجد أرقام جوال سعودية في جهات الاتصال';
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _skippedNonSaudi = expandResult.skippedNonSaudi;
        _saudiCount = expandResult.entries.length;
      });

      await _uploadEntriesAsCsv(expandResult.entries);
    } catch (e) {
      await WakelockPlus.disable();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isImporting = false;
          _error = 'خطأ في قراءة جهات الاتصال: $e';
        });
      }
    }
  }

  Future<void> _importSelectedContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final permGranted = await FlutterContacts.requestPermission(readonly: true);
      if (!permGranted) {
        setState(() {
          _isLoading = false;
          _error = 'يجب السماح بالوصول إلى جهات الاتصال';
        });
        return;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      final expandResult = _expandContacts(contacts);

      if (expandResult.entries.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'لا توجد أرقام جوال سعودية في جهات الاتصال';
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _skippedNonSaudi = expandResult.skippedNonSaudi;
      });

      if (!mounted) return;

      final selected = await showDialog<List<_ContactEntry>>(
        context: context,
        builder: (context) => _ContactEntryPickerDialog(
          entries: expandResult.entries,
          skippedNonSaudi: expandResult.skippedNonSaudi,
        ),
      );

      if (selected == null || selected.isEmpty || !mounted) return;

      setState(() => _saudiCount = selected.length);

      await _uploadEntriesAsCsv(selected);
    } catch (e) {
      await WakelockPlus.disable();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isImporting = false;
          _error = 'خطأ في قراءة جهات الاتصال: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 24 + bottomPadding,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'إضافة من جهات الاتصال',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.infoBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'سيتم إضافة أرقام الجوال السعودية فقط بجميع صيغها (05xx, +966xx, 966xx)',
                    style: TextStyle(fontSize: 12, color: AppColors.infoDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Content based on state
          if (_importResult != null)
            _buildResult()
          else if (_isImporting)
            _buildUploading()
          else if (_error != null)
            _buildError()
          else if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else ...[
            // Option 1: Import all
            _buildOptionTile(
              icon: Icons.contacts,
              title: 'إضافة جميع جهات الاتصال',
              subtitle: 'سحب كل أرقام الجوال السعودية من جهازك',
              onTap: _importAllContacts,
            ),
            const SizedBox(height: 12),
            // Option 2: Select specific
            _buildOptionTile(
              icon: Icons.person_search,
              title: 'اختيار جهات اتصال محددة',
              subtitle: 'اختر الأرقام التي تريد إضافتها',
              onTap: _importSelectedContacts,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploading() {
    final importState = ref.watch(importControllerProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const Text(
            'جاري رفع جهات الاتصال...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_saudiCount رقم سعودي',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: importState.progress > 0 ? importState.progress : null,
              backgroundColor: AppColors.borderLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
          if (importState.progress > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${(importState.progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'لا تغلق التطبيق',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final result = _importResult!;
    final successCount = result['success_count'] ?? result['imported'] ?? 0;
    final failedCount = result['failed_count'] ?? result['failed'] ?? 0;
    final message = result['message'] as String? ?? '';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.successSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.successBorder),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'اكتملت الإضافة',
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
                  style: const TextStyle(fontSize: 13, color: AppColors.successDark),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (successCount is int && successCount > 0)
                    _buildStatChip(
                        'تمت إضافته', successCount.toString(), AppColors.success),
                  if (_skippedNonSaudi > 0) ...[
                    const SizedBox(width: 8),
                    _buildStatChip(
                        'غير سعودي', _skippedNonSaudi.toString(), AppColors.textSecondary),
                  ],
                ],
              ),
              if (failedCount is int && failedCount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatChip(
                        'موجود بالفعل', failedCount.toString(), AppColors.info),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'تم',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
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

  Widget _buildError() {
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
              _error!,
              style: const TextStyle(fontSize: 14, color: AppColors.errorDark),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTACT ENTRY PICKER DIALOG (shows each phone number as separate entry)
// ═══════════════════════════════════════════════════════════════════════════

class _ContactEntryPickerDialog extends StatefulWidget {
  const _ContactEntryPickerDialog({
    required this.entries,
    this.skippedNonSaudi = 0,
  });

  final List<_ContactEntry> entries;
  final int skippedNonSaudi;

  @override
  State<_ContactEntryPickerDialog> createState() =>
      _ContactEntryPickerDialogState();
}

class _ContactEntryPickerDialogState
    extends State<_ContactEntryPickerDialog> {
  late final List<_ContactEntry> _entries;
  String _searchQuery = '';
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _entries = widget.entries;
  }

  List<MapEntry<int, _ContactEntry>> get _filteredEntries {
    final indexed = _entries.asMap().entries.toList();
    if (_searchQuery.isEmpty) return indexed;
    final query = _searchQuery.toLowerCase();
    return indexed.where((e) {
      return e.value.name.toLowerCase().contains(query) ||
          e.value.displayPhone.contains(query) ||
          e.value.phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEntries;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'اختر الأرقام',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedIndices.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
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
                  hintText: 'بحث بالاسم أو الرقم...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
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
                        _selectedIndices
                            .addAll(filtered.map((e) => e.key));
                      });
                    },
                    child: const Text(
                      'تحديد الكل',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        for (final e in filtered) {
                          _selectedIndices.remove(e.key);
                        }
                      });
                    },
                    child: const Text(
                      'إلغاء الكل',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_entries.length} رقم سعودي',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (widget.skippedNonSaudi > 0)
                        Text(
                          '${widget.skippedNonSaudi} غير سعودي (تم تجاوزه)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Entries list
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final entry = filtered[index];
                  final isSelected = _selectedIndices.contains(entry.key);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedIndices.add(entry.key);
                        } else {
                          _selectedIndices.remove(entry.key);
                        }
                      });
                    },
                    title: Text(
                      entry.value.name.isNotEmpty ? entry.value.name : 'بدون اسم',
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      entry.value.displayPhone,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    secondary: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        entry.value.name.isNotEmpty
                            ? entry.value.name[0].toUpperCase()
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
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedIndices.isEmpty
                          ? null
                          : () {
                              final selected = _selectedIndices
                                  .map((i) => _entries[i])
                                  .toList();
                              Navigator.pop(context, selected);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'إضافة (${_selectedIndices.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
