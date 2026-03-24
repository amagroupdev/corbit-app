import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/utils/validators.dart';
import 'package:orbit_app/features/settings/data/models/permission_model.dart';
import 'package:orbit_app/features/settings/data/models/role_model.dart';
import 'package:orbit_app/features/settings/presentation/controllers/settings_controller.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

import 'package:orbit_app/core/localization/app_localizations.dart';
/// Screen for managing roles and permissions.
class RolesScreen extends ConsumerWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(rolesProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('settings_roles_title')),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRoleForm(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: rolesAsync.when(
        data: (paginated) {
          if (paginated.isEmpty) {
            return AppEmptyState(
              icon: Icons.security_rounded,
              title: AppLocalizations.of(context)!.translate('roles_empty'),
              description: AppLocalizations.of(context)!.translate('roles_empty_desc'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(rolesProvider.notifier).refresh(),
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: paginated.data.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final role = paginated.data[index];
                return _RoleCard(
                  role: role,
                  onEdit: () => _showRoleForm(context, ref, role: role),
                  onDelete: () => _deleteRole(context, ref, role.id),
                );
              },
            ),
          );
        },
        loading: () => AppLoading.listShimmer(),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.read(rolesProvider.notifier).refresh(),
        ),
      ),
    );
  }

  void _showRoleForm(BuildContext context, WidgetRef ref, {RoleModel? role}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _RoleFormScreen(role: role),
      ),
    );
  }

  Future<void> _deleteRole(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('roles_delete_title')),
        content: Text(AppLocalizations.of(context)!.translate('roles_delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppLocalizations.of(context)!.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(rolesProvider.notifier).delete(id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('roles_deleted')),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.translate('error_prefix')}: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

// ── Role Card ────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.onEdit,
    required this.onDelete,
  });

  final RoleModel role;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.security_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.name ?? AppLocalizations.of(context)!.translate('invoice_status_unknown'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (role.description != null &&
                    role.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    role.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${role.permissions.length} ${AppLocalizations.of(context)!.translate('roles_permission_count')}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 20),
            color: AppColors.primary,
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}

// ── Role Form Screen ─────────────────────────────────────────────────────

class _RoleFormScreen extends ConsumerStatefulWidget {
  const _RoleFormScreen({this.role});

  final RoleModel? role;

  @override
  ConsumerState<_RoleFormScreen> createState() => _RoleFormScreenState();
}

class _RoleFormScreenState extends ConsumerState<_RoleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<int> _selectedPermissions = {};
  bool _isLoading = false;

  bool get isEditing => widget.role != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.role!.name ?? '';
      _descriptionController.text = widget.role!.description ?? '';
      _selectedPermissions.addAll(widget.role!.permissions);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final permissionsAsync = ref.watch(permissionsProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(isEditing ? AppLocalizations.of(context)!.translate('roles_edit_title') : AppLocalizations.of(context)!.translate('roles_create_title')),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              label: AppLocalizations.of(context)!.translate('roles_name_label'),
              hint: AppLocalizations.of(context)!.translate('roles_name_hint'),
              controller: _nameController,
              validator: (v) =>
                  Validators.validateRequired(v, fieldName: AppLocalizations.of(context)!.translate('roles_name_label')),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            AppTextField(
              label: AppLocalizations.of(context)!.translate('roles_description_label'),
              hint: AppLocalizations.of(context)!.translate('roles_description_hint'),
              controller: _descriptionController,
              maxLines: 2,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),

            Text(
              AppLocalizations.of(context)!.translate('roles_permissions_label'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Permissions grouped by category
            permissionsAsync.when(
              data: (permissions) {
                final groups = PermissionGroup.groupPermissions(permissions);
                return Column(
                  children: groups
                      .map((group) => _buildPermissionGroup(group))
                      .toList(),
                );
              },
              loading: () => AppLoading.circular(),
              error: (error, _) => Text('${AppLocalizations.of(context)!.translate('error_prefix')}: $error'),
            ),

            const SizedBox(height: 32),

            AppButton.primary(
              text: isEditing ? AppLocalizations.of(context)!.translate('profile_save_changes') : AppLocalizations.of(context)!.translate('roles_create_button'),
              onPressed: _isLoading ? null : _submit,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionGroup(PermissionGroup group) {
    final allSelected =
        group.permissions.every((p) => _selectedPermissions.contains(p.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                group.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // Select all toggle
            GestureDetector(
              onTap: () {
                setState(() {
                  if (allSelected) {
                    for (final p in group.permissions) {
                      _selectedPermissions.remove(p.id);
                    }
                  } else {
                    for (final p in group.permissions) {
                      _selectedPermissions.add(p.id);
                    }
                  }
                });
              },
              child: Text(
                allSelected ? AppLocalizations.of(context)!.translate('roles_deselect_all') : AppLocalizations.of(context)!.translate('roles_select_all'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: group.permissions.map((permission) {
          return CheckboxListTile(
            title: Text(
              permission.displayName ?? permission.name ?? '',
              style: const TextStyle(fontSize: 14),
            ),
            value: _selectedPermissions.contains(permission.id),
            onChanged: (selected) {
              setState(() {
                if (selected == true) {
                  _selectedPermissions.add(permission.id);
                } else {
                  _selectedPermissions.remove(permission.id);
                }
              });
            },
            activeColor: AppColors.primary,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
          );
        }).toList(),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'permissions': _selectedPermissions.toList(),
      };

      Map<String, dynamic> result;
      if (isEditing) {
        result = await ref
            .read(rolesProvider.notifier)
            .updateRole(widget.role!.id, data);
      } else {
        result = await ref.read(rolesProvider.notifier).create(data);
      }

      final success = result['success'] as bool? ?? false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (isEditing ? AppLocalizations.of(context)!.translate('roles_updated') : AppLocalizations.of(context)!.translate('roles_created'))
                  : (result['message'] as String? ?? AppLocalizations.of(context)!.translate('unknown_error')),
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        if (success) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.translate('error_prefix')}: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
