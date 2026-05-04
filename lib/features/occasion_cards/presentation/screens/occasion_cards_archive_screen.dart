import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/occasion_cards/data/models/occasion_card_model.dart';
import 'package:orbit_app/features/occasion_cards/data/repositories/occasion_cards_repository.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';

/// Standalone archive screen listing previously sent occasion cards.
///
/// Independent of the legacy two-tab `OccasionCardsScreen` so the archive
/// can be reached directly from a deep link or settings entry.
class OccasionCardsArchiveScreen extends ConsumerStatefulWidget {
  const OccasionCardsArchiveScreen({super.key});

  @override
  ConsumerState<OccasionCardsArchiveScreen> createState() =>
      _OccasionCardsArchiveScreenState();
}

class _OccasionCardsArchiveScreenState
    extends ConsumerState<OccasionCardsArchiveScreen> {
  PaginatedResponse<OccasionCardModel>? _archive;
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
      final repo = ref.read(occasionCardsRepositoryProvider);
      final result = await repo.getArchive();
      if (!mounted) return;
      setState(() {
        _archive = result;
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
        title: Text(t.translate('occasionCardsArchiveTitle')),
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
    final archive = _archive;
    if (archive == null || archive.data.isEmpty) {
      return AppEmptyState(
        icon: Icons.card_giftcard_outlined,
        title: t.translate('noSentCards'),
      );
    }

    final dateFormat = intl.DateFormat('yyyy/MM/dd HH:mm');
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: archive.data.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final card = archive.data[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.templateName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${card.recipientCount} ${t.translate("recipientUnit")} • ${dateFormat.format(card.createdAt)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
