import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/occasion_cards/data/models/occasion_card_model.dart';
import 'package:orbit_app/features/occasion_cards/data/repositories/occasion_cards_repository.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';

/// Screen for managing occasion/greeting cards.
///
/// Shows a template gallery for sending new cards and an archive
/// of previously sent cards.
class OccasionCardsScreen extends ConsumerStatefulWidget {
  const OccasionCardsScreen({super.key});

  @override
  ConsumerState<OccasionCardsScreen> createState() =>
      _OccasionCardsScreenState();
}

class _OccasionCardsScreenState extends ConsumerState<OccasionCardsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Templates state
  List<OccasionCardTemplateModel> _templates = [];
  bool _templatesLoading = true;
  String? _templatesError;

  // Archive state
  List<OccasionCardModel> _archive = [];
  bool _archiveLoading = true;
  String? _archiveError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTemplates();
    _loadArchive();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _templatesLoading = true;
      _templatesError = null;
    });

    try {
      final repo = ref.read(occasionCardsRepositoryProvider);
      final templates = await repo.getTemplates();
      if (mounted) {
        setState(() {
          _templates = templates;
          _templatesLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _templatesError = e.message;
          _templatesLoading = false;
        });
      }
    }
  }

  Future<void> _loadArchive() async {
    setState(() {
      _archiveLoading = true;
      _archiveError = null;
    });

    try {
      final repo = ref.read(occasionCardsRepositoryProvider);
      final result = await repo.getArchive();
      if (mounted) {
        setState(() {
          _archive = result.data;
          _archiveLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _archiveError = e.message;
          _archiveLoading = false;
        });
      }
    }
  }

  Future<void> _sendCard(OccasionCardTemplateModel template) async {
    final messageController = TextEditingController();
    final numbersController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                '${AppLocalizations.of(context)!.translate("sendCardTitle")} ${template.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (template.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    template.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              const SizedBox(height: 16),
              AppTextField(
                label: AppLocalizations.of(context)!.translate('theMessage'),
                hint: AppLocalizations.of(context)!.translate('enterGreeting'),
                controller: messageController,
                maxLines: 3,
                validator: (v) => v == null || v.trim().isEmpty
                    ? AppLocalizations.of(context)!.translate('enterMessageValidation')
                    : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: AppLocalizations.of(context)!.translate('theNumbers'),
                hint: AppLocalizations.of(context)!.translate('enterNumbersSeparated'),
                controller: numbersController,
                maxLines: 2,
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.trim().isEmpty
                    ? AppLocalizations.of(context)!.translate('enterNumbersValidation')
                    : null,
              ),
              const SizedBox(height: 20),
              AppButton.primary(
                text: AppLocalizations.of(context)!.translate('submit'),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(ctx, true);
                  }
                },
                icon: Icons.send_rounded,
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        final numbers = numbersController.text
            .split(RegExp(r'[,\n\s]+'))
            .map((n) => n.trim())
            .where((n) => n.isNotEmpty)
            .toList();

        final repo = ref.read(occasionCardsRepositoryProvider);
        await repo.sendCard(
          templateId: template.id,
          message: messageController.text.trim(),
          groupIds: [],
          numbers: numbers,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('cardSent')),
              backgroundColor: AppColors.success,
            ),
          );
          _loadArchive();
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
          );
        }
      }
    }

    messageController.dispose();
    numbersController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('occasionCards')),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.translate('templatesTab')),
            Tab(text: AppLocalizations.of(context)!.translate('archiveTab')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTemplatesTab(),
          _buildArchiveTab(),
        ],
      ),
    );
  }

  Widget _buildTemplatesTab() {
    if (_templatesLoading) return AppLoading.listShimmer();
    if (_templatesError != null) {
      return AppErrorWidget(message: _templatesError!, onRetry: _loadTemplates);
    }
    if (_templates.isEmpty) {
      return AppEmptyState(
        icon: Icons.card_giftcard_outlined,
        title: AppLocalizations.of(context)!.translate('noCardTemplates'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTemplates,
      color: AppColors.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: _templates.length,
        itemBuilder: (_, index) {
          final template = _templates[index];
          return _TemplateCard(
            template: template,
            onTap: () => _sendCard(template),
          );
        },
      ),
    );
  }

  Widget _buildArchiveTab() {
    if (_archiveLoading) return AppLoading.listShimmer();
    if (_archiveError != null) {
      return AppErrorWidget(message: _archiveError!, onRetry: _loadArchive);
    }
    if (_archive.isEmpty) {
      return AppEmptyState(
        icon: Icons.card_giftcard_outlined,
        title: AppLocalizations.of(context)!.translate('noSentCards'),
      );
    }

    final dateFormat = intl.DateFormat('yyyy/MM/dd', 'ar');

    return RefreshIndicator(
      onRefresh: _loadArchive,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _archive.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final card = _archive[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.card_giftcard, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.templateName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${card.recipientCount} ${AppLocalizations.of(context)!.translate("recipientUnit")} \u2022 ${dateFormat.format(card.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onTap});

  final OccasionCardTemplateModel template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: template.imageUrl.isNotEmpty
                      ? Image.network(
                          template.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.primarySurface,
                            child: const Icon(Icons.card_giftcard, size: 40, color: AppColors.primary),
                          ),
                        )
                      : Container(
                          color: AppColors.primarySurface,
                          child: const Icon(Icons.card_giftcard, size: 40, color: AppColors.primary),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  template.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
