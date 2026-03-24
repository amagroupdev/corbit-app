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
import 'package:orbit_app/core/localization/app_localizations.dart';

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
        title: Text(
          AppLocalizations.of(context)!.translate('deleteQuestionnaire'),
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          '${AppLocalizations.of(context)!.translate("confirmDeleteQuestionnaire")} "${q.title}"?',
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
      final repo = ref.read(questionnairesRepositoryProvider);
      await repo.deleteQuestionnaire(q.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('deletedSuccessfully')),
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
        title: Text(AppLocalizations.of(context)!.translate('questionnaires')),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: '${AppLocalizations.of(context)!.translate("sentTab")} (${_sentList.length})'),
            Tab(text: '${AppLocalizations.of(context)!.translate("unsentTab")} (${_unsentList.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSearchBar(
              hint: AppLocalizations.of(context)!.translate('searchQuestionnaires'),
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
      return AppEmptyState(
        icon: Icons.quiz_outlined,
        title: AppLocalizations.of(context)!.translate('noSentQuestionnaires'),
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
      return AppEmptyState(
        icon: Icons.quiz_outlined,
        title: AppLocalizations.of(context)!.translate('noUnsentQuestionnaires'),
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
