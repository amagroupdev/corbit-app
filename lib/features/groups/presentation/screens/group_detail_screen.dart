import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/constants/feature_flags.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/groups/data/models/group_model.dart';
import 'package:orbit_app/features/groups/data/models/number_model.dart';
import 'package:orbit_app/features/groups/data/repositories/groups_repository.dart';
import 'package:orbit_app/features/groups/presentation/controllers/groups_controller.dart';
import 'package:orbit_app/features/groups/presentation/widgets/add_number_sheet.dart';
import 'package:orbit_app/features/groups/presentation/widgets/contacts_import_sheet.dart';
import 'package:orbit_app/features/groups/presentation/widgets/number_list_item.dart';
import 'package:orbit_app/routing/route_names.dart';
import 'package:orbit_app/shared/widgets/bulk_action_bottom_sheet.dart';
import 'package:orbit_app/shared/widgets/multi_select_app_bar.dart';

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

  // ── Multi-select (Wave 6) ────────────────────────────────────────
  final Set<int> _selectedIds = {};
  bool _bulkBusy = false;

  bool get _isMultiSelect => _selectedIds.isNotEmpty;

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

  // ── Multi-select handlers (Wave 6) ───────────────────────────────

  void _enterMultiSelect(int id) {
    if (!kBulkOperationsEnabled) return;
    setState(() => _selectedIds.add(id));
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitMultiSelect() {
    setState(_selectedIds.clear);
  }

  void _selectAllNumbers() {
    final state = ref.read(groupDetailControllerProvider);
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(state.numbers.map((n) => n.id));
    });
  }

  Future<void> _bulkDeleteNumbers() async {
    if (_selectedIds.isEmpty || _bulkBusy) return;
    final t = AppLocalizations.of(context)!;
    final count = _selectedIds.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t.translate('bulkDelete'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          t.translateWithParams('bulkConfirmDeleteCount', {'count': '$count'}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              t.translate('bulkDelete'),
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _bulkBusy = true);
    final ids = _selectedIds.toList();
    try {
      final repo = ref.read(groupsRepositoryProvider);
      await repo.bulkDeleteNumbers(ids);
      if (!mounted) return;
      _exitMultiSelect();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.translate('bulkSuccessDelete')),
          backgroundColor: AppColors.success,
        ),
      );
      await ref
          .read(groupDetailControllerProvider.notifier)
          .loadNumbers(widget.groupId);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.translate('bulkFailedDelete')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _bulkBusy = false);
    }
  }

  Future<void> _bulkMoveOrCopy({required bool copy}) async {
    if (_selectedIds.isEmpty || _bulkBusy) return;
    final t = AppLocalizations.of(context)!;

    // Fetch up to 100 groups (excluding the current one) so the user
    // can pick a target. The endpoint is the same one used by the
    // groups list screen — no new network code needed.
    final repo = ref.read(groupsRepositoryProvider);

    GroupModel? target;
    try {
      final response = await repo.listGroups(perPage: 100);
      final candidates =
          response.data.where((g) => g.id != widget.groupId && !g.isTrashed).toList();
      if (!mounted) return;
      if (candidates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.translate('bulkNoTargetGroup')),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
      target = await showModalBottomSheet<GroupModel>(
        context: context,
        backgroundColor: AppColors.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      t.translate('bulkSelectTargetGroup'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.6,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: candidates.length,
                    itemBuilder: (_, i) {
                      final g = candidates[i];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.people,
                              color: AppColors.primary, size: 20),
                        ),
                        title: Text(g.name),
                        subtitle: Text(
                          '${g.numbersCount} ${t.translate('numberUnit')}',
                        ),
                        onTap: () => Navigator.of(ctx).pop(g),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
      return;
    }

    if (target == null || !mounted) return;

    setState(() => _bulkBusy = true);
    final ids = _selectedIds.toList();
    try {
      if (copy) {
        await repo.copyNumbersToGroup(
          numberIds: ids,
          targetGroupId: target.id,
        );
      } else {
        await repo.moveNumbersToGroup(
          numberIds: ids,
          targetGroupId: target.id,
        );
      }

      if (!mounted) return;
      _exitMultiSelect();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t.translate(copy ? 'bulkSuccessCopy' : 'bulkSuccessMove'),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      await ref
          .read(groupDetailControllerProvider.notifier)
          .loadNumbers(widget.groupId);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t.translate(copy ? 'bulkFailedCopy' : 'bulkFailedMove'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _bulkBusy = false);
    }
  }

  void _showBulkActionSheet() {
    final t = AppLocalizations.of(context)!;
    BulkActionBottomSheet.show(
      context: context,
      title: t.translateWithParams(
        'bulkSelectCount',
        {'count': '${_selectedIds.length}'},
      ),
      actions: [
        BulkAction(
          icon: Icons.drive_file_move_outlined,
          label: t.translate('bulkMove'),
          onTap: () => _bulkMoveOrCopy(copy: false),
        ),
        BulkAction(
          icon: Icons.content_copy_outlined,
          label: t.translate('bulkCopy'),
          onTap: () => _bulkMoveOrCopy(copy: true),
        ),
        BulkAction(
          icon: Icons.delete_outline,
          label: t.translate('bulkDelete'),
          isDestructive: true,
          onTap: _bulkDeleteNumbers,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupDetailControllerProvider);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _isMultiSelect
          ? MultiSelectAppBar(
              selectedCount: _selectedIds.length,
              totalCount: state.numbers.length,
              onCancel: _exitMultiSelect,
              onSelectAll: _selectAllNumbers,
              actions: [
                if (_bulkBusy)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: t.translate('bulkDelete'),
                    onPressed: _bulkDeleteNumbers,
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    tooltip: t.translate('more'),
                    onPressed: _showBulkActionSheet,
                  ),
                ],
              ],
            )
          : AppBar(
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
                                      final selected =
                                          _selectedIds.contains(number.id);
                                      return NumberListItem(
                                        numberModel: number,
                                        isMultiSelectMode: _isMultiSelect,
                                        isSelected: selected,
                                        onTap: _isMultiSelect
                                            ? () => _toggleSelection(number.id)
                                            : null,
                                        onLongPress: kBulkOperationsEnabled
                                            ? () {
                                                if (_isMultiSelect) {
                                                  _toggleSelection(number.id);
                                                } else {
                                                  _enterMultiSelect(number.id);
                                                }
                                              }
                                            : null,
                                        onEdit: () => _showAddNumberSheet(
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
      floatingActionButton: _isMultiSelect
          ? null
          : FloatingActionButton(
              onPressed: _showAddOptionsSheet,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
