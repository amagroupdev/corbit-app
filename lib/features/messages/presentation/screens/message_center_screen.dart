import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/messages/data/models/message_model.dart';
import 'package:orbit_app/features/messages/presentation/controllers/messages_controller.dart';
import 'package:orbit_app/features/messages/presentation/widgets/message_card.dart';
import 'package:orbit_app/features/messages/presentation/widgets/messages_attachments_tab.dart';
import 'package:orbit_app/features/messages/presentation/widgets/messages_pending_tab.dart';
import 'package:orbit_app/features/templates/presentation/screens/templates_screen.dart';
import 'package:orbit_app/features/settings/presentation/screens/sender_names_screen.dart';
import 'package:orbit_app/features/short_links/presentation/screens/short_links_screen.dart';
import 'package:orbit_app/routing/route_names.dart';

/// Main message center screen matching the website layout.
///
/// Features 6 functional tabs:
/// 1. جميع الرسائل (All Messages) - with status filter chips
/// 2. الرسائل المعلقة (Pending Messages)
/// 3. المرفقات (Attachments)
/// 4. القوالب (Templates)
/// 5. أسماء المرسلين (Sender Names)
/// 6. اختصار الروابط (Link Shortener)
class MessageCenterScreen extends ConsumerStatefulWidget {
  const MessageCenterScreen({super.key});

  @override
  ConsumerState<MessageCenterScreen> createState() =>
      _MessageCenterScreenState();
}

class _MessageCenterScreenState extends ConsumerState<MessageCenterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  bool _showSearch = false;
  Timer? _searchDebounce;

  /// Status filter for messages tab
  String _selectedStatus = 'all'; // all, sent, failed, pending

  static const List<_TabItem> _tabs = [
    _TabItem(label: 'جميع الرسائل', icon: Icons.mail_outline_rounded),
    _TabItem(label: 'الرسائل المعلقة', icon: Icons.pending_outlined),
    _TabItem(label: 'المرفقات', icon: Icons.attach_file_rounded),
    _TabItem(label: 'القوالب', icon: Icons.description_outlined),
    _TabItem(label: 'أسماء المرسلين', icon: Icons.badge_outlined),
    _TabItem(label: 'اختصار الروابط', icon: Icons.link_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(messageSearchQueryProvider.notifier).state = query;
      ref.read(messagePageProvider.notifier).state = 1;
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        ref.read(messageSearchQueryProvider.notifier).state = '';
        ref.read(messagePageProvider.notifier).state = 1;
      }
    });
  }

  void _navigateToSendMessage() {
    context.pushNamed(
      RouteNames.sendMessage,
      extra: {'message_type': MessageType.fromNumbers.value},
    );
  }

  Future<void> _refresh() async {
    ref.read(messagePageProvider.notifier).state = 1;
    ref.invalidate(messagesListProvider);
  }

  void _setStatusFilter(String status) {
    setState(() => _selectedStatus = status);
    // Reset pagination
    ref.read(messagePageProvider.notifier).state = 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── App Bar ────────────────────────────────────────────────
          SliverAppBar(
            title: _showSearch
                ? _buildSearchField()
                : const Text('مركز الرسائل'),
            centerTitle: true,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            floating: true,
            pinned: true,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                icon: Icon(
                  _showSearch ? Icons.close : Icons.search,
                  color: AppColors.textSecondary,
                ),
                onPressed: _toggleSearch,
              ),
              IconButton(
                icon: const Icon(Icons.tune, color: AppColors.textSecondary),
                onPressed: () => _showFilterSheet(context),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: _buildTabBar(),
            ),
          ),
        ],
        body: Column(
          children: [
            // ── Action Buttons Row ─────────────────────────────────
            _buildActionButtons(),

            // ── Tab Content ────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: All Messages
                  _AllMessagesTab(
                    selectedStatus: _selectedStatus,
                    onStatusChanged: _setStatusFilter,
                    onRefresh: _refresh,
                    onNavigateToSend: _navigateToSendMessage,
                  ),
                  // Tab 2: Pending Messages
                  const MessagesPendingTab(),
                  // Tab 3: Attachments
                  const MessagesAttachmentsTab(),
                  // Tab 4: Templates (embedded)
                  const _EmbeddedTemplatesTab(),
                  // Tab 5: Sender Names (embedded)
                  const _EmbeddedSenderNamesTab(),
                  // Tab 6: Short Links (embedded)
                  const _EmbeddedShortLinksTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToSendMessage,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.send_rounded, size: 20),
        label: const Text(
          'رسالة جديدة',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 4,
      ),
    );
  }

  // ─── Action Buttons ──────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _navigateToSendMessage,
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('إرسال متقدم', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('جاري تصدير السجل...'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
            icon: const Icon(Icons.file_download_outlined, size: 16),
            label: const Text('تصدير السجل', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search Field ──────────────────────────────────────────────────

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      autofocus: true,
      textDirection: TextDirection.rtl,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      decoration: const InputDecoration(
        hintText: 'بحث عام (بالنص: الرسالة اسم المرسل)',
        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  // ─── Tab Bar ─────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          fontFamily: 'Cairo',
        ),
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tabs: _tabs
            .map((tab) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tab.icon, size: 16),
                      const SizedBox(width: 6),
                      Text(tab.label),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ─── Filter Sheet ──────────────────────────────────────────────────

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Icon(Icons.tune, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'تصفية الرسائل',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Sender Name filter
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('إسم المرسل',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('اختر إسم المرسل',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textHint)),
                      items: const [],
                      onChanged: (_) {},
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Message Type filter
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('نوع الرسالة',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('نوع الرسالة',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textHint)),
                      items: MessageType.values
                          .map((type) => DropdownMenuItem<String>(
                                value: type.value,
                                child: Text(type.shortLabel,
                                    style: const TextStyle(fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          final type = MessageType.values
                              .firstWhere((t) => t.value == value);
                          ref
                              .read(selectedMessageTypeProvider.notifier)
                              .state = type;
                          ref.read(messagePageProvider.notifier).state = 1;
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // With attachments toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('مع المرفقات',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    Switch(
                      value: false,
                      onChanged: (_) {},
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Status filter chips
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('حالة الرسالة',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MessageStatus.values.map((status) {
                    return FilterChip(
                      label: Text(status.arabicLabel,
                          style: const TextStyle(fontSize: 12)),
                      selected: false,
                      onSelected: (_) => Navigator.pop(context),
                      selectedColor: AppColors.primarySurface,
                      checkmarkColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceVariant,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Reset
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(selectedMessageTypeProvider.notifier).state =
                          null;
                      ref.read(messageSearchQueryProvider.notifier).state = '';
                      ref.read(messagePageProvider.notifier).state = 1;
                      ref.invalidate(messagesListProvider);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('إعادة تعيين الفلاتر',
                        style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab Item Model
// ═══════════════════════════════════════════════════════════════════════════

class _TabItem {
  const _TabItem({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 1: All Messages
// ═══════════════════════════════════════════════════════════════════════════

class _AllMessagesTab extends ConsumerWidget {
  const _AllMessagesTab({
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.onRefresh,
    required this.onNavigateToSend,
  });

  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;
  final Future<void> Function() onRefresh;
  final VoidCallback onNavigateToSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesListProvider);

    return Column(
      children: [
        // ── Status Filter Chips ─────────────────────────────────
        _buildStatusChips(),

        // ── Message List ────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: onRefresh,
            child: messagesAsync.when(
              loading: () => _buildLoadingState(),
              error: (error, _) => _buildErrorState(context, error),
              data: (paginated) {
                if (paginated.isEmpty) {
                  return _buildEmptyState(context);
                }
                return _buildMessageList(
                    ref, paginated.data, paginated.hasMore);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChips() {
    final statuses = [
      ('all', 'الكل'),
      ('sent', 'تم الإرسال'),
      ('failed', 'فشل'),
      ('pending', 'قيد الإنتظار'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statuses.map((status) {
            final isSelected = selectedStatus == status.$1;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: FilterChip(
                label: Text(
                  status.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => onStatusChanged(status.$1),
                backgroundColor: AppColors.surfaceVariant,
                selectedColor: AppColors.primary,
                showCheckmark: false,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessageList(
      WidgetRef ref, List<SentMessageModel> messages, bool hasMore) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200 &&
            hasMore) {
          ref.read(messagePageProvider.notifier).state++;
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: messages.length + (hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= messages.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            );
          }
          return MessageCard(
            message: messages[index],
            onTap: () {},
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 130,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            const Text('فشل تحميل الرسائل',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(error.toString(),
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mail_outline,
                    size: 64, color: AppColors.textHint),
                const SizedBox(height: 16),
                const Text('لا توجد رسائل',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                const Text('ابدأ بإرسال رسالتك الأولى',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onNavigateToSend,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إرسال رسالة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 4: Embedded Templates Tab (without Scaffold)
// ═══════════════════════════════════════════════════════════════════════════

class _EmbeddedTemplatesTab extends StatelessWidget {
  const _EmbeddedTemplatesTab();

  @override
  Widget build(BuildContext context) {
    return const TemplatesScreen(embedded: true);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 5: Embedded Sender Names Tab (without Scaffold)
// ═══════════════════════════════════════════════════════════════════════════

class _EmbeddedSenderNamesTab extends StatelessWidget {
  const _EmbeddedSenderNamesTab();

  @override
  Widget build(BuildContext context) {
    return const SenderNamesScreen(embedded: true);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 6: Embedded Short Links Tab (without Scaffold)
// ═══════════════════════════════════════════════════════════════════════════

class _EmbeddedShortLinksTab extends StatelessWidget {
  const _EmbeddedShortLinksTab();

  @override
  Widget build(BuildContext context) {
    return const ShortLinksScreen(embedded: true);
  }
}
