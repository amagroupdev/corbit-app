import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/notifications/data/models/notification_model.dart';
import 'package:orbit_app/features/notifications/data/repositories/notifications_repository.dart';
import 'package:orbit_app/features/notifications/presentation/widgets/notification_card.dart';
import 'package:orbit_app/routing/route_names.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_search_bar.dart';

/// Screen displaying the push notification archive with send action.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _searchQuery = '';
  int _currentPage = 1;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNotifications();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh || _isLoading) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final repository = ref.read(notificationsRepositoryProvider);
      final result = await repository.getArchive(
        page: 1,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (mounted) {
        setState(() {
          _notifications = result.data;
          _hasMore = result.hasMore;
          _currentPage = result.currentPage;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final repository = ref.read(notificationsRepositoryProvider);
      final result = await repository.getArchive(
        page: _currentPage + 1,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (mounted) {
        setState(() {
          _notifications.addAll(result.data);
          _hasMore = result.hasMore;
          _currentPage = result.currentPage;
          _isLoadingMore = false;
        });
      }
    } on ApiException {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _loadNotifications(refresh: true);
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.translate('deleteNotification'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          AppLocalizations.of(context)!.translate('confirmDeleteNotification'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppLocalizations.of(context)!.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(notificationsRepositoryProvider);
      await repository.deleteArchiveItem(notification.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('notificationDeleted')),
            backgroundColor: AppColors.success,
          ),
        );
        _loadNotifications(refresh: true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('notifications')),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () async {
              try {
                final repo = ref.read(notificationsRepositoryProvider);
                await repo.exportArchive();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.translate('exportingData')),
                      backgroundColor: AppColors.info,
                    ),
                  );
                }
              } on ApiException catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            tooltip: AppLocalizations.of(context)!.translate('export'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSearchBar(
              hint: AppLocalizations.of(context)!.translate('searchNotifications'),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.sendNotification),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.send_rounded, color: Colors.white),
        label: Text(
          AppLocalizations.of(context)!.translate('sendButton'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return AppLoading.listShimmer();

    if (_errorMessage != null) {
      return AppErrorWidget(
        message: _errorMessage!,
        onRetry: () => _loadNotifications(refresh: true),
      );
    }

    if (_notifications.isEmpty) {
      return AppEmptyState(
        icon: Icons.notifications_none_rounded,
        title: AppLocalizations.of(context)!.translate('noNotificationsFound'),
        description: AppLocalizations.of(context)!.translate('sendInstantNotifications'),
        actionText: AppLocalizations.of(context)!.translate('sendNotificationAction'),
        onAction: () => context.pushNamed(RouteNames.sendNotification),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadNotifications(refresh: true),
      color: AppColors.primary,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == _notifications.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            );
          }
          return NotificationCard(
            notification: _notifications[index],
            onDelete: () => _deleteNotification(_notifications[index]),
          );
        },
      ),
    );
  }
}
