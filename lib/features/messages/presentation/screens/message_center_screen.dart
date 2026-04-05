import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
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
    _TabItem(labelKey: 'msg_tab_all_messages', icon: Icons.mail_outline_rounded),
    _TabItem(labelKey: 'msg_tab_pending', icon: Icons.pending_outlined),
    _TabItem(labelKey: 'msg_tab_attachments', icon: Icons.attach_file_rounded),
    _TabItem(labelKey: 'msg_tab_templates', icon: Icons.description_outlined),
    _TabItem(labelKey: 'msg_tab_sender_names', icon: Icons.badge_outlined),
    _TabItem(labelKey: 'msg_tab_short_links', icon: Icons.link_rounded),
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
                : Text(AppLocalizations.of(context)!.translate('messageCenter')),
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
        label: Text(
          AppLocalizations.of(context)!.translate('msg_new_message'),
          style: const TextStyle(fontWeight: FontWeight.w600),
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
              label: Text(AppLocalizations.of(context)!.translate('msg_advanced_send'), style: const TextStyle(fontSize: 13)),
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
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.translate('msg_exporting_log')),
                  backgroundColor: AppColors.info,
                ),
              );
            },
            icon: const Icon(Icons.file_download_outlined, size: 16),
            label: Text(AppLocalizations.of(context)!.translate('msg_export_log'), style: const TextStyle(fontSize: 13)),
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
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.translate('msg_search_hint'),
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
          fontFamily: 'IBMPlexSansArabic',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          fontFamily: 'IBMPlexSansArabic',
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
                      Text(AppLocalizations.of(context)!.translate(tab.labelKey)),
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
                Row(
                  children: [
                    const Icon(Icons.tune, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.translate('msg_filter_title'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Sender Name filter
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(AppLocalizations.of(context)!.translate('msg_filter_sender_name'),
                      style: const TextStyle(
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
                      hint: Text(AppLocalizations.of(context)!.translate('msg_filter_select_sender'),
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textHint)),
                      items: const [],
                      onChanged: (_) {},
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Message Type filter
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(AppLocalizations.of(context)!.translate('msg_filter_message_type'),
                      style: const TextStyle(
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
                      hint: Text(AppLocalizations.of(context)!.translate('msg_filter_message_type'),
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textHint)),
                      items: MessageType.values
                          .map((type) => DropdownMenuItem<String>(
                                value: type.value,
                                child: Text(AppLocalizations.of(context)!.translate(type.shortLabelKey),
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
                    Text(AppLocalizations.of(context)!.translate('msg_filter_with_attachments'),
                        style: const TextStyle(
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
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(AppLocalizations.of(context)!.translate('msg_filter_message_status'),
                      style: const TextStyle(
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
                      label: Text(AppLocalizations.of(context)!.translate(status.labelKey),
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
                    child: Text(AppLocalizations.of(context)!.translate('msg_filter_reset'),
                        style: const TextStyle(fontSize: 14)),
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
  const _TabItem({required this.labelKey, required this.icon});
  final String labelKey;
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
        _buildStatusChips(context),

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

  Widget _buildStatusChips(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final statuses = [
      ('all', t.translate('msg_status_chip_all')),
      ('sent', t.translate('msg_status_chip_sent')),
      ('failed', t.translate('msg_status_chip_failed')),
      ('pending', t.translate('msg_status_chip_pending')),
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
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(t.translate('msg_load_failed'),
                style: const TextStyle(
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
              label: Text(t.translate('retry')),
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
    final t = AppLocalizations.of(context)!;
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
                Text(t.translate('msg_no_messages'),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(t.translate('msg_start_first'),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onNavigateToSend,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(t.translate('sendMessage')),
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
