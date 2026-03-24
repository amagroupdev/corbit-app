import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/groups/data/repositories/groups_repository.dart';
import 'package:orbit_app/features/groups/presentation/controllers/groups_controller.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// Screen for creating a new contact group.
///
/// Contains a simple form with a group name input and a create button.
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final t = AppLocalizations.of(context)!;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(groupsRepositoryProvider);
      await repository.createGroup(name: name);

      // Refresh the groups list.
      ref.read(groupsListControllerProvider.notifier).loadGroups();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.translate('groupCreated')),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.translate('unexpectedError')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          t.translate('createNewGroup'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon header
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.group_add_outlined,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Group name field
              AppTextField(
                label: t.translate('groupName'),
                hint: t.translate('enterGroupName'),
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleCreate(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return t.translate('groupNameRequired');
                  }
                  if (value.trim().length < 2) {
                    return t.translate('groupNameMinLength');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Create button
              AppButton.primary(
                text: t.translate('createGroupButton'),
                onPressed: _isLoading ? null : _handleCreate,
                isLoading: _isLoading,
                icon: Icons.add,
              ),
              const SizedBox(height: 16),

              // Helper text
              Center(
                child: Text(
                  t.translate('addNumbersAfterCreate'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
