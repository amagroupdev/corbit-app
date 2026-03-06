import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/messages/data/models/template_model.dart';
import 'package:orbit_app/features/templates/data/repositories/templates_repository.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// Bottom sheet form for creating or editing a message template.
///
/// If [template] is provided, the form is in edit mode and pre-populates
/// the fields with the template's current values.
class TemplateFormSheet extends ConsumerStatefulWidget {
  const TemplateFormSheet({this.template, super.key});

  /// The template to edit, or `null` to create a new one.
  final TemplateModel? template;

  /// Shows the bottom sheet and returns the created/updated template,
  /// or `null` if the user cancelled.
  static Future<TemplateModel?> show(
    BuildContext context, {
    TemplateModel? template,
  }) {
    return showModalBottomSheet<TemplateModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TemplateFormSheet(template: template),
    );
  }

  @override
  ConsumerState<TemplateFormSheet> createState() => _TemplateFormSheetState();
}

class _TemplateFormSheetState extends ConsumerState<TemplateFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bodyController;
  bool _isLoading = false;

  bool get _isEditing => widget.template != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _bodyController = TextEditingController(text: widget.template?.body ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(templatesRepositoryProvider);
      TemplateModel result;

      if (_isEditing) {
        result = await repository.updateTemplate(
          id: widget.template!.id,
          name: _nameController.text.trim(),
          body: _bodyController.text.trim(),
        );
      } else {
        result = await repository.createTemplate(
          name: _nameController.text.trim(),
          body: _bodyController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Handle bar ───────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Title ────────────────────────────────────────
            Text(
              _isEditing
                  ? '\u062A\u0639\u062F\u064A\u0644 \u0627\u0644\u0642\u0627\u0644\u0628' // تعديل القالب
                  : '\u0625\u0646\u0634\u0627\u0621 \u0642\u0627\u0644\u0628 \u062C\u062F\u064A\u062F', // إنشاء قالب جديد
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // ── Name field ───────────────────────────────────
            AppTextField(
              label: '\u0627\u0633\u0645 \u0627\u0644\u0642\u0627\u0644\u0628', // اسم القالب
              hint: '\u0623\u062F\u062E\u0644 \u0627\u0633\u0645 \u0627\u0644\u0642\u0627\u0644\u0628', // أدخل اسم القالب
              controller: _nameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '\u064A\u0631\u062C\u0649 \u0625\u062F\u062E\u0627\u0644 \u0627\u0633\u0645 \u0627\u0644\u0642\u0627\u0644\u0628'; // يرجى إدخال اسم القالب
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // ── Body field ───────────────────────────────────
            AppTextField(
              label: '\u0646\u0635 \u0627\u0644\u0631\u0633\u0627\u0644\u0629', // نص الرسالة
              hint: '\u0623\u062F\u062E\u0644 \u0646\u0635 \u0627\u0644\u0631\u0633\u0627\u0644\u0629', // أدخل نص الرسالة
              controller: _bodyController,
              maxLines: 5,
              minLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '\u064A\u0631\u062C\u0649 \u0625\u062F\u062E\u0627\u0644 \u0646\u0635 \u0627\u0644\u0631\u0633\u0627\u0644\u0629'; // يرجى إدخال نص الرسالة
                }
                return null;
              },
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),

            // ── Submit button ────────────────────────────────
            AppButton.primary(
              text: _isEditing
                  ? '\u062A\u062D\u062F\u064A\u062B' // تحديث
                  : '\u0625\u0646\u0634\u0627\u0621', // إنشاء
              onPressed: _submit,
              isLoading: _isLoading,
              icon: _isEditing ? Icons.save_rounded : Icons.add_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
