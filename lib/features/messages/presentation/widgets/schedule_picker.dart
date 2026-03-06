import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/messages/data/models/message_model.dart';
import 'package:orbit_app/features/messages/presentation/controllers/messages_controller.dart';

/// Toggle widget for scheduling message delivery.
///
/// Two modes:
/// - "إرسال الآن" (Send now) -- default
/// - "إرسال لاحقاً" (Schedule) -- shows date and time pickers
class SchedulePicker extends ConsumerWidget {
  const SchedulePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(messageFormProvider);
    final isScheduled = formState.sendAtOption == SendAtOption.later;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Label ──────────────────────────────────────────────
        const Text(
          'وقت الإرسال',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 10),

        // ─── Toggle Buttons ─────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Send now
              Expanded(
                child: _ToggleOption(
                  label: 'إرسال الآن',
                  icon: Icons.send_rounded,
                  isSelected: !isScheduled,
                  onTap: () {
                    ref
                        .read(messageFormProvider.notifier)
                        .setSendAtOption(SendAtOption.now);
                  },
                ),
              ),
              // Schedule
              Expanded(
                child: _ToggleOption(
                  label: 'إرسال لاحقاً',
                  icon: Icons.schedule,
                  isSelected: isScheduled,
                  onTap: () {
                    ref
                        .read(messageFormProvider.notifier)
                        .setSendAtOption(SendAtOption.later);
                  },
                ),
              ),
            ],
          ),
        ),

        // ─── Date/Time Pickers ──────────────────────────────────
        if (isScheduled) ...[
          const SizedBox(height: 16),
          _ScheduleDateTime(
            selectedDateTime: formState.sendAt,
            onDateTimeChanged: (dateTime) {
              ref.read(messageFormProvider.notifier).setSendAt(dateTime);
            },
          ),
        ],
      ],
    );
  }
}

// ─── Toggle Option ───────────────────────────────────────────────────────────

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Schedule Date/Time Selector ─────────────────────────────────────────────

class _ScheduleDateTime extends StatelessWidget {
  const _ScheduleDateTime({
    required this.selectedDateTime,
    required this.onDateTimeChanged,
  });

  final DateTime? selectedDateTime;
  final ValueChanged<DateTime> onDateTimeChanged;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('ar'),
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

    if (pickedDate != null) {
      final currentTime = selectedDateTime ?? now;
      final combined = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        currentTime.hour,
        currentTime.minute,
      );
      onDateTimeChanged(combined);
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final now = DateTime.now();
    final currentDateTime = selectedDateTime ?? now;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentDateTime),
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
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );

    if (pickedTime != null) {
      final date = selectedDateTime ?? now;
      final combined = DateTime(
        date.year,
        date.month,
        date.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      onDateTimeChanged(combined);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = selectedDateTime != null
        ? DateFormat('yyyy/MM/dd', 'ar').format(selectedDateTime!)
        : 'اختر التاريخ';
    final timeStr = selectedDateTime != null
        ? DateFormat('hh:mm a', 'ar').format(selectedDateTime!)
        : 'اختر الوقت';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Date picker row
          _PickerRow(
            icon: Icons.calendar_today_outlined,
            label: 'التاريخ',
            value: dateStr,
            isPlaceholder: selectedDateTime == null,
            onTap: () => _pickDate(context),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),

          // Time picker row
          _PickerRow(
            icon: Icons.access_time_outlined,
            label: 'الوقت',
            value: timeStr,
            isPlaceholder: selectedDateTime == null,
            onTap: () => _pickTime(context),
          ),

          // Selected datetime summary
          if (selectedDateTime != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_available,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم الإرسال في $dateStr الساعة $timeStr',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Picker Row ──────────────────────────────────────────────────────────────

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.isPlaceholder = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isPlaceholder
                    ? AppColors.textHint
                    : AppColors.textPrimary,
                fontWeight:
                    isPlaceholder ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
