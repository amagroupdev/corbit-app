import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/balance/data/datasources/balance_remote_datasource.dart';

/// Async list of `/balance/upgrade-levels`.
final _upgradeLevelsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final ds = ref.watch(balanceRemoteDatasourceProvider);
  return ds.getUpgradeLevels();
});

class UpgradeLevelsScreen extends ConsumerWidget {
  const UpgradeLevelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final asyncList = ref.watch(_upgradeLevelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t?.translate('upgradeLevelsTitle') ?? 'Upgrade levels'),
      ),
      body: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(e.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (levels) {
          if (levels.isEmpty) {
            return Center(child: Text(t?.translate('noData') ?? 'No data'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_upgradeLevelsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: levels.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _LevelCard(data: levels[index], t: t),
            ),
          );
        },
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.data, this.t});
  final Map<String, dynamic> data;
  final AppLocalizations? t;

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? data['title'] ?? '').toString();
    final isCurrent = data['is_current'] == true ||
        data['current'] == true ||
        data['active'] == true;
    final price = data['price']?.toString() ?? '';
    final benefits = (data['benefits'] is List)
        ? (data['benefits'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.primarySurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? AppColors.primary : AppColors.primaryBorder,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isCurrent ? AppColors.primary : null,
                  ),
                ),
              ),
              if (isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t?.translate('upgradeLevelCurrent') ?? 'Current',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
          if (price.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              price,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.primary),
            ),
          ],
          if (benefits.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              t?.translate('upgradeLevelBenefits') ?? 'Benefits',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            for (final b in benefits)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(b)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
