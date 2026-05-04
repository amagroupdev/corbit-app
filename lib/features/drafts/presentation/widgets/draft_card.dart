import 'package:flutter/material.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/drafts/data/models/draft_data_model.dart';
import 'package:orbit_app/features/drafts/data/models/draft_model.dart';

/// Tappable card representing a single saved draft in the list screen.
///
/// Mirrors the visual language of `_TemplateListTile` (subtle shadow,
/// rounded card, primary-color accents) so the Drafts feature blends in
/// with the rest of the app.
class DraftCard extends StatelessWidget {
  const DraftCard({
    required this.draft,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  /// The draft to render.
  final DraftModel draft;

  /// Called when the user taps the card body.
  final VoidCallback onTap;

  /// Called when the user taps the trailing delete icon.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final preview = draft.preview();
    final hasBody = preview.isNotEmpty;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconFor(draft.messageType),
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),

              // ── Body
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type chip
                    Row(
                      children: [
                        _typeChip(t.translate(draft.messageType.labelKey)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatDate(draft.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Body preview
                    Text(
                      hasBody ? preview : t.translate('draftEmptyBody'),
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: hasBody
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                        fontStyle:
                            hasBody ? FontStyle.normal : FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Recipients summary
                    const SizedBox(height: 6),
                    _recipientsSummary(t),
                  ],
                ),
              ),

              // ── Delete action
              IconButton(
                onPressed: onDelete,
                tooltip: t.translate('draftDelete'),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Sub-widgets ──────────────────────────────────────────────────────────

  Widget _typeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _recipientsSummary(AppLocalizations t) {
    final data = draft.draftData;
    final segments = <String>[];

    if (data.numbers.isNotEmpty) {
      segments.add(t.translateWithParams(
        'draftNumbersSummary',
        {'count': '${data.numbers.length}'},
      ));
    }
    if (data.groupIds.isNotEmpty) {
      segments.add(t.translateWithParams(
        'draftGroupsSummary',
        {'count': '${data.groupIds.length}'},
      ));
    }
    if (data.numberIds.isNotEmpty) {
      segments.add(t.translateWithParams(
        'draftNumberIdsSummary',
        {'count': '${data.numberIds.length}'},
      ));
    }

    if (segments.isEmpty) {
      return Text(
        t.translate('draftNoRecipients'),
        style: const TextStyle(fontSize: 11.5, color: AppColors.textHint),
      );
    }

    return Text(
      segments.join('  •  '),
      style: const TextStyle(
        fontSize: 11.5,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static IconData _iconFor(DraftMessageType type) {
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

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d  $hh:$mm';
  }
}
