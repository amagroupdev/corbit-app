import 'package:flutter/material.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/constants/app_theme.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';

/// Input bar at the bottom of the AI chat screen.
///
/// Contains a text field and a send button. The send button is only
/// enabled when the text is not empty and the assistant is not streaming.
class AiInputBar extends StatefulWidget {
  const AiInputBar({
    required this.onSend,
    this.isStreaming = false,
    super.key,
  });

  /// Called with the message text when the user taps send.
  final void Function(String text) onSend;

  /// Whether the assistant is currently streaming a response.
  final bool isStreaming;

  @override
  State<AiInputBar> createState() => _AiInputBarState();
}

class _AiInputBarState extends State<AiInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isStreaming) return;

    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  bool get _canSend => _hasText && !widget.isStreaming;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Container(
      padding: EdgeInsets.only(
        left: AppTheme.spacingLg,
        right: AppTheme.spacingLg,
        top: AppTheme.spacingMd,
        bottom: MediaQuery.of(context).padding.bottom + AppTheme.spacingMd,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Text field ─────────────────────────────────────────────
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: AppColors.inputBorder, width: 1),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: t?.translate('aiInputHint') ??
                      (isRtl ? 'اكتب سؤالك...' : 'Type your question...'),
                  hintStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.inputHint,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLg,
                    vertical: AppTheme.spacingMd,
                  ),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),

          // ── Send button ────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: _canSend ? AppColors.primary : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusRound),
              child: InkWell(
                onTap: _canSend ? _handleSend : null,
                borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: Icon(
                    isRtl ? Icons.send_rounded : Icons.send_rounded,
                    size: 22,
                    color: _canSend
                        ? AppColors.textOnPrimary
                        : AppColors.textHint,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
