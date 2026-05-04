import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/voice_messages/data/models/voice_message_model.dart';
import 'package:orbit_app/features/voice_messages/presentation/widgets/voice_player_widget.dart';

/// Card-style row for a [VoiceMessageModel].
///
/// Renders the name + creation date, an inline audio player, and a
/// trailing delete button.
class VoiceMessageTile extends StatelessWidget {
  const VoiceMessageTile({
    super.key,
    required this.voice,
    required this.onDelete,
  });

  final VoiceMessageModel voice;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final dateFormat = intl.DateFormat('yyyy/MM/dd');

    final createdLabel = voice.createdAt != null
        ? dateFormat.format(voice.createdAt!)
        : '';
    final durationLabel = voice.formattedDuration;

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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.audiotrack_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voice.name.isEmpty
                          ? (t?.translate('voiceMessagesUntitled') ??
                              'Voice message')
                          : voice.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (durationLabel.isNotEmpty &&
                            durationLabel != '--:--')
                          durationLabel,
                        if (createdLabel.isNotEmpty) createdLabel,
                      ].join(' • '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                onPressed: onDelete,
                tooltip: t?.translate('voiceMessagesDelete') ?? 'Delete',
              ),
            ],
          ),
          if (voice.fileUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            VoicePlayerWidget(url: voice.fileUrl, compact: true),
          ],
        ],
      ),
    );
  }
}
