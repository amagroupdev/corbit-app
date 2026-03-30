import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/constants/app_theme.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/ai_assistant/data/models/ai_action_model.dart';
import 'package:orbit_app/features/ai_assistant/data/models/chat_message_model.dart';

/// A single chat bubble displaying a [ChatMessageModel].
///
/// User messages are right-aligned with the primary brand color.
/// Assistant messages are left-aligned with a neutral surface color
/// and support Markdown rendering plus tappable action chips.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    required this.message,
    this.onActionTap,
    super.key,
  });

  final ChatMessageModel message;

  /// Called when the user taps an action chip below an assistant message.
  final void Function(AiActionModel action)? onActionTap;

  bool get _isUser => message.isUser;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingXs,
      ),
      child: Row(
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Assistant avatar ────────────────────────────────────────
          if (!_isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primarySurface,
              child: const Icon(
                Icons.smart_toy_outlined,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
          ],

          // ── Bubble ─────────────────────────────────────────────────
          Flexible(
            child: Column(
              crossAxisAlignment: _isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLg,
                    vertical: AppTheme.spacingMd,
                  ),
                  decoration: BoxDecoration(
                    color: _isUser
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppTheme.radiusLg),
                      topRight: const Radius.circular(AppTheme.radiusLg),
                      bottomLeft: Radius.circular(
                        _isUser ? AppTheme.radiusLg : AppTheme.radiusXs,
                      ),
                      bottomRight: Radius.circular(
                        _isUser ? AppTheme.radiusXs : AppTheme.radiusLg,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _isUser
                      ? _buildUserText()
                      : _buildAssistantMarkdown(context),
                ),

                // ── Action chips ───────────────────────────────────────
                if (!_isUser && message.actions.isNotEmpty)
                  _buildActionChips(context),
              ],
            ),
          ),

          // ── User avatar spacer ─────────────────────────────────────
          if (_isUser) ...[
            const SizedBox(width: AppTheme.spacingSm),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: const Icon(
                Icons.person,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── User text ───────────────────────────────────────────────────────────

  Widget _buildUserText() {
    return Text(
      message.content,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textOnPrimary,
        height: 1.5,
      ),
    );
  }

  // ─── Assistant Markdown ──────────────────────────────────────────────────

  Widget _buildAssistantMarkdown(BuildContext context) {
    // Strip ```action blocks from displayed content.
    final cleanContent = message.content
        .replaceAll(RegExp(r'```action\s*\n[\s\S]*?\n```'), '')
        .trim();

    if (cleanContent.isEmpty) {
      return const SizedBox.shrink();
    }

    return MarkdownBody(
      data: cleanContent,
      selectable: true,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        strong: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        em: const TextStyle(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          color: AppColors.textPrimary,
        ),
        listBullet: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        code: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.primaryDark,
          backgroundColor: AppColors.primarySurface,
        ),
        codeblockDecoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        blockSpacing: AppTheme.spacingSm,
      ),
    );
  }

  // ─── Action chips ────────────────────────────────────────────────────────

  Widget _buildActionChips(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isArabic = t?.isRtl ?? true;

    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingSm),
      child: Wrap(
        spacing: AppTheme.spacingSm,
        runSpacing: AppTheme.spacingXs,
        children: message.actions.map((action) {
          final label = isArabic
              ? (action.labelAr ?? action.labelEn ?? action.type)
              : (action.labelEn ?? action.labelAr ?? action.type);

          return ElevatedButton.icon(
            onPressed: () => onActionTap?.call(action),
            icon: Icon(
              _actionIcon(action.type),
              size: 16,
            ),
            label: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primarySurface,
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                side: const BorderSide(
                  color: AppColors.primaryBorder,
                  width: 1,
                ),
              ),
              minimumSize: const Size(0, 36),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _actionIcon(String type) {
    return switch (type) {
      'navigate' => Icons.open_in_new_rounded,
      'suggest_link' => Icons.link_rounded,
      'create_group' => Icons.group_add_rounded,
      'create_template' => Icons.note_add_rounded,
      _ => Icons.touch_app_rounded,
    };
  }
}
