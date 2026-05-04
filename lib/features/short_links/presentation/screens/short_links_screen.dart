import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/constants/feature_flags.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/short_links/data/models/short_link_model.dart';
import 'package:orbit_app/features/short_links/data/repositories/short_links_repository.dart';
import 'package:orbit_app/features/short_links/presentation/widgets/short_link_card.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_search_bar.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';
import 'package:orbit_app/shared/widgets/multi_select_app_bar.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';

/// Screen for managing shortened URLs.
///
/// Displays a list of short links with search, create, copy, and delete.
class ShortLinksScreen extends ConsumerStatefulWidget {
  const ShortLinksScreen({super.key, this.embedded = false});

  /// When true, renders without Scaffold/AppBar for embedding in tabs.
  final bool embedded;

  @override
  ConsumerState<ShortLinksScreen> createState() => _ShortLinksScreenState();
}

class _ShortLinksScreenState extends ConsumerState<ShortLinksScreen> {
  String _searchQuery = '';
  int _currentPage = 1;
  List<ShortLinkModel> _links = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  // ── Multi-select (Wave 6) ────────────────────────────────────────
  final Set<int> _selectedIds = {};
  bool _bulkBusy = false;
  bool get _isMultiSelect => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadLinks();
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

  Future<void> _loadLinks({bool refresh = false}) async {
    if (refresh || _isLoading) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final repository = ref.read(shortLinksRepositoryProvider);
      final result = await repository.getShortLinks(
        page: 1,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (mounted) {
        setState(() {
          _links = result.data;
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
      final repository = ref.read(shortLinksRepositoryProvider);
      final result = await repository.getShortLinks(
        page: _currentPage + 1,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (mounted) {
        setState(() {
          _links.addAll(result.data);
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
    _loadLinks(refresh: true);
  }

  // ── Multi-select (Wave 6) ────────────────────────────────────────

  void _enterMultiSelect(int id) {
    if (!kBulkOperationsEnabled) return;
    setState(() => _selectedIds.add(id));
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitMultiSelect() {
    setState(_selectedIds.clear);
  }

  void _selectAllLinks() {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(_links.map((l) => l.id));
    });
  }

  Future<void> _bulkDeleteLinks() async {
    if (_selectedIds.isEmpty || _bulkBusy) return;
    final t = AppLocalizations.of(context)!;
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t.translate('bulkDelete'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          t.translateWithParams('bulkConfirmDeleteCount', {'count': '$count'}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              t.translate('bulkDelete'),
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _bulkBusy = true);
    final ids = _selectedIds.toList();
    try {
      final repo = ref.read(shortLinksRepositoryProvider);
      await repo.bulkDelete(ids);
      if (!mounted) return;
      _exitMultiSelect();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.translate('bulkSuccessDelete')),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadLinks(refresh: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.translate('bulkFailedDelete')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _bulkBusy = false);
    }
  }

  Future<void> _createLink() async {
    final urlController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.translate('createShortLink'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: AppLocalizations.of(context)!.translate('originalUrl'),
                hint: 'https://example.com/long-url',
                controller: urlController,
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.translate('enterUrl');
                  }
                  final uri = Uri.tryParse(value.trim());
                  if (uri == null || !uri.hasScheme) {
                    return AppLocalizations.of(context)!.translate('enterValidUrl');
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              AppButton.primary(
                text: AppLocalizations.of(context)!.translate('create'),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, urlController.text.trim());
                  }
                },
                icon: Icons.link_rounded,
              ),
            ],
          ),
        ),
      ),
    );

    urlController.dispose();

    if (result != null) {
      try {
        final repository = ref.read(shortLinksRepositoryProvider);
        await repository.createShortLink(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate('shortLinkCreated'),
              ),
              backgroundColor: AppColors.success,
            ),
          );
          _loadLinks(refresh: true);
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteLink(ShortLinkModel link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.translate('deleteLink'),
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          AppLocalizations.of(context)!.translate('confirmDeleteLink'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppLocalizations.of(context)!.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(shortLinksRepositoryProvider);
      await repository.deleteShortLink(link.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.translate('linkDeleted'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _loadLinks(refresh: true);
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
    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppSearchBar(
            hint: AppLocalizations.of(context)!.translate('searchLinks'),
            onChanged: _onSearchChanged,
          ),
        ),
        Expanded(child: _buildContent()),
      ],
    );

    if (widget.embedded) return body;

    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: _isMultiSelect
          ? MultiSelectAppBar(
              selectedCount: _selectedIds.length,
              totalCount: _links.length,
              onCancel: _exitMultiSelect,
              onSelectAll: _selectAllLinks,
              actions: [
                if (_bulkBusy)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: t.translate('bulkDelete'),
                    onPressed: _bulkDeleteLinks,
                  ),
              ],
            )
          : AppBar(
              title: Text(
                t.translate('shortLinks'),
              ),
            ),
      body: body,
      floatingActionButton: _isMultiSelect
          ? null
          : FloatingActionButton(
              onPressed: _createLink,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_link_rounded, color: Colors.white),
            ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return AppLoading.listShimmer();

    if (_errorMessage != null) {
      return AppErrorWidget(
        message: _errorMessage!,
        onRetry: () => _loadLinks(refresh: true),
      );
    }

    if (_links.isEmpty) {
      return AppEmptyState(
        icon: Icons.link_off_rounded,
        title: AppLocalizations.of(context)!.translate('noLinks'),
        description: AppLocalizations.of(context)!.translate('createNewLink'),
        actionText: AppLocalizations.of(context)!.translate('createLink'),
        onAction: _createLink,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadLinks(refresh: true),
      color: AppColors.primary,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _links.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == _links.length) {
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
          final link = _links[index];
          final selected = _selectedIds.contains(link.id);
          return ShortLinkCard(
            link: link,
            onDelete: () => _deleteLink(link),
            isMultiSelectMode: _isMultiSelect,
            isSelected: selected,
            onToggleSelect: () {
              if (_isMultiSelect) {
                _toggleSelection(link.id);
              } else {
                _enterMultiSelect(link.id);
              }
            },
            onLongPress: kBulkOperationsEnabled
                ? () {
                    if (_isMultiSelect) {
                      _toggleSelection(link.id);
                    } else {
                      _enterMultiSelect(link.id);
                    }
                  }
                : null,
          );
        },
      ),
    );
  }
}
