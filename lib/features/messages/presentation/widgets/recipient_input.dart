import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/messages/presentation/controllers/messages_controller.dart';

/// Input widget for adding recipient phone numbers.
///
/// Features:
/// - Phone number text field with add button
/// - Chip list showing added numbers with remove buttons
/// - Paste support for multiple numbers (separated by comma, newline, or space)
class RecipientInput extends ConsumerStatefulWidget {
  const RecipientInput({super.key});

  @override
  ConsumerState<RecipientInput> createState() => _RecipientInputState();
}

class _RecipientInputState extends ConsumerState<RecipientInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String? _errorText;

  void _addNumber() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Support pasting multiple numbers separated by comma, newline, semicolon, or space.
    final rawNumbers = text
        .split(RegExp(r'[,;\n\s]+'))
        .map((n) => n.trim().replaceAll(RegExp(r'[^0-9]'), ''))
        .where((n) => n.isNotEmpty)
        .toList();

    final validNumbers = <String>[];
    var invalidCount = 0;

    for (final n in rawNumbers) {
      if (n.length == 9 && n.startsWith('5')) {
        validNumbers.add(n);
      } else {
        invalidCount++;
      }
    }

    if (invalidCount > 0) {
      setState(() {
        _errorText = 'الرقم يجب أن يبدأ بـ 5 ويكون 9 أرقام';
      });
    } else {
      setState(() {
        _errorText = null;
      });
    }

    if (validNumbers.isNotEmpty) {
      ref.read(messageFormProvider.notifier).addNumbers(validNumbers);
    }

    _controller.clear();
    _focusNode.requestFocus();
  }

  void _removeNumber(String number) {
    ref.read(messageFormProvider.notifier).removeNumber(number);
  }

  void _clearAll() {
    ref.read(messageFormProvider.notifier).clearNumbers();
  }

  @override
  Widget build(BuildContext context) {
    final numbers = ref.watch(messageFormProvider).numbers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Label ──────────────────────────────────────────────
        Row(
          children: [
            const Text(
              'أرقام المستقبلين',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (numbers.isNotEmpty)
              Text(
                '${numbers.length} رقم',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        // ─── Input Row ──────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                inputFormatters: [
                  // Allow digits, commas, spaces, newlines for multi-paste.
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,;\s\n]')),
                  LengthLimitingTextInputFormatter(200),
                ],
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() => _errorText = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: '5XXXXXXXX',
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                  errorText: _errorText,
                  errorStyle: const TextStyle(fontSize: 11),
                  filled: true,
                  fillColor: AppColors.inputFill,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.inputBorderFocused,
                      width: 1.5,
                    ),
                  ),
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                onSubmitted: (_) => _addNumber(),
              ),
            ),
            const SizedBox(width: 8),
            // Add button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _addNumber,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Icon(Icons.add, size: 22),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Hint text
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(
            _errorText == null
                ? 'أدخل رقم يبدأ بـ 5 ويتكون من 9 أرقام (مثال: 512345678)'
                : '',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textHint,
            ),
          ),
        ),

        // ─── Number Chips ───────────────────────────────────────
        if (numbers.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Clear all button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: _clearAll,
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          'مسح الكل',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Chips
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: numbers.map((number) {
                        return Chip(
                          label: Text(
                            number,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              fontFamily: 'monospace',
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          onDeleted: () => _removeNumber(number),
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
