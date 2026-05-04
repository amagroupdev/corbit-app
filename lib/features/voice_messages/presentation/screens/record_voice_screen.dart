import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/voice_messages/presentation/controllers/voice_messages_controller.dart';
import 'package:orbit_app/features/voice_messages/presentation/controllers/voice_recorder_controller.dart';
import 'package:orbit_app/features/voice_messages/presentation/widgets/voice_recorder_widget.dart';

/// Full-screen recorder + uploader.
///
/// Wraps [VoiceRecorderWidget] and adds a name field plus the upload
/// CTA. Uploading delegates to [voiceMessagesControllerProvider] so the
/// list view picks up the new entry automatically.
class RecordVoiceScreen extends ConsumerStatefulWidget {
  const RecordVoiceScreen({super.key});

  @override
  ConsumerState<RecordVoiceScreen> createState() => _RecordVoiceScreenState();
}

class _RecordVoiceScreenState extends ConsumerState<RecordVoiceScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onUpload() async {
    final recorderState = ref.read(voiceRecorderControllerProvider);
    final path = recorderState.recordingPath;
    if (path == null || path.isEmpty || recorderState.isActive) return;

    final t = AppLocalizations.of(context);
    final controller = ref.read(voiceMessagesControllerProvider.notifier);
    final created = await controller.upload(
      filePath: path,
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
    );

    if (!mounted) return;

    if (created != null) {
      ref.read(voiceRecorderControllerProvider.notifier).clear();
      _nameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t?.translate('voiceMessagesUploaded') ?? 'Voice uploaded',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      if (context.canPop()) {
        context.pop();
      }
    } else {
      final state = ref.read(voiceMessagesControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.error ??
                (t?.translate('voiceMessagesUploadFailed') ?? 'Upload failed'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final recorderState = ref.watch(voiceRecorderControllerProvider);
    final listState = ref.watch(voiceMessagesControllerProvider);

    final canUpload =
        !recorderState.isActive && recorderState.hasRecording && !listState.isUploading;

    return Scaffold(
      appBar: AppBar(
        title: Text(t?.translate('voiceMessagesRecord') ?? 'Record voice'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const VoiceRecorderWidget(),
              const SizedBox(height: 24),
              Text(
                t?.translate('voiceMessagesName') ?? 'Name',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: t?.translate('voiceMessagesNamePlaceholder') ??
                      'Optional name',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (listState.isUploading) ...[
                LinearProgressIndicator(
                  value: listState.uploadProgress > 0
                      ? listState.uploadProgress.clamp(0.0, 1.0)
                      : null,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: canUpload ? _onUpload : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    t?.translate('voiceMessagesUpload') ?? 'Upload',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
