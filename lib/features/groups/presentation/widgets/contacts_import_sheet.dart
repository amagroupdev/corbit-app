import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
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
  int _importProgress = 0;
  int _importTotal = 0;
  int _skippedNonSaudi = 0;
  Map<String, int>? _importResult;
  String? _error;

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  /// Sends entries one by one via API with WakeLock to prevent sleep.
  Future<void> _sendEntriesToApi(List<_ContactEntry> entries) async {
    await WakelockPlus.enable();

    setState(() {
      _isImporting = true;
      _importTotal = entries.length;
      _importProgress = 0;
      _error = null;
    });

    try {
      final contactMaps = entries
          .map((e) => {'name': e.name, 'number': e.phone})
          .toList();

      final result = await ref
          .read(groupDetailControllerProvider.notifier)
          .addNumbersBatch(
            groupId: widget.groupId,
            contacts: contactMaps,
            onProgress: (current, total) {
              if (mounted) {
                setState(() => _importProgress = current);
              }
            },
          );

      if (mounted) {
        setState(() {
          _isImporting = false;
          _importResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        setState(() {
          _isImporting = false;
          _error = '${t.translate('contactsAddError')}: $e';
        });
      }
    } finally {
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
        final t = AppLocalizations.of(context)!;
        setState(() {
          _isLoading = false;
          _error = t.translate('contactsPermissionRequired');
        });
        return;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      final expandResult = _expandContacts(contacts);

      if (expandResult.entries.isEmpty) {
        final t = AppLocalizations.of(context)!;
        setState(() {
          _isLoading = false;
          _error = t.translate('noSaudiNumbers');
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _skippedNonSaudi = expandResult.skippedNonSaudi;
      });

      await _sendEntriesToApi(expandResult.entries);
    } catch (e) {
      await WakelockPlus.disable();
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        setState(() {
          _isLoading = false;
          _isImporting = false;
          _error = '${t.translate('contactsReadError')}: $e';
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
        final t = AppLocalizations.of(context)!;
        setState(() {
          _isLoading = false;
          _error = t.translate('contactsPermissionRequired');
        });
        return;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      final expandResult = _expandContacts(contacts);

      if (expandResult.entries.isEmpty) {
        final t = AppLocalizations.of(context)!;
        setState(() {
          _isLoading = false;
          _error = t.translate('noSaudiNumbers');
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

      await _sendEntriesToApi(selected);
    } catch (e) {
      await WakelockPlus.disable();
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        setState(() {
          _isLoading = false;
          _isImporting = false;
          _error = '${t.translate('contactsReadError')}: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final t = AppLocalizations.of(context)!;

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
          Text(
            t.translate('addFromContactsTitle'),
            style: const TextStyle(
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
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t.translate('saudiNumbersOnlyInfo'),
                    style: const TextStyle(fontSize: 12, color: AppColors.infoDark),
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
              title: t.translate('importAllContacts'),
              subtitle: t.translate('importAllContactsSubtitle'),
              onTap: _importAllContacts,
            ),
            const SizedBox(height: 12),
            // Option 2: Select specific
            _buildOptionTile(
              icon: Icons.person_search,
              title: t.translate('selectSpecificContacts'),
              subtitle: t.translate('selectSpecificContactsSubtitle'),
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
    final progress = _importTotal > 0 ? _importProgress / _importTotal : 0.0;
    final t = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            t.translate('addingContacts'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
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
            '$_importProgress / $_importTotal',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.translate('screenWontSleep'),
            style: const TextStyle(
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
    final success = result['success'] ?? 0;
    final failed = result['failed'] ?? 0;
    final duplicate = result['duplicate'] ?? 0;
    final t = AppLocalizations.of(context)!;

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
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    t.translate('additionCompleted'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.successDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatChip(
                      t.translate('addedSuccessfully'), success.toString(), AppColors.success),
                  if (_skippedNonSaudi > 0) ...[
                    const SizedBox(width: 8),
                    _buildStatChip(
                        t.translate('nonSaudi'), _skippedNonSaudi.toString(), AppColors.textSecondary),
                  ],
                ],
              ),
              if (duplicate > 0 || failed > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (duplicate > 0)
                      _buildStatChip(
                          t.translate('alreadyExists'), duplicate.toString(), AppColors.info),
                    if (duplicate > 0 && failed > 0)
                      const SizedBox(width: 8),
                    if (failed > 0)
                      _buildStatChip(
                          t.translate('error'), failed.toString(), AppColors.error),
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
            child: Text(
              t.translate('done'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
    final t = AppLocalizations.of(context)!;

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
                  Expanded(
                    child: Text(
                      t.translate('selectNumbers'),
                      style: const TextStyle(
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
                  hintText: t.translate('searchByNameOrNumber'),
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
                    child: Text(
                      t.translate('selectAll'),
                      style: const TextStyle(fontSize: 13),
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
                    child: Text(
                      t.translate('deselectAllFiltered'),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        t.translateWithParams('saudiNumberCount', {'count': '${_entries.length}'}),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (widget.skippedNonSaudi > 0)
                        Text(
                          t.translateWithParams('nonSaudiSkipped', {'count': '${widget.skippedNonSaudi}'}),
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
                      entry.value.name.isNotEmpty ? entry.value.name : t.translate('noName'),
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
                      child: Text(t.translate('cancel')),
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
                        t.translateWithParams('addCount', {'count': '${_selectedIndices.length}'}),
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
