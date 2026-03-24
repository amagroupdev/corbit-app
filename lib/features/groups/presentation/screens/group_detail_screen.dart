import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/groups/data/models/number_model.dart';
import 'package:orbit_app/features/groups/data/repositories/groups_repository.dart';
import 'package:orbit_app/features/groups/presentation/controllers/groups_controller.dart';
import 'package:orbit_app/features/groups/presentation/widgets/add_number_sheet.dart';
import 'package:orbit_app/features/groups/presentation/widgets/contacts_import_sheet.dart';
import 'package:orbit_app/features/groups/presentation/widgets/number_list_item.dart';
import 'package:orbit_app/routing/route_names.dart';

/// Screen showing the details of a single group and its phone numbers.
///
/// Features:
/// - Editable group name
/// - Numbers count badge
/// - List of numbers with search
/// - Add / edit / delete numbers
/// - Import and export buttons
class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({required this.groupId, super.key});

  final int groupId;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  final _scrollController = ScrollController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(groupDetailControllerProvider.notifier)
          .loadGroup(widget.groupId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(groupDetailControllerProvider.notifier)
          .loadMoreNumbers(widget.groupId);
    }
  }

  void _showEditGroupNameDialog() {
    final state = ref.read(groupDetailControllerProvider);
    final controller = TextEditingController(text: state.group?.name ?? '');
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t.translate('editGroupName'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: t.translate('groupName'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              t.translate('cancel'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop();

              final success = await ref
                  .read(groupDetailControllerProvider.notifier)
                  .updateGroupName(widget.groupId, name);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? t.translate('groupNameUpdated')
                        : t.translate('groupNameUpdateFailed')),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: Text(
              t.translate('save'),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddOptionsSheet() {
    final t = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
            Text(
              t.translate('addNumbers'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Option 1: Manual add
            _buildOptionTile(
              icon: Icons.dialpad,
              title: t.translate('addNumberManual'),
              subtitle: t.translate('addNumberManualSubtitle'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showAddNumberSheet();
              },
            ),
            const SizedBox(height: 12),
            // Option 2: Import from contacts
            _buildOptionTile(
              icon: Icons.contacts,
              title: t.translate('addFromContacts'),
              subtitle: t.translate('addFromContactsSubtitle'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showContactsImportSheet();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  void _showContactsImportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ContactsImportSheet(groupId: widget.groupId),
    );
  }

  void _showAddNumberSheet({NumberModel? existingNumber}) {
    final t = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return AddNumberSheet(
            existingNumber: existingNumber,
            isLoading: _isSaving,
            onSave: (name, number, identifier) async {
              setSheetState(() => _isSaving = true);

              bool success;
              if (existingNumber != null) {
                success = await ref
                    .read(groupDetailControllerProvider.notifier)
                    .updateNumber(
                      id: existingNumber.id,
                      name: name,
                      number: number,
                      identifier: identifier,
                    );
              } else {
                success = await ref
                    .read(groupDetailControllerProvider.notifier)
                    .addNumber(
                      groupId: widget.groupId,
                      name: name,
                      number: number,
                      identifier: identifier,
                    );
              }

              setSheetState(() => _isSaving = false);

              if (success && ctx.mounted) {
                Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(existingNumber != null
                          ? t.translate('numberUpdated')
                          : t.translate('numberAdded')),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
          );
        },
      ),
    );
  }

  void _showDeleteNumberDialog(NumberModel numberModel) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t.translate('deleteNumber'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '${t.translate('confirmDeleteNumber')} "${numberModel.number}"\u061F',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              t.translate('cancel'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref
                  .read(groupDetailControllerProvider.notifier)
                  .deleteNumber(numberModel.id);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t.translate('numberDeleted')),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: Text(
              t.translate('delete'),
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupDetailControllerProvider);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showEditGroupNameDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  state.group?.name ?? t.translate('loading'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.edit_outlined, size: 18),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: () => context.pushNamed(RouteNames.importNumbers),
            tooltip: t.translate('import'),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : state.error != null && state.group == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        state.error!,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => ref
                            .read(groupDetailControllerProvider.notifier)
                            .loadGroup(widget.groupId),
                        icon: const Icon(Icons.refresh),
                        label: Text(t.translate('retry')),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Numbers count header
                    Container(
                      width: double.infinity,
                      color: AppColors.surface,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.phone_outlined,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${state.numbersCount} ${t.translate('numberUnit')}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () async {
                              try {
                                final repo = ref.read(groupsRepositoryProvider);
                                await repo.exportGroups();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(t.translate('exporting')),
                                      backgroundColor: AppColors.info,
                                    ),
                                  );
                                }
                              } catch (_) {}
                            },
                            icon: const Icon(Icons.download_outlined, size: 18),
                            label: Text(
                              t.translate('export'),
                              style: const TextStyle(fontSize: 13),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Numbers list
                    Expanded(
                      child: state.isLoadingNumbers
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : state.numbers.isEmpty
                              ? _buildEmptyNumbers()
                              : RefreshIndicator(
                                  onRefresh: () async {
                                    await ref
                                        .read(groupDetailControllerProvider
                                            .notifier)
                                        .loadNumbers(widget.groupId);
                                  },
                                  color: AppColors.primary,
                                  child: ListView.separated(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: state.numbers.length +
                                        (state.hasMoreNumbers ? 1 : 0),
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      if (index >= state.numbers.length) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 16),
                                            child: CircularProgressIndicator(
                                              color: AppColors.primary,
                                              strokeWidth: 2.5,
                                            ),
                                          ),
                                        );
                                      }

                                      final number = state.numbers[index];
                                      return NumberListItem(
                                        numberModel: number,
                                        onEdit: () =>
                                            _showAddNumberSheet(
                                                existingNumber: number),
                                        onDelete: () =>
                                            _showDeleteNumberDialog(number),
                                      );
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptionsSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.person_add_outlined),
      ),
    );
  }

  Widget _buildEmptyNumbers() {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.contact_phone_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.translate('noNumbers'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.translate('addNumbersOrImport'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
