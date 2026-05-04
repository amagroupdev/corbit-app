import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/transfer_subaccounts/data/models/subaccount_transfer_model.dart';
import 'package:orbit_app/features/transfer_subaccounts/data/repositories/subaccount_transfer_repository.dart';

/// Async history of `/transfer/subaccounts/history`.
final _subaccountHistoryProvider =
    FutureProvider.autoDispose<List<SubaccountTransferModel>>((ref) async {
  final repo = ref.watch(subaccountTransferRepositoryProvider);
  final result = await repo.getHistory();
  if (result.isFailure) {
    throw StateError(result.error ?? 'unexpectedError');
  }
  return result.data ?? const [];
});

class SubaccountHistoryScreen extends ConsumerWidget {
  const SubaccountHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final asyncList = ref.watch(_subaccountHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title:
            Text(t?.translate('subaccountTransferHistory') ?? 'Transfer history'),
      ),
      body: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              e.toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(t?.translate('noData') ?? 'No data'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_subaccountHistoryProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.swap_horiz,
                        color: AppColors.primary),
                    title: Text(
                      '${item.fromUsername} → ${item.toUsername}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(item.createdAt),
                    trailing: Text(
                      '${item.amount.toStringAsFixed(2)} SAR',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
