import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/voice_messages/presentation/controllers/voice_recorder_controller.dart';
import 'package:orbit_app/features/voice_messages/presentation/widgets/voice_player_widget.dart';

/// Visual recorder controls (record / pause / resume / stop / discard)
/// powered by [voiceRecorderControllerProvider].
///
/// Surfaces a preview of the captured file via [VoicePlayerWidget] once
/// recording stops.
class VoiceRecorderWidget extends ConsumerWidget {
  const VoiceRecorderWidget({super.key});

  String _format(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceRecorderControllerProvider);
    final controller = ref.read(voiceRecorderControllerProvider.notifier);
    final t = AppLocalizations.of(context);

    Widget statusLabel() {
      String key;
      Color color;
      switch (state.status) {
        case VoiceRecorderStatus.recording:
          key = 'voiceMessagesRecording';
          color = AppColors.error;
          break;
        case VoiceRecorderStatus.paused:
          key = 'voiceMessagesPaused';
          color = AppColors.info;
          break;
        case VoiceRecorderStatus.permissionDenied:
          key = 'voiceMessagesPermissionDenied';
          color = AppColors.error;
          break;
        case VoiceRecorderStatus.idle:
          key = state.hasRecording
              ? 'voiceMessagesReady'
              : 'voiceMessagesTapToRecord';
          color = state.hasRecording ? AppColors.success : AppColors.textHint;
          break;
      }
      return Text(
        t?.translate(key) ?? key,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _format(state.elapsed),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              statusLabel(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!state.isActive)
                    _RoundActionButton(
                      icon: Icons.mic,
                      color: AppColors.error,
                      label: t?.translate('voiceMessagesRecord') ?? 'Record',
                      onTap: controller.start,
                    ),
                  if (state.isRecording) ...[
                    _RoundActionButton(
                      icon: Icons.pause,
                      color: AppColors.info,
                      label: t?.translate('voiceMessagesPause') ?? 'Pause',
                      onTap: controller.pause,
                    ),
                    const SizedBox(width: 16),
                    _RoundActionButton(
                      icon: Icons.stop,
                      color: AppColors.error,
                      label: t?.translate('voiceMessagesStop') ?? 'Stop',
                      onTap: () => controller.stop(),
                    ),
                  ],
                  if (state.isPaused) ...[
                    _RoundActionButton(
                      icon: Icons.fiber_manual_record,
                      color: AppColors.error,
                      label: t?.translate('voiceMessagesResume') ?? 'Resume',
                      onTap: controller.resume,
                    ),
                    const SizedBox(width: 16),
                    _RoundActionButton(
                      icon: Icons.stop,
                      color: AppColors.textSecondary,
                      label: t?.translate('voiceMessagesStop') ?? 'Stop',
                      onTap: () => controller.stop(),
                    ),
                  ],
                  if (!state.isActive && state.hasRecording) ...[
                    const SizedBox(width: 16),
                    _RoundActionButton(
                      icon: Icons.delete_outline,
                      color: AppColors.textSecondary,
                      label: t?.translate('voiceMessagesDiscard') ?? 'Discard',
                      onTap: controller.discard,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (!state.isActive &&
            state.hasRecording &&
            state.recordingPath != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: VoicePlayerWidget(
              localPath: state.recordingPath,
              compact: true,
            ),
          ),
        ],
        if (state.error != null && state.error!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            state.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: Material(
            color: color,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
