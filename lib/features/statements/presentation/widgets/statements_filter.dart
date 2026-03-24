import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/statements/data/models/statement_response_model.dart';
import 'package:orbit_app/features/statements/presentation/controllers/statements_controller.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';

/// Bottom sheet with filter controls for the statements list.
///
/// Allows the user to set date range, name, sender, group, and Hijri date
/// filters. Tapping "Apply" updates [statementsFilterProvider] and closes
/// the sheet. Tapping "Reset" clears all filters.
class StatementsFilterSheet extends ConsumerStatefulWidget {
  const StatementsFilterSheet({super.key});

  /// Opens the filter sheet as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const StatementsFilterSheet(),
    );
  }

  @override
  ConsumerState<StatementsFilterSheet> createState() => _StatementsFilterSheetState();
}

class _StatementsFilterSheetState extends ConsumerState<StatementsFilterSheet> {
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _useHijriDate = false;
  late TextEditingController _searchController;
  late TextEditingController _nameController;
  late TextEditingController _senderNameController;

  @override
  void initState() {
    super.initState();
    final currentFilter = ref.read(statementsFilterProvider);
    _fromDate = currentFilter.fromDate;
    _toDate = currentFilter.toDate;
    _useHijriDate = currentFilter.useHijriDate;
    _searchController =
        TextEditingController(text: currentFilter.searchQuery ?? '');
    _nameController =
        TextEditingController(text: currentFilter.name ?? '');
    _senderNameController =
        TextEditingController(text: currentFilter.senderName ?? '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _senderNameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom ? (_fromDate ?? now) : (_toDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  void _applyFilters() {
    final search = _searchController.text.trim();
    final name = _nameController.text.trim();
    final senderName = _senderNameController.text.trim();
    ref.read(statementsFilterProvider.notifier).state = StatementFilter(
      searchQuery: search.isEmpty ? null : search,
      name: name.isEmpty ? null : name,
      senderName: senderName.isEmpty ? null : senderName,
      fromDate: _fromDate,
      toDate: _toDate,
      useHijriDate: _useHijriDate,
    );
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _useHijriDate = false;
      _searchController.clear();
      _nameController.clear();
      _senderNameController.clear();
    });
    ref.read(statementsFilterProvider.notifier).state = const StatementFilter();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ───────────────────────────────────────
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

              // ── Title ─────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.filter_list_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.translate('statement_filter_title'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 20),

              // ── General Search ─────────────────────────────────────
              Text(
                AppLocalizations.of(context)!.translate('statement_general_search'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _searchController,
                hintText: AppLocalizations.of(context)!.translate('statement_search_text_hint'),
                icon: Icons.search,
              ),
              const SizedBox(height: 16),

              // ── Name ───────────────────────────────────────────────
              Text(
                AppLocalizations.of(context)!.translate('statement_name_label'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _nameController,
                hintText: AppLocalizations.of(context)!.translate('statement_enter_name'),
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              // ── Sender Name ────────────────────────────────────────
              Text(
                AppLocalizations.of(context)!.translate('statement_sender_name'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _senderNameController,
                hintText: AppLocalizations.of(context)!.translate('statement_enter_sender_name'),
                icon: Icons.account_circle_outlined,
              ),
              const SizedBox(height: 16),

              // ── Hijri Date Checkbox ─────────────────────────────────
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _useHijriDate,
                      onChanged: (value) =>
                          setState(() => _useHijriDate = value ?? false),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(
                        color: AppColors.borderDark,
                        width: 1.5,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.translate('hijriDate'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Date Range ────────────────────────────────────────
              Text(
                AppLocalizations.of(context)!.translate('statement_date_range'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // From date
                  Expanded(
                    child: _DatePickerButton(
                      label: AppLocalizations.of(context)!.translate('statement_from_date'),
                      value: _fromDate != null
                          ? dateFormat.format(_fromDate!)
                          : null,
                      onTap: () => _pickDate(isFrom: true),
                      onClear: _fromDate != null
                          ? () => setState(() => _fromDate = null)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // To date
                  Expanded(
                    child: _DatePickerButton(
                      label: AppLocalizations.of(context)!.translate('statement_to_date'),
                      value: _toDate != null
                          ? dateFormat.format(_toDate!)
                          : null,
                      onTap: () => _pickDate(isFrom: false),
                      onClear: _toDate != null
                          ? () => setState(() => _toDate = null)
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Action Buttons ────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      text: AppLocalizations.of(context)!.translate('reset'),
                      onPressed: _resetFilters,
                      icon: Icons.refresh_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton.primary(
                      text: AppLocalizations.of(context)!.translate('apply'),
                      onPressed: _applyFilters,
                      icon: Icons.check_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.inputHint,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.textHint,
          size: 20,
        ),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date Picker Button
// ─────────────────────────────────────────────────────────────────────────────

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({
    required this.label,
    required this.onTap,
    this.value,
    this.onClear,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.textHint,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? '---',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textHint,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
