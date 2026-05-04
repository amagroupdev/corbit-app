import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/drafts/data/models/draft_data_model.dart';
import 'package:orbit_app/features/drafts/presentation/controllers/drafts_controller.dart';
import 'package:orbit_app/features/drafts/presentation/controllers/drafts_form_controller.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';

/// Detail / edit screen for a single saved draft.
///
/// Loads the draft on mount, lets the user edit the message body
/// and basic recipient lists, and saves via PUT. Type and variant
/// are immutable from here — to switch variants the user must create
/// a new draft from the relevant compose screen.
class DraftDetailScreen extends ConsumerStatefulWidget {
  const DraftDetailScreen({required this.draftId, super.key});

  /// Database id of the draft to edit. `0` is treated as invalid.
  final int draftId;

  @override
  ConsumerState<DraftDetailScreen> createState() => _DraftDetailScreenState();
}

class _DraftDetailScreenState extends ConsumerState<DraftDetailScreen> {
  late final TextEditingController _bodyController;
  late final TextEditingController _numbersController;

  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _bodyController = TextEditingController();
    _numbersController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.draftId > 0) {
        ref.read(draftFormControllerProvider.notifier).load(widget.draftId);
      }
    });
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _numbersController.dispose();
    super.dispose();
  }

  void _seedControllersFromState(DraftFormState state) {
    if (_bootstrapped) return;
    if (state.isLoading || state.draftId == null) return;

    _bodyController.text = state.draftData.messageBody;
    _numbersController.text = state.draftData.numbers.join(', ');
    _bootstrapped = true;
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;

    // Sync editable text fields back into state.
    final notifier = ref.read(draftFormControllerProvider.notifier);
    notifier.setMessageBody(_bodyController.text);

    final numbers = _parseNumbers(_numbersController.text);
    notifier.setNumbers(numbers);

    final saved = await notifier.save();
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (saved != null) {
      // Reflect change in the list controller if it's mounted.
      ref.read(draftsListControllerProvider.notifier).replaceDraft(saved);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            t.translate('draftSaved'),
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            t.translate('draftSaveFailed'),
            style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static List<String> _parseNumbers(String raw) {
    return raw
        .split(RegExp(r'[,\n;]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final state = ref.watch(draftFormControllerProvider);
    _seedControllersFromState(state);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.translate('draftEdit')),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!state.isLoading && state.draftId != null)
            IconButton(
              icon: state.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              tooltip: t.translate('save'),
              onPressed: state.isSaving ? null : _save,
            ),
        ],
      ),
      body: _buildBody(t, state),
    );
  }

  Widget _buildBody(AppLocalizations t, DraftFormState state) {
    if (widget.draftId <= 0) {
      return AppErrorWidget(
        message: t.translate('draftLoadFailed'),
        onRetry: () => context.pop(),
      );
    }

    if (state.isLoading) {
      return AppLoading.fullScreen();
    }

    if (state.errorMessage != null && state.draftId == null) {
      return AppErrorWidget(
        message: t.translate('draftLoadFailed'),
        onRetry: () => ref
            .read(draftFormControllerProvider.notifier)
            .load(widget.draftId),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Type chip
          _typeBadge(t, state.messageType),

          const SizedBox(height: 20),

          // ── Numbers (only for to_number variant)
          if (state.messageType == DraftMessageType.toNumber) ...[
            _label(t.translate('draftRecipients')),
            const SizedBox(height: 6),
            TextField(
              controller: _numbersController,
              maxLines: 3,
              textDirection: TextDirection.ltr,
              decoration: _inputDecoration(t.translate('draftRecipientsHint')),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              t.translate('draftRecipientsHelp'),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 18),
          ],

          // ── Variant-specific summary (read-only) for non-text variants
          if (state.messageType != DraftMessageType.toNumber) ...[
            _readOnlySummary(t, state),
            const SizedBox(height: 18),
          ],

          // ── Message body
          _label(t.translate('draftBody')),
          const SizedBox(height: 6),
          TextField(
            controller: _bodyController,
            maxLines: 8,
            minLines: 5,
            decoration: _inputDecoration(t.translate('draftBodyHint')),
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),

          const SizedBox(height: 28),

          // ── Save button
          AppButton.primary(
            text: t.translate('save'),
            icon: Icons.save_rounded,
            onPressed: state.isSaving ? null : _save,
            isLoading: state.isSaving,
          ),

          if (state.savedAt != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                t.translate('draftSaved'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── UI helpers ───────────────────────────────────────────────────────────

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppColors.inputBorderFocused,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _typeBadge(AppLocalizations t, DraftMessageType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForType(type), size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            '${t.translate('draftMessageType')}: ${t.translate(type.labelKey)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlySummary(AppLocalizations t, DraftFormState state) {
    final data = state.draftData;
    final lines = <String>[
      if (data.groupIds.isNotEmpty)
        t.translateWithParams(
          'draftGroupsSummary',
          {'count': '${data.groupIds.length}'},
        ),
      if (data.numberIds.isNotEmpty)
        t.translateWithParams(
          'draftNumberIdsSummary',
          {'count': '${data.numberIds.length}'},
        ),
      if (data.voiceId != null)
        t.translateWithParams(
          'draftVoiceIdSummary',
          {'id': '${data.voiceId}'},
        ),
      if (data.cardType != null)
        t.translateWithParams(
          'draftCardTypeSummary',
          {'type': data.cardType ?? ''},
        ),
      if (data.templateId != null)
        t.translateWithParams(
          'draftTemplateIdSummary',
          {'id': '${data.templateId}'},
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(t.translate('draftRecipients')),
          const SizedBox(height: 8),
          if (lines.isEmpty)
            Text(
              t.translate('draftNoRecipients'),
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...lines.map(
              (l) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '•  $l',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static IconData _iconForType(DraftMessageType type) {
    switch (type) {
      case DraftMessageType.toNumber:
        return Icons.dialpad_rounded;
      case DraftMessageType.toGroup:
        return Icons.people_alt_rounded;
      case DraftMessageType.voice:
        return Icons.mic_rounded;
      case DraftMessageType.vipCard:
        return Icons.card_giftcard_rounded;
    }
  }
}
