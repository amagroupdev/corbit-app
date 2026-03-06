import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';

/// Tab that shows message attachments.
class MessagesAttachmentsTab extends ConsumerStatefulWidget {
  const MessagesAttachmentsTab({super.key});

  @override
  ConsumerState<MessagesAttachmentsTab> createState() =>
      _MessagesAttachmentsTabState();
}

class _MessagesAttachmentsTabState
    extends ConsumerState<MessagesAttachmentsTab> {
  @override
  Widget build(BuildContext context) {
    // TODO: Implement attachments API integration
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_file_rounded,
              size: 64, color: AppColors.textHint.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'المرفقات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'استعرض جميع المرفقات المرسلة مع الرسائل',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.cloud_download_outlined,
                    size: 32, color: AppColors.primary),
                SizedBox(height: 8),
                Text(
                  'سيتم عرض المرفقات هنا عند إرسال رسائل مع ملفات',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
