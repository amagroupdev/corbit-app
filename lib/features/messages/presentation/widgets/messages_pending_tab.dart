import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/messages/data/models/message_model.dart';
import 'package:orbit_app/features/messages/presentation/controllers/messages_controller.dart';
import 'package:orbit_app/features/messages/presentation/widgets/message_card.dart';

/// Tab that shows only pending/under-review messages.
class MessagesPendingTab extends ConsumerWidget {
  const MessagesPendingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesListProvider);

    return messagesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'فشل تحميل الرسائل المعلقة',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(messagesListProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
      data: (paginated) {
        // Filter for pending/under-review messages
        final pendingMessages = paginated.data
            .where((msg) =>
                msg.status == MessageStatus.pending ||
                msg.status == MessageStatus.scheduled)
            .toList();

        if (pendingMessages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pending_outlined,
                    size: 64,
                    color: AppColors.textHint.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد رسائل معلقة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'جميع الرسائل تمت معالجتها',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(messagesListProvider),
          color: AppColors.primary,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: pendingMessages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return MessageCard(
                message: pendingMessages[index],
                onTap: () {},
              );
            },
          ),
        );
      },
    );
  }
}
