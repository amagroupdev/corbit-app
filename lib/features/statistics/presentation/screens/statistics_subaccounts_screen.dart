import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/statistics/data/repositories/statistics_repository.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';

/// Sub-accounts statistics screen — driven by `POST /statistics/subaccounts`.
///
/// Renders one card per sub-account with sent/delivered/failed counters and
/// the balance the sub-account has consumed. The screen is intentionally
/// read-only; CRUD on sub-accounts lives under Settings.
class StatisticsSubaccountsScreen extends ConsumerStatefulWidget {
  const StatisticsSubaccountsScreen({super.key});

  @override
  ConsumerState<StatisticsSubaccountsScreen> createState() =>
      _StatisticsSubaccountsScreenState();
}

class _StatisticsSubaccountsScreenState
    extends ConsumerState<StatisticsSubaccountsScreen> {
  List<SubaccountStat> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(statisticsRepositoryProvider);
      final result = await repo.getSubaccountsStats();
      if (!mounted) return;
      setState(() {
        _items = result;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(t.translate('statisticsSubaccountsTitle')),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _buildBody(t),
    );
  }

  Widget _buildBody(AppLocalizations t) {
    if (_loading) return AppLoading.listShimmer();
    if (_error != null) {
      return AppErrorWidget(message: _error!, onRetry: _load);
    }
    if (_items.isEmpty) {
      return AppEmptyState(
        icon: Icons.people_outline,
        title: t.translate('statisticsAllSubaccounts'),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _SubaccountCard(stat: _items[i]),
      ),
    );
  }
}

class _SubaccountCard extends StatelessWidget {
  const _SubaccountCard({required this.stat});

  final SubaccountStat stat;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stat.name.isEmpty ? '#${stat.id}' : stat.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Metric(
                label: t.translate('stat_sub_all'),
                value: stat.totalSent.toString(),
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              _Metric(
                label: t.translate('delivered'),
                value: stat.totalDelivered.toString(),
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              _Metric(
                label: t.translate('failed'),
                value: stat.totalFailed.toString(),
                color: AppColors.error,
              ),
            ],
          ),
          if (stat.balanceConsumed > 0) ...[
            const SizedBox(height: 10),
            Text(
              '${t.translate("consumed_balance")}: ${stat.balanceConsumed}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
