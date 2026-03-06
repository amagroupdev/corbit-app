import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/questionnaires/data/models/questionnaire_model.dart';
import 'package:orbit_app/features/questionnaires/data/repositories/questionnaires_repository.dart';
import 'package:orbit_app/features/questionnaires/presentation/widgets/questionnaire_card.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_search_bar.dart';

/// Screen for managing questionnaires with Sent/Unsent tabs.
class QuestionnairesScreen extends ConsumerStatefulWidget {
  const QuestionnairesScreen({super.key});

  @override
  ConsumerState<QuestionnairesScreen> createState() =>
      _QuestionnairesScreenState();
}

class _QuestionnairesScreenState extends ConsumerState<QuestionnairesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _searchQuery = '';

  // Sent tab state
  List<QuestionnaireModel> _sentList = [];
  bool _sentLoading = true;
  String? _sentError;

  // Unsent tab state
  List<QuestionnaireModel> _unsentList = [];
  bool _unsentLoading = true;
  String? _unsentError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSent();
    _loadUnsent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSent({bool refresh = false}) async {
    setState(() {
      _sentLoading = true;
      _sentError = null;
    });

    try {
      final repo = ref.read(questionnairesRepositoryProvider);
      final result = await repo.getSentQuestionnaires(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if (mounted) {
        setState(() {
          _sentList = result.data;
          _sentLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _sentError = e.message;
          _sentLoading = false;
        });
      }
    }
  }

  Future<void> _loadUnsent({bool refresh = false}) async {
    setState(() {
      _unsentLoading = true;
      _unsentError = null;
    });

    try {
      final repo = ref.read(questionnairesRepositoryProvider);
      final result = await repo.getUnsentQuestionnaires();
      if (mounted) {
        setState(() {
          _unsentList = result.data;
          _unsentLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _unsentError = e.message;
          _unsentLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _loadSent();
  }

  Future<void> _deleteQuestionnaire(QuestionnaireModel q) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '\u062D\u0630\u0641 \u0627\u0644\u0627\u0633\u062A\u0628\u064A\u0627\u0646', // حذف الاستبيان
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          '\u0647\u0644 \u0623\u0646\u062A \u0645\u062A\u0623\u0643\u062F \u0645\u0646 \u062D\u0630\u0641 "${q.title}"\u061F', // هل أنت متأكد من حذف "..."؟
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
      final repo = ref.read(questionnairesRepositoryProvider);
      await repo.deleteQuestionnaire(q.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('\u062A\u0645 \u0627\u0644\u062D\u0630\u0641 \u0628\u0646\u062C\u0627\u062D'), // تم الحذف بنجاح
            backgroundColor: AppColors.success,
          ),
        );
        _loadSent(refresh: true);
        _loadUnsent(refresh: true);
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
        title: const Text('\u0627\u0644\u0627\u0633\u062A\u0628\u064A\u0627\u0646\u0627\u062A'), // الاستبيانات
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: '\u0627\u0644\u0645\u0631\u0633\u0644\u0629 (${_sentList.length})'), // المرسلة
            Tab(text: '\u063A\u064A\u0631 \u0627\u0644\u0645\u0631\u0633\u0644\u0629 (${_unsentList.length})'), // غير المرسلة
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSearchBar(
              hint: '\u0628\u062D\u062B \u0641\u064A \u0627\u0644\u0627\u0633\u062A\u0628\u064A\u0627\u0646\u0627\u062A...', // بحث في الاستبيانات...
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSentTab(),
                _buildUnsentTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentTab() {
    if (_sentLoading) return AppLoading.listShimmer();
    if (_sentError != null) {
      return AppErrorWidget(
        message: _sentError!,
        onRetry: () => _loadSent(refresh: true),
      );
    }
    if (_sentList.isEmpty) {
      return const AppEmptyState(
        icon: Icons.quiz_outlined,
        title: '\u0644\u0627 \u062A\u0648\u062C\u062F \u0627\u0633\u062A\u0628\u064A\u0627\u0646\u0627\u062A \u0645\u0631\u0633\u0644\u0629', // لا توجد استبيانات مرسلة
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadSent(refresh: true),
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _sentList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final q = _sentList[index];
          return QuestionnaireCard(
            questionnaire: q,
            onDelete: () => _deleteQuestionnaire(q),
          );
        },
      ),
    );
  }

  Widget _buildUnsentTab() {
    if (_unsentLoading) return AppLoading.listShimmer();
    if (_unsentError != null) {
      return AppErrorWidget(
        message: _unsentError!,
        onRetry: () => _loadUnsent(refresh: true),
      );
    }
    if (_unsentList.isEmpty) {
      return const AppEmptyState(
        icon: Icons.quiz_outlined,
        title: '\u0644\u0627 \u062A\u0648\u062C\u062F \u0627\u0633\u062A\u0628\u064A\u0627\u0646\u0627\u062A \u063A\u064A\u0631 \u0645\u0631\u0633\u0644\u0629', // لا توجد استبيانات غير مرسلة
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadUnsent(refresh: true),
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _unsentList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final q = _unsentList[index];
          return QuestionnaireCard(
            questionnaire: q,
            onSend: () {
              // TODO: Navigate to send questionnaire flow
            },
            onDelete: () => _deleteQuestionnaire(q),
          );
        },
      ),
    );
  }
}
