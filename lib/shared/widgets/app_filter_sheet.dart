import 'package:flutter/material.dart';
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';

/// Generic filter model that holds the current state of all filters.
///
/// Extend or adapt this class for feature-specific filters.
class FilterModel {
  const FilterModel({
    this.selectedChips = const {},
    this.dateRange,
    this.dropdownValues = const {},
  });

  /// Set of selected chip keys (e.g. {"sent", "delivered"}).
  final Set<String> selectedChips;

  /// Optional date range filter.
  final DateTimeRange? dateRange;

  /// Key-value pairs for dropdown selections.
  final Map<String, String?> dropdownValues;

  FilterModel copyWith({
    Set<String>? selectedChips,
    DateTimeRange? dateRange,
    Map<String, String?>? dropdownValues,
    bool clearDateRange = false,
  }) {
    return FilterModel(
      selectedChips: selectedChips ?? this.selectedChips,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      dropdownValues: dropdownValues ?? this.dropdownValues,
    );
  }

  /// Returns true when no filter is actively applied.
  bool get isEmpty =>
      selectedChips.isEmpty && dateRange == null && dropdownValues.values.every((v) => v == null);
}

/// Configuration for a single set of filter chips displayed inside the sheet.
class FilterChipGroup {
  const FilterChipGroup({
    required this.label,
    required this.options,
  });

  /// Section title above the chips.
  final String label;

  /// Map of chip key -> display label.
  final Map<String, String> options;
}

/// Configuration for a dropdown filter inside the sheet.
class FilterDropdownConfig {
  const FilterDropdownConfig({
    required this.key,
    required this.label,
    required this.options,
  });

  final String key;
  final String label;

  /// Map of value -> display label.
  final Map<String, String> options;
}

/// A modal bottom sheet for filtering data.
///
/// Call [AppFilterSheet.show] to present the sheet and await the user's
/// chosen [FilterModel].
class AppFilterSheet extends StatefulWidget {
  const AppFilterSheet._({
    required this.title,
    required this.initialFilter,
    this.chipGroups = const [],
    this.dropdowns = const [],
    this.showDateRange = false,
    this.dateRangeLabel,
    this.firstDate,
    this.lastDate,
  });

  final String title;
  final FilterModel initialFilter;
  final List<FilterChipGroup> chipGroups;
  final List<FilterDropdownConfig> dropdowns;
  final bool showDateRange;
  final String? dateRangeLabel;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Shows the filter bottom sheet and returns the resulting [FilterModel]
  /// when the user taps **Apply**, or `null` if dismissed.
  static Future<FilterModel?> show({
    required BuildContext context,
    required String title,
    FilterModel initialFilter = const FilterModel(),
    List<FilterChipGroup> chipGroups = const [],
    List<FilterDropdownConfig> dropdowns = const [],
    bool showDateRange = false,
    String? dateRangeLabel,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return showModalBottomSheet<FilterModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppFilterSheet._(
        title: title,
        initialFilter: initialFilter,
        chipGroups: chipGroups,
        dropdowns: dropdowns,
        showDateRange: showDateRange,
        dateRangeLabel: dateRangeLabel,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
  }

  @override
  State<AppFilterSheet> createState() => _AppFilterSheetState();
}

class _AppFilterSheetState extends State<AppFilterSheet> {
  late FilterModel _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  void _toggleChip(String key) {
    final chips = Set<String>.from(_filter.selectedChips);
    if (chips.contains(key)) {
      chips.remove(key);
    } else {
      chips.add(key);
    }
    setState(() {
      _filter = _filter.copyWith(selectedChips: chips);
    });
  }

  void _updateDropdown(String key, String? value) {
    final values = Map<String, String?>.from(_filter.dropdownValues);
    values[key] = value;
    setState(() {
      _filter = _filter.copyWith(dropdownValues: values);
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: widget.firstDate ?? DateTime(2020),
      lastDate: widget.lastDate ?? now,
      initialDateRange: _filter.dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _filter = _filter.copyWith(dateRange: picked);
      });
    }
  }

  void _reset() {
    setState(() {
      _filter = const FilterModel();
    });
  }

  void _apply() {
    Navigator.of(context).pop(_filter);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // ── Header ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // ── Scrollable content ─────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chip groups
                  for (final group in widget.chipGroups) ...[
                    Text(
                      group.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: group.options.entries.map((entry) {
                        final selected =
                            _filter.selectedChips.contains(entry.key);
                        return FilterChip(
                          label: Text(entry.value),
                          selected: selected,
                          onSelected: (_) => _toggleChip(entry.key),
                          selectedColor: AppColors.primarySurface,
                          checkmarkColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceVariant,
                          side: BorderSide(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Dropdowns
                  for (final dropdown in widget.dropdowns) ...[
                    Text(
                      dropdown.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.inputBorder),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value:
                              _filter.dropdownValues[dropdown.key],
                          hint: Text(
                            dropdown.label,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.inputHint,
                            ),
                          ),
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary,
                          ),
                          items: dropdown.options.entries
                              .map(
                                (e) => DropdownMenuItem<String>(
                                  value: e.key,
                                  child: Text(
                                    e.value,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              _updateDropdown(dropdown.key, value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Date range
                  if (widget.showDateRange) ...[
                    Text(
                      widget.dateRangeLabel ??
                          '\u0627\u0644\u0641\u062A\u0631\u0629 \u0627\u0644\u0632\u0645\u0646\u064A\u0629', // الفترة الزمنية
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDateRange,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.inputBorder),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _filter.dateRange != null
                                    ? '${_formatDate(_filter.dateRange!.start)}'
                                        ' - '
                                        '${_formatDate(_filter.dateRange!.end)}'
                                    : '\u0627\u062E\u062A\u0631 \u0627\u0644\u0641\u062A\u0631\u0629', // اختر الفترة
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _filter.dateRange != null
                                      ? AppColors.textPrimary
                                      : AppColors.inputHint,
                                ),
                              ),
                            ),
                            if (_filter.dateRange != null)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _filter = _filter.copyWith(
                                        clearDateRange: true);
                                  });
                                },
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppColors.textHint,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),

          // ── Bottom action buttons ──────────────────────────
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    text:
                        '\u0625\u0639\u0627\u062F\u0629 \u062A\u0639\u064A\u064A\u0646', // إعادة تعيين
                    onPressed: _reset,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton.primary(
                    text:
                        '\u062A\u0637\u0628\u064A\u0642', // تطبيق
                    onPressed: _apply,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
