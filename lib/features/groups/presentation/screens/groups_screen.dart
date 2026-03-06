import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/groups/data/repositories/groups_repository.dart';
import 'package:orbit_app/features/groups/presentation/controllers/groups_controller.dart';
import 'package:orbit_app/features/groups/presentation/widgets/group_card.dart';
import 'package:orbit_app/routing/route_names.dart';

/// Main groups listing screen.
///
/// Features:
/// - Search bar at top
/// - Pull to refresh + infinite scroll
/// - Toggle trashed groups filter
/// - FAB to create new group
/// - Swipe actions: edit, delete/restore
/// - Empty state illustration
class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load groups on first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupsListControllerProvider.notifier).loadGroups();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(groupsListControllerProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(groupsListControllerProvider.notifier).search(query);
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(groupsListControllerProvider.notifier).loadGroups();
  }

  void _showDeleteDialog(int groupId, String groupName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '\u062D\u0630\u0641 \u0627\u0644\u0645\u062C\u0645\u0648\u0639\u0629',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '\u0647\u0644 \u0623\u0646\u062A \u0645\u062A\u0623\u0643\u062F \u0645\u0646 \u062D\u0630\u0641 \u0627\u0644\u0645\u062C\u0645\u0648\u0639\u0629 "$groupName"\u061F',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              '\u0625\u0644\u063A\u0627\u0621',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref
                  .read(groupsListControllerProvider.notifier)
                  .deleteGroup(groupId);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('\u062A\u0645 \u062D\u0630\u0641 \u0627\u0644\u0645\u062C\u0645\u0648\u0639\u0629 \u0628\u0646\u062C\u0627\u062D'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text(
              '\u062D\u0630\u0641',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(int groupId, String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '\u062A\u0639\u062F\u064A\u0644 \u0627\u0644\u0645\u062C\u0645\u0648\u0639\u0629',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '\u0627\u0633\u0645 \u0627\u0644\u0645\u062C\u0645\u0648\u0639\u0629',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              '\u0625\u0644\u063A\u0627\u0621',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              Navigator.of(ctx).pop();

              final detailNotifier =
                  ref.read(groupDetailControllerProvider.notifier);
              final success =
                  await detailNotifier.updateGroupName(groupId, newName);

              if (mounted) {
                if (success) {
                  ref
                      .read(groupsListControllerProvider.notifier)
                      .loadGroups();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('\u062A\u0645 \u062A\u062D\u062F\u064A\u062B \u0627\u0644\u0627\u0633\u0645 \u0628\u0646\u062C\u0627\u062D'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('\u0641\u0634\u0644 \u062A\u062D\u062F\u064A\u062B \u0627\u0644\u0627\u0633\u0645'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text(
              '\u062D\u0641\u0638',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupsListControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          '\u0627\u0644\u0645\u062C\u0645\u0648\u0639\u0627\u062A',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () async {
              try {
                final repo = ref.read(groupsRepositoryProvider);
                await repo.exportGroups();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('\u062C\u0627\u0631\u064A \u062A\u0635\u062F\u064A\u0631 \u0627\u0644\u0645\u062C\u0645\u0648\u0639\u0627\u062A...'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('\u0641\u0634\u0644 \u0627\u0644\u062A\u0635\u062F\u064A\u0631'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            tooltip: '\u062A\u0635\u062F\u064A\u0631',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar and filter
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: '\u0628\u062D\u062B \u0639\u0646 \u0645\u062C\u0645\u0648\u0639\u0629...',
                    hintStyle: const TextStyle(
                      color: AppColors.inputHint,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textHint,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.scaffoldBackground,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Trashed toggle
                Row(
                  children: [
                    Text(
                      '\u0639\u0631\u0636 \u0627\u0644\u0645\u062D\u0630\u0648\u0641\u0629',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 24,
                      child: Switch.adaptive(
                        value: state.includeTrashed,
                        onChanged: (value) {
                          ref
                              .read(groupsListControllerProvider.notifier)
                              .toggleTrashed(value);
                        },
                        activeColor: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${state.total} \u0645\u062C\u0645\u0648\u0639\u0629',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : state.error != null && state.groups.isEmpty
                    ? _buildErrorState(state.error!)
                    : state.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _onRefresh,
                            color: AppColors.primary,
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount:
                                  state.groups.length + (state.hasMore ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                if (index >= state.groups.length) {
                                  return const Center(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16),
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  );
                                }

                                final group = state.groups[index];
                                return GroupCard(
                                  group: group,
                                  onTap: () {
                                    context.pushNamed(
                                      RouteNames.groupDetail,
                                      pathParameters: {
                                        'id': group.id.toString(),
                                      },
                                    );
                                  },
                                  onEdit: () => _showEditDialog(
                                    group.id,
                                    group.name,
                                  ),
                                  onDelete: () => _showDeleteDialog(
                                    group.id,
                                    group.name,
                                  ),
                                  onRestore: () async {
                                    final success = await ref
                                        .read(groupsListControllerProvider
                                            .notifier)
                                        .restoreGroup(group.id);
                                    if (mounted && success) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              '\u062A\u0645 \u0627\u0633\u062A\u0639\u0627\u062F\u0629 \u0627\u0644\u0645\u062C\u0645\u0648\u0639\u0629'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed(RouteNames.createGroup),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.people_outline,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '\u0644\u0627 \u062A\u0648\u062C\u062F \u0645\u062C\u0645\u0648\u0639\u0627\u062A',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '\u0627\u0628\u062F\u0623 \u0628\u0625\u0646\u0634\u0627\u0621 \u0645\u062C\u0645\u0648\u0639\u0629 \u062C\u062F\u064A\u062F\u0629 \u0644\u062A\u0646\u0638\u064A\u0645 \u0623\u0631\u0642\u0627\u0645\u0643',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('\u0625\u0639\u0627\u062F\u0629 \u0627\u0644\u0645\u062D\u0627\u0648\u0644\u0629'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
