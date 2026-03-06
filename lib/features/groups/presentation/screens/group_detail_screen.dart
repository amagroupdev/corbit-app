import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/groups/data/models/number_model.dart';
import 'package:orbit_app/features/groups/data/repositories/groups_repository.dart';
import 'package:orbit_app/features/groups/presentation/controllers/groups_controller.dart';
import 'package:orbit_app/features/groups/presentation/widgets/add_number_sheet.dart';
import 'package:orbit_app/features/groups/presentation/widgets/number_list_item.dart';
import 'package:orbit_app/routing/route_names.dart';

/// Screen showing the details of a single group and its phone numbers.
///
/// Features:
/// - Editable group name
/// - Numbers count badge
/// - List of numbers with search
/// - Add / edit / delete numbers
/// - Import and export buttons
class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({required this.groupId, super.key});

  final int groupId;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  final _scrollController = ScrollController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(groupDetailControllerProvider.notifier)
          .loadGroup(widget.groupId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(groupDetailControllerProvider.notifier)
          .loadMoreNumbers(widget.groupId);
    }
  }

  void _showEditGroupNameDialog() {
    final state = ref.read(groupDetailControllerProvider);
    final controller = TextEditingController(text: state.group?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '\u062A\u0639\u062F\u064A\u0644 \u0627\u0633\u0645 \u0627\u0644\u0645\u062C\u0645\u0648\u0639\u0629',
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
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop();

              final success = await ref
                  .read(groupDetailControllerProvider.notifier)
                  .updateGroupName(widget.groupId, name);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? '\u062A\u0645 \u062A\u062D\u062F\u064A\u062B \u0627\u0644\u0627\u0633\u0645'
                        : '\u0641\u0634\u0644 \u062A\u062D\u062F\u064A\u062B \u0627\u0644\u0627\u0633\u0645'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
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

  void _showAddNumberSheet({NumberModel? existingNumber}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return AddNumberSheet(
            existingNumber: existingNumber,
            isLoading: _isSaving,
            onSave: (name, number, identifier) async {
              setSheetState(() => _isSaving = true);

              bool success;
              if (existingNumber != null) {
                success = await ref
                    .read(groupDetailControllerProvider.notifier)
                    .updateNumber(
                      id: existingNumber.id,
                      name: name,
                      number: number,
                      identifier: identifier,
                    );
              } else {
                success = await ref
                    .read(groupDetailControllerProvider.notifier)
                    .addNumber(
                      groupId: widget.groupId,
                      name: name,
                      number: number,
                      identifier: identifier,
                    );
              }

              setSheetState(() => _isSaving = false);

              if (success && ctx.mounted) {
                Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(existingNumber != null
                          ? '\u062A\u0645 \u062A\u062D\u062F\u064A\u062B \u0627\u0644\u0631\u0642\u0645'
                          : '\u062A\u0645\u062A \u0627\u0644\u0625\u0636\u0627\u0641\u0629 \u0628\u0646\u062C\u0627\u062D'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
          );
        },
      ),
    );
  }

  void _showDeleteNumberDialog(NumberModel numberModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '\u062D\u0630\u0641 \u0627\u0644\u0631\u0642\u0645',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '\u0647\u0644 \u0623\u0646\u062A \u0645\u062A\u0623\u0643\u062F \u0645\u0646 \u062D\u0630\u0641 "${numberModel.number}"\u061F',
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
                  .read(groupDetailControllerProvider.notifier)
                  .deleteNumber(numberModel.id);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('\u062A\u0645 \u062D\u0630\u0641 \u0627\u0644\u0631\u0642\u0645'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text(
              '\u062D\u0630\u0641',
              style: TextStyle(
                color: AppColors.error,
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
    final state = ref.watch(groupDetailControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showEditGroupNameDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  state.group?.name ?? '\u062C\u0627\u0631\u064A \u0627\u0644\u062A\u062D\u0645\u064A\u0644...',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.edit_outlined, size: 18),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: () => context.pushNamed(RouteNames.importNumbers),
            tooltip: '\u0627\u0633\u062A\u064A\u0631\u0627\u062F',
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : state.error != null && state.group == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        state.error!,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => ref
                            .read(groupDetailControllerProvider.notifier)
                            .loadGroup(widget.groupId),
                        icon: const Icon(Icons.refresh),
                        label: const Text('\u0625\u0639\u0627\u062F\u0629 \u0627\u0644\u0645\u062D\u0627\u0648\u0644\u0629'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Numbers count header
                    Container(
                      width: double.infinity,
                      color: AppColors.surface,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.phone_outlined,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${state.numbersCount} \u0631\u0642\u0645',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () async {
                              try {
                                final repo = ref.read(groupsRepositoryProvider);
                                await repo.exportGroups();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('\u062C\u0627\u0631\u064A \u0627\u0644\u062A\u0635\u062F\u064A\u0631...'),
                                      backgroundColor: AppColors.info,
                                    ),
                                  );
                                }
                              } catch (_) {}
                            },
                            icon: const Icon(Icons.download_outlined, size: 18),
                            label: const Text(
                              '\u062A\u0635\u062F\u064A\u0631',
                              style: TextStyle(fontSize: 13),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Numbers list
                    Expanded(
                      child: state.isLoadingNumbers
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : state.numbers.isEmpty
                              ? _buildEmptyNumbers()
                              : RefreshIndicator(
                                  onRefresh: () async {
                                    await ref
                                        .read(groupDetailControllerProvider
                                            .notifier)
                                        .loadNumbers(widget.groupId);
                                  },
                                  color: AppColors.primary,
                                  child: ListView.separated(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: state.numbers.length +
                                        (state.hasMoreNumbers ? 1 : 0),
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      if (index >= state.numbers.length) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 16),
                                            child: CircularProgressIndicator(
                                              color: AppColors.primary,
                                              strokeWidth: 2.5,
                                            ),
                                          ),
                                        );
                                      }

                                      final number = state.numbers[index];
                                      return NumberListItem(
                                        numberModel: number,
                                        onEdit: () =>
                                            _showAddNumberSheet(
                                                existingNumber: number),
                                        onDelete: () =>
                                            _showDeleteNumberDialog(number),
                                      );
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNumberSheet(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.person_add_outlined),
      ),
    );
  }

  Widget _buildEmptyNumbers() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.contact_phone_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '\u0644\u0627 \u062A\u0648\u062C\u062F \u0623\u0631\u0642\u0627\u0645',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '\u0623\u0636\u0641 \u0623\u0631\u0642\u0627\u0645\u0627\u064B \u0644\u0647\u0630\u0647 \u0627\u0644\u0645\u062C\u0645\u0648\u0639\u0629 \u0623\u0648 \u0627\u0633\u062A\u0648\u0631\u062F\u0647\u0627 \u0645\u0646 \u0645\u0644\u0641 Excel',
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
}
