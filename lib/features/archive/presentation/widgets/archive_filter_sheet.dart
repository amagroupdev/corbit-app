import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/archive/data/models/archive_model.dart';
import 'package:orbit_app/features/archive/presentation/controllers/archive_controller.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';

/// Bottom sheet with filter controls for the archive list.
///
/// Allows the user to set date range, send type, and phone number filters.
/// Tapping "Apply" updates [archiveFilterProvider] and closes the sheet.
/// Tapping "Reset" clears all filters.
class ArchiveFilterSheet extends ConsumerStatefulWidget {
  const ArchiveFilterSheet({super.key});

  /// Opens the filter sheet as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ArchiveFilterSheet(),
    );
  }

  @override
  ConsumerState<ArchiveFilterSheet> createState() => _ArchiveFilterSheetState();
}

class _ArchiveFilterSheetState extends ConsumerState<ArchiveFilterSheet> {
  late SendAtFilter _sendAt;
  DateTime? _fromDate;
  DateTime? _toDate;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final currentFilter = ref.read(archiveFilterProvider);
    _sendAt = currentFilter.sendAt ?? SendAtFilter.all;
    _fromDate = currentFilter.fromDate;
    _toDate = currentFilter.toDate;
    _phoneController =
        TextEditingController(text: currentFilter.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
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
    final phone = _phoneController.text.trim();
    ref.read(archiveFilterProvider.notifier).state = ArchiveFilter(
      sendAt: _sendAt == SendAtFilter.all ? null : _sendAt,
      fromDate: _fromDate,
      toDate: _toDate,
      phoneNumber: phone.isEmpty ? null : phone,
    );
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    setState(() {
      _sendAt = SendAtFilter.all;
      _fromDate = null;
      _toDate = null;
      _phoneController.clear();
    });
    ref.read(archiveFilterProvider.notifier).state = const ArchiveFilter();
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
              const Row(
                children: [
                  Icon(Icons.filter_list_rounded,
                      color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    '\u062A\u0635\u0641\u064A\u0629 \u0627\u0644\u0623\u0631\u0634\u064A\u0641', // تصفية الأرشيف
                    style: TextStyle(
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

              // ── Send Type Filter ──────────────────────────────────
              const Text(
                '\u0646\u0648\u0639 \u0627\u0644\u0625\u0631\u0633\u0627\u0644', // نوع الإرسال
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SendAtFilter.values.map((filter) {
                  final isActive = _sendAt == filter;
                  return ChoiceChip(
                    label: Text(filter.labelAr),
                    selected: isActive,
                    onSelected: (_) => setState(() => _sendAt = filter),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceVariant,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isActive ? Colors.white : AppColors.textPrimary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    showCheckmark: false,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Date Range ────────────────────────────────────────
              const Text(
                '\u0627\u0644\u0641\u062A\u0631\u0629 \u0627\u0644\u0632\u0645\u0646\u064A\u0629', // الفترة الزمنية
                style: TextStyle(
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
                      label: '\u0645\u0646', // من
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
                      label: '\u0625\u0644\u0649', // إلى
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
              const SizedBox(height: 20),

              // ── Phone Number ──────────────────────────────────────
              const Text(
                '\u0631\u0642\u0645 \u0627\u0644\u0647\u0627\u062A\u0641', // رقم الهاتف
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: '\u0623\u062F\u062E\u0644 \u0631\u0642\u0645 \u0627\u0644\u0647\u0627\u062A\u0641', // أدخل رقم الهاتف
                  hintStyle: const TextStyle(
                    color: AppColors.inputHint,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
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
              ),
              const SizedBox(height: 28),

              // ── Action Buttons ────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      text: '\u0625\u0639\u0627\u062F\u0629 \u0636\u0628\u0637', // إعادة ضبط
                      onPressed: _resetFilters,
                      icon: Icons.refresh_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton.primary(
                      text: '\u062A\u0637\u0628\u064A\u0642', // تطبيق
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
