import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/statements/data/models/statement_response_model.dart';
import 'package:orbit_app/features/statements/presentation/controllers/statements_controller.dart';
import 'package:orbit_app/features/statements/presentation/widgets/statement_card.dart';
import 'package:orbit_app/features/statements/presentation/widgets/statements_filter.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';

/// Main statements & responses screen with scrollable tab bar, filter, search,
/// infinite scroll list, and action buttons.
class StatementsScreen extends ConsumerStatefulWidget {
  const StatementsScreen({super.key});

  @override
  ConsumerState<StatementsScreen> createState() => _StatementsScreenState();
}

class _StatementsScreenState extends ConsumerState<StatementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: StatementType.values.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);

    // Load initial data.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatements();
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
    final type = StatementType.values[_tabController.index];
    ref.read(statementsSelectedTabProvider.notifier).state = type;
    _loadStatements();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadStatements() {
    final type = ref.read(statementsSelectedTabProvider);
    final filter = ref.read(statementsFilterProvider);
    ref.read(statementsListProvider.notifier).fetchStatements(
          statementType: type,
          filter: filter,
        );
  }

  void _loadMore() {
    final type = ref.read(statementsSelectedTabProvider);
    final filter = ref.read(statementsFilterProvider);
    ref.read(statementsListProvider.notifier).loadMore(
          statementType: type,
          filter: filter,
        );
  }

  Future<void> _onRefresh() async {
    final type = ref.read(statementsSelectedTabProvider);
    final filter = ref.read(statementsFilterProvider);
    await ref.read(statementsListProvider.notifier).refresh(
          statementType: type,
          filter: filter,
        );
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        ref.read(statementsSearchQueryProvider.notifier).state = '';
      }
    });
  }

  void _onSearchChanged(String query) {
    ref.read(statementsSearchQueryProvider.notifier).state = query;
  }

  // ─── Actions ───────────────────────────────────────────────────────

  Future<void> _deleteItem(StatementResponseItem item) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await _showConfirmDialog(
      title: t.translate('statement_delete_title'),
      message: t.translate('statement_confirm_delete'),
    );
    if (confirmed != true) return;

    final success = await ref.read(statementsActionsProvider.notifier).deleteResponses(
          responseIds: [item.id],
          listNotifier: ref.read(statementsListProvider.notifier),
        );

    if (success && mounted) {
      _showSnackBar(t.translate('statement_deleted'));
    }
  }

  Future<void> _exportStatements() async {
    final type = ref.read(statementsSelectedTabProvider);
    final filter = ref.read(statementsFilterProvider);
    await ref.read(statementsActionsProvider.notifier).exportStatements(
          statementType: type,
          filter: filter,
        );

    if (mounted) {
      _showSnackBar(AppLocalizations.of(context)!.translate('statement_export_requested'));
    }
  }

  void _viewMessage(StatementResponseItem item) {
    showDialog(
      context: context,
      builder: (ctx) {
        final t = AppLocalizations.of(context)!;
        return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t.translate('message'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Response text
              Text(
                t.translate('statement_response_text'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.responseText,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
              if (item.messageBody != null && item.messageBody!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  t.translate('statement_original_message'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.messageBody!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              t.translate('close'),
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      );
      },
    );
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
    final statementsState = ref.watch(statementsListProvider);
    final filteredItems = ref.watch(filteredStatementsItemsProvider);
    final filter = ref.watch(statementsFilterProvider);
    final actionState = ref.watch(statementsActionsProvider);

    // Listen for filter changes and reload.
    ref.listen<StatementFilter>(statementsFilterProvider, (prev, next) {
      if (prev != next) {
        _loadStatements();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(filter, actionState),
      body: Column(
        children: [
          // ── Description ──────────────────────────────────────
          _buildDescription(),

          // ── Tab Bar ─────────────────────────────────────────
          _buildTabBar(),

          // ── Search Bar ──────────────────────────────────────
          if (_showSearch) _buildSearchBar(),

          // ── Content ─────────────────────────────────────────
          Expanded(
            child: _buildContent(
              statementsState,
              filteredItems,
            ),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ───────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(
    StatementFilter filter,
    StatementsActionState actionState,
  ) {
    return AppBar(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0.5,
      title: Text(
        AppLocalizations.of(context)!.translate('statements'),
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
          tooltip: AppLocalizations.of(context)!.translate('search'),
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
              onPressed: () => StatementsFilterSheet.show(context),
              tooltip: AppLocalizations.of(context)!.translate('filter'),
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
          onPressed: actionState.isExporting ? null : _exportStatements,
          tooltip: AppLocalizations.of(context)!.translate('exportResponses'),
        ),
      ],
    );
  }

  // ─── Description ─────────────────────────────────────────────────

  Widget _buildDescription() {
    return Container(
      color: AppColors.surface,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        AppLocalizations.of(context)!.translate('statementsDescription'),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
      ),
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
        tabs: StatementType.values.map((type) {
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
          hintText: AppLocalizations.of(context)!.translate('statement_search_hint'),
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

  // ─── Content ───────────────────────────────────────────────────────

  Widget _buildContent(
    StatementsListState state,
    List<StatementResponseItem> filteredItems,
  ) {
    // Initial loading
    if (state.isLoading && !state.hasLoadedOnce) {
      return AppLoading.listShimmer(itemCount: 6, itemHeight: 130);
    }

    // Error state
    if (state.hasError && state.items.isEmpty) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: _loadStatements,
      );
    }

    // Empty state
    if (state.isEmpty && filteredItems.isEmpty) {
      final t = AppLocalizations.of(context)!;
      return AppEmptyState(
        icon: Icons.question_answer_outlined,
        title: t.translate('statement_no_responses'),
        description: t.translate('statement_no_responses_in'),
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
          return StatementCard(
            item: item,
            onTap: () => _viewMessage(item),
            onDelete: () => _deleteItem(item),
            onExport: _exportStatements,
            onViewMessage: () => _viewMessage(item),
            onDismissed: () {
              ref.read(statementsActionsProvider.notifier).deleteResponses(
                    responseIds: [item.id],
                    listNotifier: ref.read(statementsListProvider.notifier),
                  );
            },
          );
        },
      ),
    );
  }
}
