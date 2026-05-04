import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/drafts/data/models/draft_model.dart';
import 'package:orbit_app/features/drafts/presentation/controllers/drafts_controller.dart';
import 'package:orbit_app/features/drafts/presentation/widgets/draft_card.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';

/// Top-level Drafts list screen.
///
/// Reads from [draftsListControllerProvider] and renders:
/// - skeleton loader on first load
/// - error state with retry
/// - empty state with a hint to compose a message
/// - paginated list of [DraftCard]s with pull-to-refresh and infinite scroll
class DraftsScreen extends ConsumerStatefulWidget {
  const DraftsScreen({super.key});

  @override
  ConsumerState<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends ConsumerState<DraftsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(draftsListControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _confirmDelete(DraftModel draft) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.translate('draftDelete')),
        content: Text(t.translate('draftConfirmDelete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(t.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok =
        await ref.read(draftsListControllerProvider.notifier).deleteDraft(draft.id);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? t.translate('draftDeleted') : t.translate('draftSaveFailed'),
          style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openDraft(DraftModel draft) {
    context.pushNamed(
      'draftDetail',
      pathParameters: {'id': draft.id.toString()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final state = ref.watch(draftsListControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.translate('draftsTitle')),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(t, state),
    );
  }

  Widget _buildBody(AppLocalizations t, DraftsListState state) {
    if (state.isLoading) {
      return AppLoading.listShimmer();
    }

    if (state.errorMessage != null && state.drafts.isEmpty) {
      return AppErrorWidget(
        message: t.translate('draftLoadFailed'),
        onRetry: () =>
            ref.read(draftsListControllerProvider.notifier).refresh(),
      );
    }

    if (state.drafts.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(draftsListControllerProvider.notifier).refresh(),
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: AppEmptyState(
                icon: Icons.bookmark_border_rounded,
                title: t.translate('draftEmpty'),
                description: t.translate('draftEmptyDescription'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(draftsListControllerProvider.notifier).refresh(),
      color: AppColors.primary,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: state.drafts.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= state.drafts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            );
          }

          final draft = state.drafts[index];
          return DraftCard(
            draft: draft,
            onTap: () => _openDraft(draft),
            onDelete: () => _confirmDelete(draft),
          );
        },
      ),
    );
  }
}
