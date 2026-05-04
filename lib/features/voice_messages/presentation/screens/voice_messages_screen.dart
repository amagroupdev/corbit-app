import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/voice_messages/data/models/voice_message_model.dart';
import 'package:orbit_app/features/voice_messages/presentation/controllers/voice_messages_controller.dart';
import 'package:orbit_app/features/voice_messages/presentation/widgets/voice_message_tile.dart';
import 'package:orbit_app/routing/route_names.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_search_bar.dart';

/// List screen for the user's saved voice messages.
class VoiceMessagesScreen extends ConsumerStatefulWidget {
  const VoiceMessagesScreen({super.key});

  @override
  ConsumerState<VoiceMessagesScreen> createState() =>
      _VoiceMessagesScreenState();
}

class _VoiceMessagesScreenState extends ConsumerState<VoiceMessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceMessagesControllerProvider.notifier).load();
    });
  }

  Future<void> _confirmDelete(VoiceMessageModel voice) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          t?.translate('voiceMessagesDelete') ?? 'Delete voice',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          '${t?.translate('voiceMessagesDeleteConfirm') ?? 'Delete'} "${voice.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t?.translate('cancel') ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(t?.translate('delete') ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final controller = ref.read(voiceMessagesControllerProvider.notifier);
    final ok = await controller.delete(voice.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (t?.translate('voiceMessagesDeleted') ?? 'Voice deleted')
              : (ref.read(voiceMessagesControllerProvider).error ??
                  (t?.translate('error') ?? 'Error')),
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _openRecorder() async {
    await context.pushNamed(RouteNames.recordVoice);
    // Refresh the list when we return — uploads inside the recorder
    // already update the controller, but we reload for safety after a
    // long pause.
    if (mounted) {
      await ref.read(voiceMessagesControllerProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(voiceMessagesControllerProvider);
    final controller = ref.read(voiceMessagesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(t?.translate('voiceMessagesTitle') ?? 'Voice messages'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSearchBar(
              hint: t?.translate('search') ?? 'Search',
              onChanged: controller.updateSearch,
            ),
          ),
          Expanded(child: _buildContent(state)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRecorder,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.mic),
        label: Text(t?.translate('voiceMessagesRecord') ?? 'Record'),
      ),
    );
  }

  Widget _buildContent(VoiceMessagesListState state) {
    final t = AppLocalizations.of(context);

    if (state.isLoading && state.items.isEmpty) {
      return AppLoading.listShimmer();
    }

    if (state.error != null && state.items.isEmpty) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () =>
            ref.read(voiceMessagesControllerProvider.notifier).load(),
      );
    }

    if (state.isEmpty) {
      return AppEmptyState(
        icon: Icons.audiotrack_outlined,
        title: t?.translate('voiceMessagesEmpty') ?? 'No voice messages',
        description:
            t?.translate('voiceMessagesEmptyDesc') ?? 'Record one to get started',
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(voiceMessagesControllerProvider.notifier).load(),
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          final voice = state.items[index];
          return VoiceMessageTile(
            voice: voice,
            onDelete: () => _confirmDelete(voice),
          );
        },
      ),
    );
  }
}
