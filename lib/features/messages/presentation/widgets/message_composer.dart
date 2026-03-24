import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/messages/presentation/controllers/messages_controller.dart';

/// Multi-line text field for composing SMS message body.
///
/// Features:
/// - RTL text direction for Arabic
/// - Live character count and SMS segment count
/// - Template insert button (triggers parent callback)
/// - Variable insert button with menu of available variables
class MessageComposer extends ConsumerStatefulWidget {
  const MessageComposer({
    this.onInsertTemplate,
    super.key,
  });

  /// Callback triggered when the user taps the template insert button.
  final VoidCallback? onInsertTemplate;

  @override
  ConsumerState<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends ConsumerState<MessageComposer> {
  late final TextEditingController _controller;

  /// Available message variables that can be inserted.
  static const List<_Variable> _variables = [
    _Variable('student_name', 'msg_var_student_name'),
    _Variable('customer_name', 'msg_var_customer_name'),
    _Variable('guardian_name', 'msg_var_guardian_name'),
    _Variable('teacher_name', 'msg_var_teacher_name'),
    _Variable('class_name', 'msg_var_class_name'),
    _Variable('school_name', 'msg_var_school_name'),
    _Variable('date', 'msg_var_date'),
    _Variable('time', 'msg_var_time'),
    _Variable('grade', 'msg_var_grade'),
    _Variable('absence_date', 'msg_var_absence_date'),
    _Variable('company_name', 'msg_var_company_name'),
    _Variable('order_number', 'msg_var_order_number'),
  ];

  @override
  void initState() {
    super.initState();
    final initialBody = ref.read(messageFormProvider).messageBody;
    _controller = TextEditingController(text: initialBody);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    ref.read(messageFormProvider.notifier).setMessageBody(value);
  }

  void _insertVariable(_Variable variable) {
    final text = _controller.text;
    final selection = _controller.selection;
    final cursorPos = selection.isValid ? selection.baseOffset : text.length;
    final variableText = '{${variable.key}}';

    final newText = text.substring(0, cursorPos) +
        variableText +
        text.substring(cursorPos);

    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: cursorPos + variableText.length,
    );

    ref.read(messageFormProvider.notifier).setMessageBody(newText);
  }

  void _showVariablesMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.code,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.translate('msg_insert_variable'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _variables.length,
                    itemBuilder: (context, index) {
                      final variable = _variables[index];
                      return ListTile(
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '{${variable.key}}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                        title: Text(
                          AppLocalizations.of(context)!.translate(variable.labelKey),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _insertVariable(variable);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final smsCount = ref.watch(smsCountProvider);

    // Keep text controller in sync with external state changes
    // (e.g. template insertion).
    ref.listen<MessageFormState>(messageFormProvider, (prev, next) {
      if (next.messageBody != _controller.text) {
        _controller.text = next.messageBody;
        _controller.selection = TextSelection.collapsed(
          offset: next.messageBody.length,
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Label Row ───────────────────────────────────────────
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.translate('msg_message_body_label'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            // Template button
            if (widget.onInsertTemplate != null)
              InkWell(
                onTap: widget.onInsertTemplate,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primaryBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.translate('msg_template_btn'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 8),
            // Variable button
            InkWell(
              onTap: _showVariablesMenu,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.infoSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.infoBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.code,
                      size: 14,
                      color: AppColors.info,
                    ),
                    SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.translate('msg_variable_btn'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ─── Text Field ──────────────────────────────────────────
        TextField(
          controller: _controller,
          onChanged: _onTextChanged,
          maxLines: 6,
          minLines: 4,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
            height: 1.6,
          ),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.translate('msg_body_hint'),
            hintStyle: const TextStyle(
              color: AppColors.textHint,
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppColors.inputFill,
            contentPadding: const EdgeInsets.all(16),
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
          ),
        ),

        const SizedBox(height: 8),

        // ─── Character / SMS Count Bar ───────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Character count
              _CountIndicator(
                icon: Icons.text_fields,
                label: AppLocalizations.of(context)!.translate('msg_char_label'),
                value: smsCount.characterCount,
              ),
              const SizedBox(width: 20),
              // SMS segment count
              _CountIndicator(
                icon: Icons.sms_outlined,
                label: AppLocalizations.of(context)!.translate('msg_sms_label'),
                value: smsCount.smsCount,
                highlight: smsCount.smsCount > 1,
              ),
              const Spacer(),
              // Encoding indicator
              Text(
                _isUnicode(ref.watch(messageFormProvider).messageBody)
                    ? 'Unicode'
                    : 'GSM',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isUnicode(String text) {
    if (text.isEmpty) return false;
    // Simple check: if text contains Arabic characters, it is Unicode.
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }
}

// ─── Count Indicator ─────────────────────────────────────────────────────────

class _CountIndicator extends StatelessWidget {
  const _CountIndicator({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final int value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.primary : AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─── Variable Model ──────────────────────────────────────────────────────────

class _Variable {
  const _Variable(this.key, this.labelKey);

  /// The variable key used in the message body (e.g. 'student_name').
  final String key;

  /// Localization key for display label.
  final String labelKey;
}
