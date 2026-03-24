import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/balance/presentation/controllers/balance_controller.dart';
import 'package:orbit_app/features/balance/presentation/widgets/transaction_card.dart';

/// Balance Log tab content.
///
/// Displays the full transaction history with:
/// - Search field
/// - Date range filter
/// - Status filter chips
/// - Transaction list with infinite scroll
class BalanceLogTab extends ConsumerStatefulWidget {
  const BalanceLogTab({super.key});

  @override
  ConsumerState<BalanceLogTab> createState() => _BalanceLogTabState();
}

class _BalanceLogTabState extends ConsumerState<BalanceLogTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionsControllerProvider.notifier).loadTransactions();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(transactionsControllerProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref
          .read(transactionsControllerProvider.notifier)
          .searchTransactions(query);
    });
  }

  Future<void> _onRefresh() async {
    await ref
        .read(transactionsControllerProvider.notifier)
        .loadTransactions();
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final dateFormat = DateFormat('yyyy-MM-dd');
      ref.read(transactionsControllerProvider.notifier).setDateRange(
            dateFormat.format(picked.start),
            dateFormat.format(picked.end),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(transactionsControllerProvider);
    final t = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Search and filters
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              // Search + date filter row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: t.translate('searchLog'),
                        hintStyle: const TextStyle(
                          color: AppColors.inputHint,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textHint,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.scaffoldBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Date filter button
                  Material(
                    color: AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _showDateRangePicker,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.date_range_outlined,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Export button
                  Material(
                    color: AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        // Export functionality placeholder
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(t.translate('exportData')),
                            backgroundColor: AppColors.info,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.file_download_outlined,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status filter chips
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip(
                      t.translate('all'),
                      null,
                      state.statusFilter,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      t.translate('accepted'),
                      'approved',
                      state.statusFilter,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      t.translate('statusPending'),
                      'pending',
                      state.statusFilter,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      t.translate('rejected'),
                      'rejected',
                      state.statusFilter,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      t.translate('expired'),
                      'expired',
                      state.statusFilter,
                    ),
                  ],
                ),
              ),

              // Date range info
              if (state.dateFrom != null || state.dateTo != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.date_range,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${state.dateFrom ?? ''} - ${state.dateTo ?? ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(transactionsControllerProvider.notifier)
                            .setDateRange(null, null);
                      },
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],

              // Total count
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${state.total} ${t.translate('transactionCount')}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Transaction list
        Expanded(
          child: state.isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary),
                )
              : state.error != null && state.transactions.isEmpty
                  ? _buildErrorState(state.error!)
                  : state.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _onRefresh,
                          color: AppColors.primary,
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: state.transactions.length +
                                (state.hasMore ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              if (index >= state.transactions.length) {
                                return const Center(
                                  child: Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 16),
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                );
                              }

                              final transaction =
                                  state.transactions[index];
                              return TransactionCard(
                                transaction: transaction,
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    String? statusValue,
    String? currentFilter,
  ) {
    final isActive = currentFilter == statusValue;

    return GestureDetector(
      onTap: () {
        ref
            .read(transactionsControllerProvider.notifier)
            .setStatusFilter(statusValue);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
                Icons.receipt_long_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.translate('noTransactionsFound'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.translate('noTransactionsMatchFound'),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.translate('retry')),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
