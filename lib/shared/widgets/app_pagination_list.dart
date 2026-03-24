import 'package:flutter/material.dart';
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';

/// Status of the paginated list data.
enum PaginationStatus {
  /// Initial state, nothing loaded yet.
  initial,

  /// Currently loading the first page.
  loading,

  /// Data loaded successfully, may have more pages.
  loaded,

  /// Currently loading the next page (indicator at bottom).
  loadingMore,

  /// An error occurred.
  error,

  /// All pages have been loaded.
  complete,
}

/// A generic paginated list view with infinite scroll, pull-to-refresh,
/// empty state, error state, and bottom loading indicator.
///
/// Usage:
/// ```dart
/// AppPaginationList<Message>(
///   items: messages,
///   status: status,
///   onLoadMore: () => ref.read(messagesProvider.notifier).loadMore(),
///   onRefresh: () => ref.read(messagesProvider.notifier).refresh(),
///   itemBuilder: (context, message, index) => MessageTile(message: message),
///   emptyIcon: Icons.mail_outlined,
///   emptyTitle: 'No messages',
/// )
/// ```
class AppPaginationList<T> extends StatefulWidget {
  const AppPaginationList({
    required this.items,
    required this.status,
    required this.onLoadMore,
    required this.onRefresh,
    required this.itemBuilder,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyTitle,
    this.emptyDescription,
    this.emptyActionText,
    this.onEmptyAction,
    this.errorMessage,
    this.separatorBuilder,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.scrollController,
    this.loadMoreThreshold = 200,
    this.physics,
    this.header,
    super.key,
  });

  /// The current list of loaded items.
  final List<T> items;

  /// Current pagination status.
  final PaginationStatus status;

  /// Called when the user scrolls near the bottom.
  final VoidCallback onLoadMore;

  /// Called on pull-to-refresh. Should return a [Future] that completes
  /// when data is reloaded.
  final Future<void> Function() onRefresh;

  /// Builds a single list item.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Icon for the empty state.
  final IconData emptyIcon;

  /// Title for the empty state.
  final String? emptyTitle;

  /// Optional description for the empty state.
  final String? emptyDescription;

  /// Action button text for empty state.
  final String? emptyActionText;

  /// Action callback for empty state.
  final VoidCallback? onEmptyAction;

  /// Error message when status is [PaginationStatus.error].
  final String? errorMessage;

  /// Optional separator between items.
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// List padding.
  final EdgeInsetsGeometry padding;

  /// External scroll controller.
  final ScrollController? scrollController;

  /// How many pixels from the bottom to trigger [onLoadMore].
  final double loadMoreThreshold;

  /// Scroll physics override.
  final ScrollPhysics? physics;

  /// An optional fixed header widget above the list items.
  final Widget? header;

  @override
  State<AppPaginationList<T>> createState() => _AppPaginationListState<T>();
}

class _AppPaginationListState<T> extends State<AppPaginationList<T>> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    if (maxScroll - currentScroll <= widget.loadMoreThreshold) {
      if (widget.status == PaginationStatus.loaded) {
        widget.onLoadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Initial Loading ──────────────────────────────────────
    if (widget.status == PaginationStatus.initial ||
        widget.status == PaginationStatus.loading) {
      return AppLoading.listShimmer();
    }

    // ── Error (no items loaded) ──────────────────────────────
    if (widget.status == PaginationStatus.error && widget.items.isEmpty) {
      return AppErrorWidget(
        message: widget.errorMessage ??
            AppLocalizations.instance.translate('loadingError'),
        onRetry: () => widget.onRefresh(),
      );
    }

    // ── Empty ────────────────────────────────────────────────
    if (widget.items.isEmpty &&
        (widget.status == PaginationStatus.loaded ||
            widget.status == PaginationStatus.complete)) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: widget.onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              child: AppEmptyState(
                icon: widget.emptyIcon,
                title: widget.emptyTitle ?? AppLocalizations.instance.translate('noData'),
                description: widget.emptyDescription,
                actionText: widget.emptyActionText,
                onAction: widget.onEmptyAction,
              ),
            ),
          ],
        ),
      );
    }

    // ── Data List ────────────────────────────────────────────
    final itemCount = widget.items.length + _extraItemCount;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: widget.onRefresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
        padding: widget.padding,
        itemCount: itemCount,
        separatorBuilder: widget.separatorBuilder ??
            (_, __) => const SizedBox(height: 0),
        itemBuilder: (context, index) {
          // Header
          if (widget.header != null && index == 0) {
            return widget.header!;
          }

          final dataIndex = widget.header != null ? index - 1 : index;

          // Items
          if (dataIndex < widget.items.length) {
            return widget.itemBuilder(
              context,
              widget.items[dataIndex],
              dataIndex,
            );
          }

          // Bottom loading / error indicator
          return _buildBottomIndicator();
        },
      ),
    );
  }

  int get _extraItemCount {
    int count = 0;
    if (widget.header != null) count++;
    if (widget.status == PaginationStatus.loadingMore ||
        (widget.status == PaginationStatus.error &&
            widget.items.isNotEmpty)) {
      count++;
    }
    return count;
  }

  Widget _buildBottomIndicator() {
    if (widget.status == PaginationStatus.loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
      );
    }

    if (widget.status == PaginationStatus.error &&
        widget.items.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: TextButton.icon(
            onPressed: widget.onLoadMore,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            label: Text(
              AppLocalizations.instance.translate('retry'),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
