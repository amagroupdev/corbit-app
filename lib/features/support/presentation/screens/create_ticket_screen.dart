import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/support/presentation/controllers/support_controller.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// Form to open a new support ticket.
///
/// Per the V3 Postman master collection the only required field is
/// `title`; the body of the ticket is captured later via the (web-only)
/// reply system, so the form intentionally stays minimal.
class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() =>
      _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  Map<String, List<String>> _serverErrors = {};

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;

    final result = await ref
        .read(createTicketControllerProvider.notifier)
        .submit(title: _titleController.text.trim());

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.translate('supportTicketSubmitted')),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
      return;
    }

    if (result.fieldErrors.isNotEmpty) {
      setState(() => _serverErrors = result.fieldErrors);
    }
    final message = result.errorMessage ?? t.translate('supportTicketFailed');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isSubmitting = ref.watch(createTicketControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(t.translate('supportTicketCreate')),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: t.translate('supportTicketTitle'),
                  hint: t.translate('supportTicketTitlePlaceholder'),
                  controller: _titleController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return t.translate('supportTicketTitleRequired');
                    }
                    return null;
                  },
                ),
                if (_serverErrors['title'] != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _serverErrors['title']!.join('\n'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                AppButton.primary(
                  text: t.translate('supportTicketSubmit'),
                  onPressed: isSubmitting ? null : _submit,
                  isLoading: isSubmitting,
                  icon: Icons.send_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
