import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/occasion_cards/data/models/occasion_card_model.dart';
import 'package:orbit_app/features/occasion_cards/data/repositories/occasion_cards_repository.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// Dedicated screen for composing and sending occasion cards.
///
/// Flow:
/// 1. Load templates from `GET /occasion-cards/templates`.
/// 2. User picks one + types numbers + greeting.
/// 3. Optional preview via `POST /occasion-cards/preview` (peeks at the
///    rendered text).
/// 4. Final submit via `POST /occasion-cards/send`.
class OccasionCardsSendScreen extends ConsumerStatefulWidget {
  const OccasionCardsSendScreen({super.key});

  @override
  ConsumerState<OccasionCardsSendScreen> createState() =>
      _OccasionCardsSendScreenState();
}

class _OccasionCardsSendScreenState
    extends ConsumerState<OccasionCardsSendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _numbersController = TextEditingController();

  List<OccasionCardTemplateModel> _templates = const [];
  OccasionCardTemplateModel? _selectedTemplate;

  bool _loadingTemplates = true;
  String? _templatesError;
  bool _submitting = false;
  bool _previewing = false;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _numbersController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _loadingTemplates = true;
      _templatesError = null;
    });
    try {
      final repo = ref.read(occasionCardsRepositoryProvider);
      final templates = await repo.getTemplates();
      if (!mounted) return;
      setState(() {
        _templates = templates;
        _selectedTemplate = templates.isNotEmpty ? templates.first : null;
        _loadingTemplates = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingTemplates = false;
        _templatesError = e.message;
      });
    }
  }

  List<String> _parseNumbers() {
    return _numbersController.text
        .split(RegExp(r'[,\n\s]+'))
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();
  }

  Future<void> _preview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTemplate == null) return;
    final t = AppLocalizations.of(context)!;

    setState(() => _previewing = true);
    try {
      final repo = ref.read(occasionCardsRepositoryProvider);
      final result = await repo.preview(
        templateId: _selectedTemplate!.id,
        message: _messageController.text.trim(),
        numbers: _parseNumbers(),
      );

      if (!mounted) return;
      final previewText = (result['preview'] as String?) ??
          (result['message'] as String?) ??
          _messageController.text.trim();
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.translate('occasionCardsPreviewTitle')),
          content: SingleChildScrollView(child: Text(previewText)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.translate('close')),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTemplate == null) return;
    final t = AppLocalizations.of(context)!;

    setState(() => _submitting = true);
    try {
      final repo = ref.read(occasionCardsRepositoryProvider);
      await repo.sendCard(
        templateId: _selectedTemplate!.id,
        message: _messageController.text.trim(),
        numbers: _parseNumbers(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.translate('occasionCardsSent')),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(t.translate('occasionCardsSendTitle')),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _buildBody(t),
    );
  }

  Widget _buildBody(AppLocalizations t) {
    if (_loadingTemplates) return AppLoading.listShimmer();
    if (_templatesError != null) {
      return AppErrorWidget(message: _templatesError!, onRetry: _loadTemplates);
    }
    if (_templates.isEmpty) {
      return AppEmptyState(
        icon: Icons.card_giftcard_outlined,
        title: t.translate('noCardTemplates'),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            t.translate('occasionCardsTemplate'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _templates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final tpl = _templates[i];
                final selected = _selectedTemplate?.id == tpl.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTemplate = tpl),
                  child: Container(
                    width: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: tpl.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: tpl.imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.primarySurface,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.card_giftcard,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.primarySurface,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.card_giftcard,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: t.translate('theMessage'),
            hint: t.translate('enterGreeting'),
            controller: _messageController,
            maxLines: 4,
            validator: (v) => v == null || v.trim().isEmpty
                ? t.translate('enterMessageValidation')
                : null,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: t.translate('theNumbers'),
            hint: t.translate('enterNumbersSeparated'),
            controller: _numbersController,
            maxLines: 3,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return t.translate('enterNumbersValidation');
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  text: t.translate('preview'),
                  onPressed: _previewing ? null : _preview,
                  isLoading: _previewing,
                  icon: Icons.visibility_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton.primary(
                  text: t.translate('submit'),
                  onPressed: _submitting ? null : _send,
                  isLoading: _submitting,
                  icon: Icons.send_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
