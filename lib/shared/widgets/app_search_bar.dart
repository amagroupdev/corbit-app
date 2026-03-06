import 'dart:async';

import 'package:flutter/material.dart';
import 'package:orbit_app/core/constants/app_colors.dart';

/// A styled search bar with debounced input, clear button, and consistent
/// ORBIT theming.
///
/// The [onChanged] callback fires after the user stops typing for 300 ms
/// (configurable via [debounceDuration]).
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.focusNode,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.enabled = true,
    this.autofocus = false,
    super.key,
  });

  /// Placeholder text. Defaults to a generic Arabic "Search..." label.
  final String? hint;

  /// Fires after a debounce period each time the text changes.
  final ValueChanged<String>? onChanged;

  /// Fires when the user presses the search / enter key.
  final ValueChanged<String>? onSubmitted;

  /// Optional external text controller.
  final TextEditingController? controller;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Debounce duration for [onChanged]. Defaults to 300 ms.
  final Duration debounceDuration;

  /// Whether the field is interactive.
  final bool enabled;

  /// Whether the field should request focus on mount.
  final bool autofocus;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounce;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }

    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onChanged?.call(_controller.text.trim());
    });
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: widget.hint ??
            '\u0628\u062D\u062B...', // بحث...
        hintStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.inputHint,
        ),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textHint,
          size: 22,
        ),
        suffixIcon: _hasText
            ? IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textHint,
                  size: 20,
                ),
                onPressed: _clear,
                splashRadius: 20,
              )
            : null,
        border: _buildBorder(),
        enabledBorder: _buildBorder(),
        focusedBorder: _buildBorder(color: AppColors.inputBorderFocused),
        disabledBorder: _buildBorder(),
      ),
    );
  }

  OutlineInputBorder _buildBorder({Color? color}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: color ?? Colors.transparent,
        width: color != null ? 1.5 : 0,
      ),
    );
  }
}
