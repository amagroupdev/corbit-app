import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:orbit_app/features/cart/presentation/controllers/checkout_controller.dart';
import 'package:orbit_app/features/cart/presentation/widgets/cart_summary_card.dart';
import 'package:orbit_app/features/cart/presentation/widgets/payment_method_selector.dart';
import 'package:orbit_app/routing/route_names.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';

/// Checkout screen — `/checkout`.
///
/// Displays a final summary, payment-method selector, and a Pay button.
/// Submits `POST /cart/checkout` and either:
/// - Forwards to the embedded payment WebView when the server returns a URL.
/// - Shows a success/failure dialog otherwise.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cartState = ref.watch(cartControllerProvider);
    final checkoutState = ref.watch(checkoutControllerProvider);
    final checkoutCtrl = ref.read(checkoutControllerProvider.notifier);
    final cartCtrl = ref.read(cartControllerProvider.notifier);

    // React to checkout success / failure once.
    ref.listen<CheckoutState>(checkoutControllerProvider, (prev, next) async {
      if (next.isSuccess && prev?.status != CheckoutStatus.success) {
        await _onCheckoutSuccess(context, next, cartCtrl);
      } else if (next.isFailed && prev?.status != CheckoutStatus.failed) {
        _showFailureSnackBar(context, t, next.error);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(t?.translate('checkoutTitle') ?? 'Checkout'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary
            Text(
              t?.translate('checkoutSummary') ?? 'Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            CartSummaryCard(cart: cartState.cart),

            const SizedBox(height: 24),

            // Payment method selection
            Text(
              t?.translate('checkoutPaymentMethod') ?? 'Payment method',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            CartPaymentMethodSelector(
              selected: checkoutState.paymentMethod,
              onSelected: checkoutCtrl.selectPaymentMethod,
            ),

            const SizedBox(height: 24),

            // Pay button
            AppButton.primary(
              text: t?.translate('checkoutPay') ?? 'Pay',
              isLoading: checkoutState.isProcessing,
              isDisabled: cartState.cart.isEmpty,
              onPressed: cartState.cart.isEmpty
                  ? null
                  : () async {
                      await checkoutCtrl.submit();
                    },
            ),

            if (checkoutState.isProcessing) ...[
              const SizedBox(height: 16),
              Text(
                t?.translate('checkoutProcessing') ?? 'Processing payment...',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onCheckoutSuccess(
    BuildContext context,
    CheckoutState state,
    CartController cartCtrl,
  ) async {
    final t = AppLocalizations.of(context);
    final success = state.success;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final checkoutLabel = t?.translate('checkoutTitle') ?? 'Checkout';
    final successLabel = t?.translate('checkoutSuccess') ?? 'Payment successful';

    // If the server returned a payment URL, forward to the embedded WebView.
    if (success?.paymentUrl != null && success!.paymentUrl!.isNotEmpty) {
      await context.pushNamed(
        RouteNames.paymentWebView,
        extra: {
          'url': success.paymentUrl!,
          'title': checkoutLabel,
        },
      );
      // Refresh the cart in case the payment cleared it.
      await cartCtrl.refresh();
      if (mounted) navigator.maybePop();
      return;
    }

    // No URL → show success snack bar then pop back to cart/balance.
    messenger?.showSnackBar(
      SnackBar(content: Text(successLabel)),
    );
    await cartCtrl.refresh();
    if (mounted) navigator.maybePop();
  }

  void _showFailureSnackBar(
      BuildContext context, AppLocalizations? t, String? error) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(error ?? t?.translate('checkoutFailed') ?? 'Payment failed'),
      ),
    );
  }
}
