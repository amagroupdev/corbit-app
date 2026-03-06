import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orbit_app/core/constants/app_colors.dart';

/// A styled text input field with label, validation, and RTL support.
///
/// Features:
/// - Floating label above the field
/// - Rounded border with focus/error highlighting
/// - Suffix & prefix icon support
/// - Built-in obscure-text toggle for password fields
class AppTextField extends StatefulWidget {
  const AppTextField({
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.readOnly = false,
    this.onTap,
    this.initialValue,
    this.contentPadding,
    this.fillColor,
    super.key,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? initialValue;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscured = widget.obscureText;
    }
  }

  void _toggleObscure() {
    setState(() => _obscured = !_obscured);
  }

  static const double _borderRadius = 12;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Label ─────────────────────────────────────────────
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // ── Field ─────────────────────────────────────────────
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          obscureText: _obscured,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          focusNode: widget.focusNode,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          maxLength: widget.maxLength,
          autofillHints: widget.autofillHints,
          textCapitalization: widget.textCapitalization,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: widget.enabled
                ? AppColors.textPrimary
                : AppColors.textDisabled,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.inputHint,
            ),
            filled: true,
            fillColor: widget.fillColor ??
                (widget.enabled
                    ? AppColors.surface
                    : AppColors.surfaceVariant),
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: widget.prefixIcon,
            suffixIcon: _buildSuffixIcon(),
            counterText: '',
            border: _buildBorder(AppColors.inputBorder),
            enabledBorder: _buildBorder(AppColors.inputBorder),
            focusedBorder: _buildBorder(AppColors.inputBorderFocused, width: 1.5),
            errorBorder: _buildBorder(AppColors.inputBorderError),
            focusedErrorBorder:
                _buildBorder(AppColors.inputBorderError, width: 1.5),
            disabledBorder: _buildBorder(AppColors.inputBorderDisabled),
            errorStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    // If the field is a password field, show the toggle icon.
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscured
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppColors.textHint,
          size: 22,
        ),
        onPressed: _toggleObscure,
        splashRadius: 20,
      );
    }
    return widget.suffixIcon;
  }

  OutlineInputBorder _buildBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_borderRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
