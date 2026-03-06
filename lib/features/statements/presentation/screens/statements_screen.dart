import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/statements/data/models/statement_response_model.dart';
import 'package:orbit_app/features/statements/presentation/controllers/statements_controller.dart';
import 'package:orbit_app/features/statements/presentation/widgets/statement_card.dart';
import 'package:orbit_app/features/statements/presentation/widgets/statements_filter.dart';
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
    final confirmed = await _showConfirmDialog(
      title: '\u062D\u0630\u0641 \u0627\u0644\u0631\u062F', // حذف الرد
      message:
          '\u0647\u0644 \u0623\u0646\u062A \u0645\u062A\u0623\u0643\u062F \u0645\u0646 \u062D\u0630\u0641 \u0647\u0630\u0627 \u0627\u0644\u0631\u062F\u061F', // هل أنت متأكد من حذف هذا الرد؟
    );
    if (confirmed != true) return;

    final success = await ref.read(statementsActionsProvider.notifier).deleteResponses(
          responseIds: [item.id],
          listNotifier: ref.read(statementsListProvider.notifier),
        );

    if (success && mounted) {
      _showSnackBar('\u062A\u0645 \u062D\u0630\u0641 \u0627\u0644\u0631\u062F \u0628\u0646\u062C\u0627\u062D'); // تم حذف الرد بنجاح
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
      _showSnackBar('\u062A\u0645 \u0637\u0644\u0628 \u062A\u0635\u062F\u064A\u0631 \u0627\u0644\u0631\u062F\u0648\u062F \u0628\u0646\u062C\u0627\u062D'); // تم طلب تصدير الردود بنجاح
    }
  }

  void _viewMessage(StatementResponseItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '\u0627\u0644\u0631\u0633\u0627\u0644\u0629', // الرسالة
          style: TextStyle(
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
              const Text(
                '\u0646\u0635 \u0627\u0644\u0631\u062F:', // نص الرد:
                style: TextStyle(
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
                const Text(
                  '\u0627\u0644\u0631\u0633\u0627\u0644\u0629 \u0627\u0644\u0623\u0635\u0644\u064A\u0629:', // الرسالة الأصلية:
                  style: TextStyle(
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
            child: const Text(
              '\u0625\u063A\u0644\u0627\u0642', // إغلاق
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
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
            child: const Text(
              '\u0625\u0644\u063A\u0627\u0621', // إلغاء
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              '\u062A\u0623\u0643\u064A\u062F', // تأكيد
              style: TextStyle(
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
      title: const Text(
        '\u0627\u0644\u0625\u0641\u0627\u062F\u0627\u062A \u0648\u0627\u0644\u0631\u062F\u0648\u062F', // الإفادات والردود
        style: TextStyle(
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
          tooltip: '\u0628\u062D\u062B', // بحث
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
              tooltip: '\u062A\u0635\u0641\u064A\u0629', // تصفية
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
          tooltip: '\u062A\u0635\u062F\u064A\u0631 \u0627\u0644\u0631\u062F\u0648\u062F', // تصدير الردود
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
      child: const Text(
        '\u0627\u0633\u062A\u0639\u0631\u0636 \u0631\u0633\u0627\u0626\u0644 \u0631\u062F\u0648\u062F \u0627\u0644\u0645\u0633\u062A\u062E\u062F\u0645\u064A\u0646 \u0639\u0644\u0649 \u0627\u0644\u0631\u0633\u0627\u0626\u0644 \u0627\u0644\u0645\u0631\u0633\u0644\u0629.', // استعرض رسائل ردود المستخدمين على الرسائل المرسلة.
        style: TextStyle(
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
          return Tab(text: type.labelAr);
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
          hintText: '\u0628\u062D\u062B \u0641\u064A \u0627\u0644\u0625\u0641\u0627\u062F\u0627\u062A \u0648\u0627\u0644\u0631\u062F\u0648\u062F...', // بحث في الإفادات والردود...
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
      final tab = ref.read(statementsSelectedTabProvider);
      return AppEmptyState(
        icon: Icons.question_answer_outlined,
        title: '\u0644\u0627 \u062A\u0648\u062C\u062F \u0631\u062F\u0648\u062F', // لا توجد ردود
        description:
            '\u0644\u0627 \u062A\u0648\u062C\u062F \u0631\u062F\u0648\u062F \u0641\u064A ${tab.labelAr}', // لا توجد ردود في X
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
