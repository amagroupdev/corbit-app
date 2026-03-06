import 'package:flutter/material.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/groups/data/models/number_model.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// A bottom sheet widget for adding or editing a phone number.
///
/// When [existingNumber] is provided, the sheet pre-fills fields
/// for editing. Otherwise, it presents empty fields for creation.
class AddNumberSheet extends StatefulWidget {
  const AddNumberSheet({
    required this.onSave,
    this.existingNumber,
    this.isLoading = false,
    super.key,
  });

  /// Called when the user submits the form with valid data.
  /// Parameters: name, phone number, identifier.
  final void Function(String name, String number, String? identifier) onSave;

  /// If provided, the sheet operates in edit mode.
  final NumberModel? existingNumber;

  /// Shows a loading indicator on the save button.
  final bool isLoading;

  @override
  State<AddNumberSheet> createState() => _AddNumberSheetState();
}

class _AddNumberSheetState extends State<AddNumberSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _numberController;
  late final TextEditingController _identifierController;

  bool get _isEditing => widget.existingNumber != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingNumber?.name ?? '',
    );
    _numberController = TextEditingController(
      text: widget.existingNumber?.number ?? '',
    );
    _identifierController = TextEditingController(
      text: widget.existingNumber?.identifier ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _identifierController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    widget.onSave(
      _nameController.text.trim(),
      _numberController.text.trim(),
      _identifierController.text.trim().isNotEmpty
          ? _identifierController.text.trim()
          : null,
    );
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
      child: Form(
        key: _formKey,
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
              _isEditing
                  ? '\u062A\u0639\u062F\u064A\u0644 \u0631\u0642\u0645'
                  : '\u0625\u0636\u0627\u0641\u0629 \u0631\u0642\u0645 \u062C\u062F\u064A\u062F',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Name field
            AppTextField(
              label: '\u0627\u0644\u0627\u0633\u0645',
              hint: '\u0623\u062F\u062E\u0644 \u0627\u0633\u0645 \u0627\u0644\u062C\u0647\u0629 \u0627\u0644\u0627\u062A\u0635\u0627\u0644',
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Phone number field
            AppTextField(
              label: '\u0631\u0642\u0645 \u0627\u0644\u0647\u0627\u062A\u0641',
              hint: '05xxxxxxxx',
              controller: _numberController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '\u0631\u0642\u0645 \u0627\u0644\u0647\u0627\u062A\u0641 \u0645\u0637\u0644\u0648\u0628';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Identifier field (optional)
            AppTextField(
              label: '\u0627\u0644\u0645\u0639\u0631\u0641 (\u0627\u062E\u062A\u064A\u0627\u0631\u064A)',
              hint: '\u0631\u0642\u0645 \u0627\u0644\u0647\u0648\u064A\u0629 \u0623\u0648 \u0631\u0642\u0645 \u0627\u0644\u0645\u0648\u0638\u0641',
              controller: _identifierController,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleSave(),
            ),
            const SizedBox(height: 24),

            // Save button
            AppButton.primary(
              text: _isEditing
                  ? '\u062A\u062D\u062F\u064A\u062B'
                  : '\u0625\u0636\u0627\u0641\u0629',
              onPressed: widget.isLoading ? null : _handleSave,
              isLoading: widget.isLoading,
              icon: _isEditing ? Icons.check : Icons.add,
            ),
          ],
        ),
      ),
    );
  }
}
