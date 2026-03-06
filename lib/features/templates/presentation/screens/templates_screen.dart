import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/messages/data/models/template_model.dart';
import 'package:orbit_app/features/templates/data/repositories/templates_repository.dart';
import 'package:orbit_app/features/templates/presentation/widgets/template_form_sheet.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_search_bar.dart';

/// Screen for managing reusable SMS message templates.
///
/// Displays a searchable, paginated list of templates with actions
/// to create, edit, and delete templates.
class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key, this.embedded = false});

  /// When true, renders without Scaffold/AppBar for embedding in tabs.
  final bool embedded;

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  String _searchQuery = '';
  int _currentPage = 1;
  List<TemplateModel> _templates = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTemplates();
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

  Future<void> _loadTemplates({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final repository = ref.read(templatesRepositoryProvider);
      final result = await repository.getTemplates(
        page: 1,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (mounted) {
        setState(() {
          _templates = result.data;
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
      final repository = ref.read(templatesRepositoryProvider);
      final result = await repository.getTemplates(
        page: _currentPage + 1,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (mounted) {
        setState(() {
          _templates.addAll(result.data);
          _hasMore = result.hasMore;
          _currentPage = result.currentPage;
          _isLoadingMore = false;
        });
      }
    } on ApiException {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _loadTemplates(refresh: true);
  }

  Future<void> _createTemplate() async {
    final result = await TemplateFormSheet.show(context);
    if (result != null) {
      _loadTemplates(refresh: true);
    }
  }

  Future<void> _editTemplate(TemplateModel template) async {
    final result = await TemplateFormSheet.show(context, template: template);
    if (result != null) {
      _loadTemplates(refresh: true);
    }
  }

  Future<void> _deleteTemplate(TemplateModel template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '\u062D\u0630\u0641 \u0627\u0644\u0642\u0627\u0644\u0628', // حذف القالب
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          '\u0647\u0644 \u0623\u0646\u062A \u0645\u062A\u0623\u0643\u062F \u0645\u0646 \u062D\u0630\u0641 \u0627\u0644\u0642\u0627\u0644\u0628 "${template.name}"\u061F', // هل أنت متأكد من حذف القالب "..."؟
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '\u0625\u0644\u063A\u0627\u0621', // إلغاء
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(
              '\u062D\u0630\u0641', // حذف
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(templatesRepositoryProvider);
      await repository.deleteTemplate(template.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '\u062A\u0645 \u062D\u0630\u0641 \u0627\u0644\u0642\u0627\u0644\u0628 \u0628\u0646\u062C\u0627\u062D', // تم حذف القالب بنجاح
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _loadTemplates(refresh: true);
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

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        // ── Search bar ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppSearchBar(
            hint: '\u0628\u062D\u062B \u0641\u064A \u0627\u0644\u0642\u0648\u0627\u0644\u0628...', // بحث في القوالب...
            onChanged: _onSearchChanged,
          ),
        ),

        // ── Content ──────────────────────────────────────
        Expanded(child: _buildContent()),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '\u0627\u0644\u0642\u0648\u0627\u0644\u0628', // القوالب
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _createTemplate,
            tooltip: '\u0625\u0646\u0634\u0627\u0621 \u0642\u0627\u0644\u0628', // إنشاء قالب
          ),
        ],
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: _createTemplate,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return AppLoading.listShimmer();
    }

    if (_errorMessage != null) {
      return AppErrorWidget(
        message: _errorMessage!,
        onRetry: () => _loadTemplates(refresh: true),
      );
    }

    if (_templates.isEmpty) {
      return AppEmptyState(
        icon: Icons.description_outlined,
        title: '\u0644\u0627 \u062A\u0648\u062C\u062F \u0642\u0648\u0627\u0644\u0628', // لا توجد قوالب
        description: '\u0642\u0645 \u0628\u0625\u0646\u0634\u0627\u0621 \u0642\u0627\u0644\u0628 \u062C\u062F\u064A\u062F \u0644\u062A\u0633\u0647\u064A\u0644 \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0631\u0633\u0627\u0626\u0644', // قم بإنشاء قالب جديد لتسهيل إرسال الرسائل
        actionText: '\u0625\u0646\u0634\u0627\u0621 \u0642\u0627\u0644\u0628', // إنشاء قالب
        onAction: _createTemplate,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadTemplates(refresh: true),
      color: AppColors.primary,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _templates.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == _templates.length) {
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

          final template = _templates[index];
          return _TemplateListTile(
            template: template,
            onEdit: () => _editTemplate(template),
            onDelete: () => _deleteTemplate(template),
          );
        },
      ),
    );
  }
}

/// Individual template list tile with edit and delete actions.
class _TemplateListTile extends StatelessWidget {
  const _TemplateListTile({
    required this.template,
    required this.onEdit,
    required this.onDelete,
  });

  final TemplateModel template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        template.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 20,
                                  color: AppColors.textSecondary),
                              SizedBox(width: 8),
                              Text('\u062A\u0639\u062F\u064A\u0644'), // تعديل
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 20,
                                  color: AppColors.error),
                              SizedBox(width: 8),
                              Text(
                                '\u062D\u0630\u0641', // حذف
                                style: TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  template.body,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
