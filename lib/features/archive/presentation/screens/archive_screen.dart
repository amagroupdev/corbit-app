import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/archive/data/models/archive_model.dart';
import 'package:orbit_app/features/archive/presentation/controllers/archive_controller.dart';
import 'package:orbit_app/features/archive/presentation/widgets/archive_filter_sheet.dart';
import 'package:orbit_app/features/archive/presentation/widgets/archive_item_card.dart';
import 'package:orbit_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';

/// Main archive screen with scrollable tab bar, filter, search,
/// infinite scroll list, and multi-select actions.
class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<ArchiveType> _visibleTypes;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _visibleTypes = ArchiveType.forUserType(user?.userTypeId);
    _tabController = TabController(
      length: _visibleTypes.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);

    // Load initial data.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArchive();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    final type = _visibleTypes[_tabController.index];
    ref.read(archiveSelectedTabProvider.notifier).state = type;
    _exitMultiSelect();
    _loadArchive();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadArchive() {
    final type = ref.read(archiveSelectedTabProvider);
    final filter = ref.read(archiveFilterProvider);
    ref.read(archiveListProvider.notifier).fetchArchive(
          archiveType: type,
          filter: filter,
        );
  }

  void _loadMore() {
    final type = ref.read(archiveSelectedTabProvider);
    final filter = ref.read(archiveFilterProvider);
    ref.read(archiveListProvider.notifier).loadMore(
          archiveType: type,
          filter: filter,
        );
  }

  Future<void> _onRefresh() async {
    final type = ref.read(archiveSelectedTabProvider);
    final filter = ref.read(archiveFilterProvider);
    await ref.read(archiveListProvider.notifier).refresh(
          archiveType: type,
          filter: filter,
        );
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        ref.read(archiveSearchQueryProvider.notifier).state = '';
      }
    });
  }

  void _onSearchChanged(String query) {
    ref.read(archiveSearchQueryProvider.notifier).state = query;
  }

  // ─── Multi-select ──────────────────────────────────────────────────

  void _enterMultiSelect(int itemId) {
    ref.read(archiveMultiSelectModeProvider.notifier).state = true;
    ref.read(archiveSelectedIdsProvider.notifier).state = {itemId};
  }

  void _exitMultiSelect() {
    ref.read(archiveMultiSelectModeProvider.notifier).state = false;
    ref.read(archiveSelectedIdsProvider.notifier).state = {};
  }

  void _toggleItemSelection(int itemId) {
    final selected = Set<int>.from(ref.read(archiveSelectedIdsProvider));
    if (selected.contains(itemId)) {
      selected.remove(itemId);
      if (selected.isEmpty) {
        _exitMultiSelect();
        return;
      }
    } else {
      selected.add(itemId);
    }
    ref.read(archiveSelectedIdsProvider.notifier).state = selected;
  }

  void _selectAll() {
    final items = ref.read(filteredArchiveItemsProvider);
    ref.read(archiveSelectedIdsProvider.notifier).state =
        items.map((e) => e.id).toSet();
  }

  // ─── Actions ───────────────────────────────────────────────────────

  Future<void> _deleteSelected() async {
    final ids = ref.read(archiveSelectedIdsProvider).toList();
    if (ids.isEmpty) return;

    final t = AppLocalizations.of(context)!;
    final confirmed = await _showConfirmDialog(
      title: t.translate('archive_delete_messages'),
      message: t.translateWithParams('archive_confirm_delete', {'count': '${ids.length}'}),
    );
    if (confirmed != true) return;

    final type = ref.read(archiveSelectedTabProvider);
    final success = await ref.read(archiveActionsProvider.notifier).deleteMessages(
          archiveType: type,
          messageIds: ids,
          listNotifier: ref.read(archiveListProvider.notifier),
        );

    if (success && mounted) {
      _exitMultiSelect();
      _showSnackBar(t.translate('archive_messages_deleted'));
    }
  }

  Future<void> _cancelPendingSelected() async {
    final ids = ref.read(archiveSelectedIdsProvider).toList();
    if (ids.isEmpty) return;

    final t = AppLocalizations.of(context)!;
    final confirmed = await _showConfirmDialog(
      title: t.translate('archive_cancel_messages'),
      message: t.translateWithParams('archive_confirm_cancel', {'count': '${ids.length}'}),
    );
    if (confirmed != true) return;

    final success = await ref.read(archiveActionsProvider.notifier).cancelPending(
          messageIds: ids,
          listNotifier: ref.read(archiveListProvider.notifier),
        );

    if (success && mounted) {
      _exitMultiSelect();
      _showSnackBar(t.translate('archive_messages_cancelled'));
    }
  }

  Future<void> _restoreSelected() async {
    final ids = ref.read(archiveSelectedIdsProvider).toList();
    if (ids.isEmpty) return;

    final success = await ref.read(archiveActionsProvider.notifier).restore(
          messageIds: ids,
          listNotifier: ref.read(archiveListProvider.notifier),
        );

    if (success && mounted) {
      _exitMultiSelect();
      _showSnackBar(AppLocalizations.of(context)!.translate('archive_messages_restored'));
    }
  }

  Future<void> _exportArchive() async {
    final type = ref.read(archiveSelectedTabProvider);
    final filter = ref.read(archiveFilterProvider);
    await ref.read(archiveActionsProvider.notifier).exportArchive(
          archiveType: type,
          filter: filter,
        );

    if (mounted) {
      _showSnackBar(AppLocalizations.of(context)!.translate('archive_export_requested'));
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              AppLocalizations.of(context)!.translate('cancel'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              AppLocalizations.of(context)!.translate('confirm'),
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final archiveState = ref.watch(archiveListProvider);
    final isMultiSelect = ref.watch(archiveMultiSelectModeProvider);
    final selectedIds = ref.watch(archiveSelectedIdsProvider);
    final filteredItems = ref.watch(filteredArchiveItemsProvider);
    final filter = ref.watch(archiveFilterProvider);
    final actionState = ref.watch(archiveActionsProvider);

    // Listen for filter changes and reload.
    ref.listen<ArchiveFilter>(archiveFilterProvider, (prev, next) {
      if (prev != next) {
        _loadArchive();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(isMultiSelect, selectedIds, filter, actionState),
      body: Column(
        children: [
          // ── Tab Bar ─────────────────────────────────────────
          _buildTabBar(),

          // ── Search Bar ──────────────────────────────────────
          if (_showSearch) _buildSearchBar(),

          // ── Multi-select action bar ─────────────────────────
          if (isMultiSelect)
            _buildMultiSelectBar(selectedIds, actionState),

          // ── Content ─────────────────────────────────────────
          Expanded(
            child: _buildContent(
              archiveState,
              filteredItems,
              isMultiSelect,
              selectedIds,
            ),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ───────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(
    bool isMultiSelect,
    Set<int> selectedIds,
    ArchiveFilter filter,
    ArchiveActionState actionState,
  ) {
    if (isMultiSelect) {
      return AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitMultiSelect,
        ),
        title: Text(
          '${selectedIds.length} ${AppLocalizations.of(context)!.translate('select')}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _selectAll,
            child: Text(
              AppLocalizations.of(context)!.translate('selectAll'),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      );
    }

    final t = AppLocalizations.of(context)!;
    return AppBar(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0.5,
      title: Text(
        t.translate('archive'),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        // Search toggle
        IconButton(
          icon: Icon(
            _showSearch ? Icons.search_off : Icons.search,
            color: AppColors.textSecondary,
          ),
          onPressed: _toggleSearch,
          tooltip: t.translate('search'),
        ),

        // Filter button with badge
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.filter_list_rounded,
                color: AppColors.textSecondary,
              ),
              onPressed: () => ArchiveFilterSheet.show(context),
              tooltip: t.translate('filter'),
            ),
            if (filter.activeFilterCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${filter.activeFilterCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Export button
        IconButton(
          icon: actionState.isExporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              : const Icon(
                  Icons.file_download_outlined,
                  color: AppColors.textSecondary,
                ),
          onPressed: actionState.isExporting ? null : _exportArchive,
          tooltip: t.translate('export'),
        ),
      ],
    );
  }

  // ─── Tab Bar ───────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        dividerColor: AppColors.divider,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tabs: _visibleTypes.map((type) {
          return Tab(text: AppLocalizations.of(context)!.translate(type.labelKey));
        }).toList(),
      ),
    );
  }

  // ─── Search Bar ────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.translate('archive_search_hint'),
          hintStyle: const TextStyle(
            color: AppColors.inputHint,
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.textHint),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceVariant,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ─── Multi-select Action Bar ───────────────────────────────────────

  Widget _buildMultiSelectBar(
    Set<int> selectedIds,
    ArchiveActionState actionState,
  ) {
    return Container(
      color: AppColors.primarySurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Builder(
        builder: (context) {
          final t = AppLocalizations.of(context)!;
          return Row(
            children: [
              _ActionChip(
                icon: Icons.delete_outline,
                label: t.translate('delete'),
                color: AppColors.error,
                isLoading: actionState.isDeleting,
                onTap: selectedIds.isNotEmpty ? _deleteSelected : null,
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.cancel_outlined,
                label: t.translate('cancel'),
                color: AppColors.warning,
                isLoading: actionState.isCancelling,
                onTap: selectedIds.isNotEmpty ? _cancelPendingSelected : null,
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.restore,
                label: t.translate('restore'),
                color: AppColors.success,
                isLoading: actionState.isRestoring,
                onTap: selectedIds.isNotEmpty ? _restoreSelected : null,
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.file_download_outlined,
                label: t.translate('export'),
                color: AppColors.info,
                isLoading: actionState.isExporting,
                onTap: _exportArchive,
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Content ───────────────────────────────────────────────────────

  Widget _buildContent(
    ArchiveListState state,
    List<ArchiveItem> filteredItems,
    bool isMultiSelect,
    Set<int> selectedIds,
  ) {
    // Initial loading
    if (state.isLoading && !state.hasLoadedOnce) {
      return AppLoading.listShimmer(itemCount: 6, itemHeight: 110);
    }

    // Error state
    if (state.hasError && state.items.isEmpty) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: _loadArchive,
      );
    }

    // Empty state
    if (state.isEmpty && filteredItems.isEmpty) {
      final t = AppLocalizations.of(context)!;
      return AppEmptyState(
        icon: Icons.archive_outlined,
        title: t.translate('noMessages'),
        description: t.translate('archive_no_messages_in'),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: filteredItems.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading more indicator
          if (index >= filteredItems.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            );
          }

          final item = filteredItems[index];
          return ArchiveItemCard(
            item: item,
            isMultiSelectMode: isMultiSelect,
            isSelected: selectedIds.contains(item.id),
            onTap: () {
              // Could navigate to message detail here.
            },
            onLongPress: () {
              if (!isMultiSelect) {
                _enterMultiSelect(item.id);
              }
            },
            onToggleSelect: () => _toggleItemSelection(item.id),
            onDismissed: () {
              ref.read(archiveActionsProvider.notifier).deleteMessages(
                    archiveType: ref.read(archiveSelectedTabProvider),
                    messageIds: [item.id],
                    listNotifier: ref.read(archiveListProvider.notifier),
                  );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Chip (multi-select bar)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    this.isLoading = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              else
                Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
