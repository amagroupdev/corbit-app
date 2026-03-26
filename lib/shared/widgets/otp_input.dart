import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orbit_app/core/constants/app_colors.dart';

/// A custom OTP input widget that visually shows [boxCount] boxes (default 6)
/// and accepts up to [maxLength] digits.
///
/// Displays 6 boxes so the user sees a standard 6-digit code UI.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    this.controller,
    this.boxCount = 6,
    this.maxLength = 6,
    this.autoFocus = true,
    this.onChanged,
    this.onCompleted,
  });

  /// External controller – if provided, the widget uses it; otherwise creates
  /// its own.
  final TextEditingController? controller;

  /// Number of visible boxes (default 6).
  final int boxCount;

  /// Maximum characters accepted (default 6). Must be >= [boxCount].
  final int maxLength;

  /// Whether the hidden field is auto-focused.
  final bool autoFocus;

  /// Fires on every keystroke with the current value.
  final ValueChanged<String>? onChanged;

  /// Fires once the user has entered at least [boxCount] characters.
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _ownsController = false;

  String get _text => _controller.text;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (_ownsController) _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
    widget.onChanged?.call(_text);

    if (_text.length >= widget.boxCount && widget.onCompleted != null) {
      widget.onCompleted!(_text);
    }
  }

  void _requestFocus() {
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        onTap: _requestFocus,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Visual boxes ───────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.boxCount, (index) {
                final hasChar = index < _text.length;
                final isActive = index == _text.length && _focusNode.hasFocus;
                final isFilled = hasChar;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 60,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 6,
                    right: index == widget.boxCount - 1 ? 0 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: isFilled
                        ? AppColors.surface
                        : isActive
                            ? AppColors.primarySurface
                            : AppColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFilled
                          ? AppColors.primary
                          : isActive
                              ? AppColors.primary
                              : AppColors.inputBorder,
                      width: isActive || isFilled ? 1.5 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: hasChar
                      ? Text(
                          _text[index],
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : isActive
                          ? _BlinkingCursor()
                          : const SizedBox.shrink(),
                );
              }),
            ),

            // ── Hidden input field ─────────────────────────────────
            Opacity(
              opacity: 0,
              child: SizedBox(
                width: (48 + 12) * widget.boxCount.toDouble(),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.autoFocus,
                  keyboardType: TextInputType.number,
                  maxLength: widget.maxLength,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    color: Colors.transparent,
                    fontSize: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Blinking cursor indicator ────────────────────────────────────────────────

class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 2,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
