import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/files/data/models/file_model.dart';
import 'package:orbit_app/features/files/data/repositories/files_repository.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_search_bar.dart';

/// Screen for managing uploaded files.
///
/// Displays a list of files with icons, upload FAB, download, delete,
/// and multi-select bulk delete.
class FilesScreen extends ConsumerStatefulWidget {
  const FilesScreen({super.key});

  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen> {
  String _searchQuery = '';
  List<FileModel> _files = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<int> _selectedIds = {};
  bool get _isMultiSelect => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(filesRepositoryProvider);
      final result = await repo.getFiles(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (mounted) {
        setState(() {
          _files = result.data;
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _loadFiles();
  }

  void _toggleSelect(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteFile(FileModel file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '\u062D\u0630\u0641 \u0627\u0644\u0645\u0644\u0641', // حذف الملف
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          '\u0647\u0644 \u0623\u0646\u062A \u0645\u062A\u0623\u0643\u062F \u0645\u0646 \u062D\u0630\u0641 "${file.name}"\u061F', // هل أنت متأكد من حذف "..."؟
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('\u0625\u0644\u063A\u0627\u0621'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('\u062D\u0630\u0641'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(filesRepositoryProvider);
      await repo.deleteFile(file.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('\u062A\u0645 \u062D\u0630\u0641 \u0627\u0644\u0645\u0644\u0641'), // تم حذف الملف
            backgroundColor: AppColors.success,
          ),
        );
        _loadFiles(refresh: true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _bulkDelete() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('\u062D\u0630\u0641 \u0627\u0644\u0645\u0644\u0641\u0627\u062A', style: TextStyle(fontWeight: FontWeight.w600)), // حذف الملفات
        content: Text('\u0647\u0644 \u0623\u0646\u062A \u0645\u062A\u0623\u0643\u062F \u0645\u0646 \u062D\u0630\u0641 ${_selectedIds.length} \u0645\u0644\u0641\u0627\u062A\u061F'), // هل أنت متأكد من حذف ... ملفات؟
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('\u0625\u0644\u063A\u0627\u0621')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('\u062D\u0630\u0641'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(filesRepositoryProvider);
      await repo.bulkDelete(_selectedIds.toList());
      if (mounted) {
        setState(() => _selectedIds.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('\u062A\u0645 \u062D\u0630\u0641 \u0627\u0644\u0645\u0644\u0641\u0627\u062A'), // تم حذف الملفات
            backgroundColor: AppColors.success,
          ),
        );
        _loadFiles(refresh: true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _downloadFile(FileModel file) async {
    try {
      final repo = ref.read(filesRepositoryProvider);
      final url = await repo.getDownloadUrl(file.id);
      if (mounted && url.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('\u062C\u0627\u0631\u064A \u062A\u062D\u0645\u064A\u0644 \u0627\u0644\u0645\u0644\u0641'), // جاري تحميل الملف
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
  }

  IconData _fileIcon(FileModel file) {
    if (file.isImage) return Icons.image_outlined;
    if (file.isPdf) return Icons.picture_as_pdf_outlined;
    if (file.isExcel) return Icons.table_chart_outlined;
    switch (file.extension) {
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'mp3':
      case 'wav':
        return Icons.audio_file_outlined;
      case 'mp4':
      case 'avi':
        return Icons.video_file_outlined;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('\u0627\u0644\u0645\u0644\u0641\u0627\u062A'), // الملفات
        actions: [
          if (_isMultiSelect) ...[
            Text(
              '${_selectedIds.length}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _bulkDelete,
              tooltip: '\u062D\u0630\u0641 \u0627\u0644\u0645\u062D\u062F\u062F', // حذف المحدد
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _selectedIds.clear()),
              tooltip: '\u0625\u0644\u063A\u0627\u0621 \u0627\u0644\u062A\u062D\u062F\u064A\u062F', // إلغاء التحديد
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSearchBar(
              hint: '\u0628\u062D\u062B \u0641\u064A \u0627\u0644\u0645\u0644\u0641\u0627\u062A...', // بحث في الملفات...
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('\u0627\u062E\u062A\u0631 \u0645\u0644\u0641 \u0644\u0644\u0631\u0641\u0639'), // اختر ملف للرفع
              backgroundColor: AppColors.info,
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.upload_file_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return AppLoading.listShimmer();
    if (_errorMessage != null) {
      return AppErrorWidget(message: _errorMessage!, onRetry: () => _loadFiles(refresh: true));
    }
    if (_files.isEmpty) {
      return const AppEmptyState(
        icon: Icons.folder_open_outlined,
        title: '\u0644\u0627 \u062A\u0648\u062C\u062F \u0645\u0644\u0641\u0627\u062A', // لا توجد ملفات
        description: '\u0627\u0631\u0641\u0639 \u0645\u0644\u0641\u0627\u062A \u062C\u062F\u064A\u062F\u0629 \u0628\u0627\u0633\u062A\u062E\u062F\u0627\u0645 \u0632\u0631 \u0627\u0644\u0631\u0641\u0639', // ارفع ملفات جديدة باستخدام زر الرفع
      );
    }

    final dateFormat = intl.DateFormat('yyyy/MM/dd', 'ar');

    return RefreshIndicator(
      onRefresh: () => _loadFiles(refresh: true),
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _files.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          final file = _files[index];
          final isSelected = _selectedIds.contains(file.id);
          return Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primarySurface : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
              boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isMultiSelect ? () => _toggleSelect(file.id) : () => _downloadFile(file),
                onLongPress: () => _toggleSelect(file.id),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      if (_isMultiSelect)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected ? AppColors.primary : AppColors.textHint,
                            size: 22,
                          ),
                        ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_fileIcon(file), color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${file.formattedSize} \u2022 ${dateFormat.format(file.createdAt)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'download') _downloadFile(file);
                          if (value == 'delete') _deleteFile(file);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'download',
                            child: Row(
                              children: [
                                Icon(Icons.download_outlined, size: 20, color: AppColors.textSecondary),
                                SizedBox(width: 8),
                                Text('\u062A\u062D\u0645\u064A\u0644'), // تحميل
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                                SizedBox(width: 8),
                                Text('\u062D\u0630\u0641', style: TextStyle(color: AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
