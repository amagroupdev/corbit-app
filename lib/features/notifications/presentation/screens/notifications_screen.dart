import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_app/core/constants/app_colors.dart';
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
        title: const Text(
          '\u062D\u0630\u0641 \u0627\u0644\u0625\u0634\u0639\u0627\u0631', // حذف الإشعار
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text(
          '\u0647\u0644 \u0623\u0646\u062A \u0645\u062A\u0623\u0643\u062F \u0645\u0646 \u062D\u0630\u0641 \u0647\u0630\u0627 \u0627\u0644\u0625\u0634\u0639\u0627\u0631\u061F', // هل أنت متأكد من حذف هذا الإشعار؟
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('\u0625\u0644\u063A\u0627\u0621'), // إلغاء
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('\u062D\u0630\u0641'), // حذف
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
          const SnackBar(
            content: Text('\u062A\u0645 \u062D\u0630\u0641 \u0627\u0644\u0625\u0634\u0639\u0627\u0631'), // تم حذف الإشعار
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
        title: const Text('\u0627\u0644\u0625\u0634\u0639\u0627\u0631\u0627\u062A'), // الإشعارات
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () async {
              try {
                final repo = ref.read(notificationsRepositoryProvider);
                await repo.exportArchive();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('\u062C\u0627\u0631\u064A \u062A\u0635\u062F\u064A\u0631 \u0627\u0644\u0628\u064A\u0627\u0646\u0627\u062A'), // جاري تصدير البيانات
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
            tooltip: '\u062A\u0635\u062F\u064A\u0631', // تصدير
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSearchBar(
              hint: '\u0628\u062D\u062B \u0641\u064A \u0627\u0644\u0625\u0634\u0639\u0627\u0631\u0627\u062A...', // بحث في الإشعارات...
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
        label: const Text(
          '\u0625\u0631\u0633\u0627\u0644', // إرسال
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
        title: '\u0644\u0627 \u062A\u0648\u062C\u062F \u0625\u0634\u0639\u0627\u0631\u0627\u062A', // لا توجد إشعارات
        description: '\u0623\u0631\u0633\u0644 \u0625\u0634\u0639\u0627\u0631\u0627\u062A \u0641\u0648\u0631\u064A\u0629 \u0644\u0639\u0645\u0644\u0627\u0626\u0643', // أرسل إشعارات فورية لعملائك
        actionText: '\u0625\u0631\u0633\u0627\u0644 \u0625\u0634\u0639\u0627\u0631', // إرسال إشعار
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
