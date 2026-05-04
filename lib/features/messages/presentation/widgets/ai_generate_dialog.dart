import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/messages/data/repositories/messages_repository.dart';

/// Available AI rewrite actions exposed by `POST /messages/ai-generate`.
enum AiGenerateAction {
  improve('improve', 'aiGenerateImprove'),
  shorten('shorten', 'aiGenerateShorten'),
  formal('formal', 'aiGenerateFormal'),
  expand('expand', 'aiGenerateExpand');

  const AiGenerateAction(this.value, this.labelKey);
  final String value;
  final String labelKey;
}

/// Modal bottom sheet that asks the gateway to rewrite a given seed text
/// using one of four predefined actions and lets the user accept the
/// generated result back into the message composer.
///
/// Returns the accepted text, or null if the user dismissed the sheet.
class AiGenerateDialog {
  static Future<String?> show(
    BuildContext context, {
    String initialText = '',
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _AiGenerateSheet(initialText: initialText),
      ),
    );
  }
}

class _AiGenerateSheet extends ConsumerStatefulWidget {
  const _AiGenerateSheet({required this.initialText});

  final String initialText;

  @override
  ConsumerState<_AiGenerateSheet> createState() => _AiGenerateSheetState();
}

class _AiGenerateSheetState extends ConsumerState<_AiGenerateSheet> {
  late final TextEditingController _seedController;
  AiGenerateAction _action = AiGenerateAction.improve;
  bool _loading = false;
  String? _error;
  String? _generated;

  @override
  void initState() {
    super.initState();
    _seedController = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final t = AppLocalizations.of(context)!;
    final seed = _seedController.text.trim();
    if (seed.isEmpty) {
      setState(() => _error = t.translate('aiGeneratePlaceholder'));
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _generated = null;
    });

    try {
      final repo = ref.read(messagesRepositoryProvider);
      final result = await repo.aiGenerate(
        text: seed,
        action: _action.value,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _generated = result.isEmpty ? null : result;
        if (result.isEmpty) _error = t.translate('aiGenerateFailed');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = t.translate('aiGenerateFailed');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  t.translate('aiGenerateTitle'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _seedController,
              maxLines: 4,
              minLines: 3,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: t.translate('aiGeneratePlaceholder'),
                filled: true,
                fillColor: AppColors.inputFill,
                contentPadding: const EdgeInsets.all(14),
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
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AiGenerateAction.values.map((action) {
                final selected = action == _action;
                return ChoiceChip(
                  selected: selected,
                  label: Text(t.translate(action.labelKey)),
                  selectedColor: AppColors.primarySurface,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: selected
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  onSelected: (_) => setState(() => _action = action),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _generate,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  _loading
                      ? t.translate('aiGenerateLoading')
                      : t.translate('aiGenerateAction'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.errorBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_generated != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  _generated!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, _generated),
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(
                    t.translate('aiGenerateUseText'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
