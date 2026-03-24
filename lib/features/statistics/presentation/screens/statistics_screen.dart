import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/statistics/data/models/statistics_model.dart';
import 'package:orbit_app/features/statistics/presentation/controllers/statistics_controller.dart';
import 'package:orbit_app/features/statistics/presentation/widgets/statistics_card.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';

/// Main statistics screen with tabs for absence/lateness, custom messages,
/// and teacher messages. Includes sub-type filters, date range picker,
/// semester/group selectors, and export functionality.
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: StatisticsType.values.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);

    // Load initial data.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatistics();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    final type = StatisticsType.values[_tabController.index];
    ref.read(statisticsSelectedTabProvider.notifier).state = type;
    // Reset sub-type when switching tabs.
    ref.read(statisticsSubTypeProvider.notifier).state = 'all';
    _loadStatistics();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadStatistics() {
    final type = ref.read(statisticsSelectedTabProvider);
    final filter = _buildFilter();
    ref.read(statisticsListProvider.notifier).fetchStatistics(
          statisticsType: type,
          filter: filter,
        );
  }

  void _loadMore() {
    final type = ref.read(statisticsSelectedTabProvider);
    final filter = _buildFilter();
    ref.read(statisticsListProvider.notifier).loadMore(
          statisticsType: type,
          filter: filter,
        );
  }

  Future<void> _onRefresh() async {
    final type = ref.read(statisticsSelectedTabProvider);
    final filter = _buildFilter();
    await ref.read(statisticsListProvider.notifier).refresh(
          statisticsType: type,
          filter: filter,
        );
  }

  StatisticsFilter _buildFilter() {
    final baseFilter = ref.read(statisticsFilterProvider);
    final subType = ref.read(statisticsSubTypeProvider);
    return baseFilter.copyWith(
      subTypeValue: subType == 'all' ? null : subType,
      clearSubType: subType == 'all',
    );
  }

  void _onSubTypeChanged(String value) {
    ref.read(statisticsSubTypeProvider.notifier).state = value;
    _loadStatistics();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final filter = ref.read(statisticsFilterProvider);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: filter.fromDate != null && filter.toDate != null
          ? DateTimeRange(start: filter.fromDate!, end: filter.toDate!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 30)), end: now),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(statisticsFilterProvider.notifier).state =
          ref.read(statisticsFilterProvider).copyWith(
                fromDate: picked.start,
                toDate: picked.end,
              );
      _loadStatistics();
    }
  }

  void _clearDateRange() {
    ref.read(statisticsFilterProvider.notifier).state =
        ref.read(statisticsFilterProvider).copyWith(
              clearFromDate: true,
              clearToDate: true,
            );
    _loadStatistics();
  }

  Future<void> _exportStatistics() async {
    final type = ref.read(statisticsSelectedTabProvider);
    final filter = _buildFilter();

    final result =
        await ref.read(statisticsExportProvider.notifier).exportStatistics(
              statisticsType: type,
              filter: filter,
            );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result ??
                AppLocalizations.of(context)!.translate('stat_export_requested'),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(statisticsListProvider);
    final selectedTab = ref.watch(statisticsSelectedTabProvider);
    final filter = ref.watch(statisticsFilterProvider);
    final selectedSubType = ref.watch(statisticsSubTypeProvider);
    final exportState = ref.watch(statisticsExportProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(exportState),
      body: Column(
        children: [
          // ── Tab Bar ─────────────────────────────────────────
          _buildTabBar(),

          // ── Filters Bar ─────────────────────────────────────
          _buildFiltersBar(selectedTab, selectedSubType, filter),

          // ── Content ─────────────────────────────────────────
          Expanded(
            child: _buildContent(listState, selectedTab),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ───────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(AsyncValue<String?> exportState) {
    return AppBar(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0.5,
      title: Text(
        AppLocalizations.of(context)!.translate('statistics'),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        // Export button
        IconButton(
          icon: exportState.isLoading
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
          onPressed: exportState.isLoading ? null : _exportStatistics,
          tooltip: AppLocalizations.of(context)!.translate('export'),
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
        isScrollable: false,
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
        tabs: StatisticsType.values.map((type) {
          return Tab(text: AppLocalizations.of(context)!.translate(type.labelKey));
        }).toList(),
      ),
    );
  }

  // ─── Filters Bar ───────────────────────────────────────────────────

  Widget _buildFiltersBar(
    StatisticsType selectedTab,
    String selectedSubType,
    StatisticsFilter filter,
  ) {
    final dateFormat = DateFormat('MM/dd');
    final hasDateFilter = filter.fromDate != null || filter.toDate != null;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        children: [
          // ── Sub-type filter chips ──────────────────────────
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: selectedTab.subTypes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final subType = selectedTab.subTypes[index];
                final isActive = selectedSubType == subType.apiValue;

                return ChoiceChip(
                  label: Text(AppLocalizations.of(context)!.translate(subType.labelKey)),
                  selected: isActive,
                  onSelected: (_) => _onSubTypeChanged(subType.apiValue),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceVariant,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActive ? Colors.white : AppColors.textPrimary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color:
                          isActive ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // ── Date range + semester row ──────────────────────
          Row(
            children: [
              // Date range button
              Expanded(
                child: InkWell(
                  onTap: _pickDateRange,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: hasDateFilter
                          ? AppColors.primarySurface
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasDateFilter
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.date_range_outlined,
                          size: 18,
                          color: hasDateFilter
                              ? AppColors.primary
                              : AppColors.textHint,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            hasDateFilter
                                ? '${filter.fromDate != null ? dateFormat.format(filter.fromDate!) : '...'} - ${filter.toDate != null ? dateFormat.format(filter.toDate!) : '...'}'
                                : AppLocalizations.of(context)!.translate('stat_select_period'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: hasDateFilter
                                  ? AppColors.primary
                                  : AppColors.textHint,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasDateFilter)
                          GestureDetector(
                            onTap: _clearDateRange,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Semester dropdown
              _SemesterDropdown(
                value: filter.semester,
                onChanged: (semester) {
                  ref.read(statisticsFilterProvider.notifier).state =
                      filter.copyWith(
                    semester: semester,
                    clearSemester: semester == null,
                  );
                  _loadStatistics();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Content ───────────────────────────────────────────────────────

  Widget _buildContent(
    StatisticsListState state,
    StatisticsType selectedTab,
  ) {
    // Initial loading
    if (state.isLoading && !state.hasLoadedOnce) {
      return AppLoading.listShimmer(itemCount: 5, itemHeight: 140);
    }

    // Error state
    if (state.hasError && state.items.isEmpty) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: _loadStatistics,
      );
    }

    // Empty state
    if (state.isEmpty) {
      final t = AppLocalizations.of(context)!;
      return AppEmptyState(
        icon: Icons.analytics_outlined,
        title: t.translate('stat_no_statistics'),
        description: t.translate('stat_no_data_in'),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: Column(
        children: [
          // ── Summary header ─────────────────────────────────
          _buildSummaryHeader(state),

          // ── List ───────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 4, bottom: 80),
              itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Loading more indicator
                if (index >= state.items.length) {
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

                final item = state.items[index];
                return StatisticsCard(
                  item: item,
                  statisticsType: selectedTab,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Summary Header ────────────────────────────────────────────────

  Widget _buildSummaryHeader(StatisticsListState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primarySurface, AppColors.surface],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.summarize_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.translateWithParams('stat_total_results', {'count': '${state.total}'}),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          Text(
            AppLocalizations.of(context)!.translateWithParams('stat_page_info', {'current': '${state.currentPage}', 'last': '${state.lastPage}'}),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Semester Dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _SemesterDropdown extends StatelessWidget {
  const _SemesterDropdown({
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  static const List<_SemesterOption> _semesters = [
    _SemesterOption(value: null, labelKey: 'stat_semester'),
    _SemesterOption(value: '1', labelKey: 'stat_semester_first'),
    _SemesterOption(value: '2', labelKey: 'stat_semester_second'),
    _SemesterOption(value: '3', labelKey: 'stat_semester_third'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: value != null
            ? AppColors.primarySurface
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value != null ? AppColors.primary : AppColors.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: value != null ? AppColors.primary : AppColors.textHint,
          ),
          isDense: true,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: value != null ? AppColors.primary : AppColors.textHint,
          ),
          items: _semesters.map((semester) {
            return DropdownMenuItem<String?>(
              value: semester.value,
              child: Builder(
                builder: (ctx) => Text(
                  AppLocalizations.of(ctx)!.translate(semester.labelKey),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SemesterOption {
  const _SemesterOption({required this.value, required this.labelKey});
  final String? value;
  final String labelKey;
}
