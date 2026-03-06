import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orbit_app/core/constants/app_colors.dart';

/// A phone number input field with a country code prefix selector.
///
/// Displays a dropdown for the country code (defaulting to +966 for Saudi
/// Arabia) followed by the phone number text field. The widget reports the
/// full phone number (country code + local number) through [onChanged].
class PhoneInputField extends StatefulWidget {
  const PhoneInputField({
    super.key,
    this.controller,
    this.onChanged,
    this.errorText,
    this.hintText,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
  });

  /// Optional external controller for the phone number portion.
  final TextEditingController? controller;

  /// Called with the full phone number whenever the input changes.
  /// The value includes the country code prefix (e.g. "+966512345678").
  final ValueChanged<String>? onChanged;

  /// Validation error text shown below the field.
  final String? errorText;

  /// Hint text for the phone number portion.
  final String? hintText;

  /// Whether the field is enabled for editing.
  final bool enabled;

  /// Whether to auto-focus the phone field on mount.
  final bool autofocus;

  /// Optional focus node.
  final FocusNode? focusNode;

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late final TextEditingController _controller;
  String _selectedCode = '+966';

  static const List<_CountryCode> _countryCodes = [
    _CountryCode(code: '+966', flag: '\u{1F1F8}\u{1F1E6}', name: 'السعودية'),
    _CountryCode(code: '+971', flag: '\u{1F1E6}\u{1F1EA}', name: 'الإمارات'),
    _CountryCode(code: '+973', flag: '\u{1F1E7}\u{1F1ED}', name: 'البحرين'),
    _CountryCode(code: '+965', flag: '\u{1F1F0}\u{1F1FC}', name: 'الكويت'),
    _CountryCode(code: '+968', flag: '\u{1F1F4}\u{1F1F2}', name: 'عُمان'),
    _CountryCode(code: '+974', flag: '\u{1F1F6}\u{1F1E6}', name: 'قطر'),
    _CountryCode(code: '+20', flag: '\u{1F1EA}\u{1F1EC}', name: 'مصر'),
    _CountryCode(code: '+962', flag: '\u{1F1EF}\u{1F1F4}', name: 'الأردن'),
    _CountryCode(code: '+964', flag: '\u{1F1EE}\u{1F1F6}', name: 'العراق'),
    _CountryCode(code: '+961', flag: '\u{1F1F1}\u{1F1E7}', name: 'لبنان'),
    _CountryCode(code: '+967', flag: '\u{1F1FE}\u{1F1EA}', name: 'اليمن'),
    _CountryCode(code: '+249', flag: '\u{1F1F8}\u{1F1E9}', name: 'السودان'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_notifyChange);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_notifyChange);
    }
    super.dispose();
  }

  void _notifyChange() {
    widget.onChanged?.call('$_selectedCode${_controller.text}');
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? AppColors.error : AppColors.inputBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Country code dropdown
              _buildCountryCodeDropdown(),

              // Vertical divider
              Container(
                width: 1,
                height: 28,
                color: AppColors.inputBorder,
              ),

              // Phone number field
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: widget.focusNode,
                  autofocus: widget.autofocus,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'Cairo',
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? '5XXXXXXXX',
                    hintStyle: const TextStyle(
                      color: AppColors.inputHint,
                      fontSize: 15,
                      fontFamily: 'Cairo',
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Error text
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 4, left: 4),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCountryCodeDropdown() {
    final selected = _countryCodes.firstWhere(
      (c) => c.code == _selectedCode,
      orElse: () => _countryCodes.first,
    );

    return PopupMenuButton<String>(
      onSelected: (code) {
        setState(() => _selectedCode = code);
        _notifyChange();
      },
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => _countryCodes
          .map(
            (c) => PopupMenuItem<String>(
              value: c.code,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c.flag, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      c.code,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      c.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'Cairo',
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(selected.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                selected.code,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal model
// ---------------------------------------------------------------------------

class _CountryCode {
  const _CountryCode({
    required this.code,
    required this.flag,
    required this.name,
  });

  final String code;
  final String flag;
  final String name;
}
