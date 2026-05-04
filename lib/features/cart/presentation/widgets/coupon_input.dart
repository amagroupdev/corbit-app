import 'package:flutter/material.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/cart/data/models/coupon_model.dart';

/// Inline coupon entry/management widget for the cart screen.
class CouponInput extends StatefulWidget {
  const CouponInput({
    super.key,
    required this.coupon,
    required this.onApply,
    required this.onRemove,
    this.applying = false,
    this.errorKey,
  });

  /// Currently applied coupon (null when none).
  final CouponModel? coupon;

  /// Called when the user submits a code to apply.
  final Future<void> Function(String code) onApply;

  /// Called when the user clicks the remove button.
  final Future<void> Function() onRemove;

  /// True while an apply/remove network call is in flight.
  final bool applying;

  /// Localization key for an inline error (e.g. `cartCouponInvalid`).
  final String? errorKey;

  @override
  State<CouponInput> createState() => _CouponInputState();
}

class _CouponInputState extends State<CouponInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final hasCoupon = widget.coupon != null;

    if (hasCoupon) {
      return _appliedRow(t);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !widget.applying,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: t?.translate('cartCouponPlaceholder') ??
                      'Enter coupon code',
                  prefixIcon: const Icon(Icons.local_offer_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onSubmitted: widget.applying ? null : _submit,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: widget.applying ? null : () => _submit(_controller.text),
              child: widget.applying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(t?.translate('cartCouponApply') ?? 'Apply'),
            ),
          ],
        ),
        if (widget.errorKey != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
            child: Text(
              t?.translate(widget.errorKey!) ?? widget.errorKey!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _appliedRow(AppLocalizations? t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t?.translate('cartCouponApplied') ?? 'Coupon applied',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                Text(
                  widget.coupon!.code,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: widget.applying ? null : () => widget.onRemove(),
            child: Text(t?.translate('cartCouponRemove') ?? 'Remove'),
          ),
        ],
      ),
    );
  }

  void _submit(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    widget.onApply(trimmed);
  }
}
