import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:orbit_app/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:orbit_app/features/cart/presentation/widgets/cart_summary_card.dart';
import 'package:orbit_app/features/cart/presentation/widgets/coupon_input.dart';
import 'package:orbit_app/routing/route_names.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';

/// Cart screen — `/cart`.
///
/// Lists everything the user has queued for purchase, lets them
/// remove items, apply/remove coupons, and proceed to checkout.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  int? _removingItemId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(cartControllerProvider);
    final controller = ref.read(cartControllerProvider.notifier);

    // Surface transient messages.
    ref.listen<CartState>(cartControllerProvider, (prev, next) {
      final key = next.lastMessageKey;
      if (key != null && prev?.lastMessageKey != key) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.showSnackBar(
          SnackBar(content: Text(t?.translate(key) ?? key)),
        );
        controller.consumeMessage();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(t?.translate('cartTitle') ?? 'Cart'),
        actions: [
          if (state.cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: t?.translate('cartClear') ?? 'Clear',
              onPressed: state.actionInProgress
                  ? null
                  : () => _confirmClear(context, controller),
            ),
        ],
      ),
      body: _buildBody(context, state, controller),
      bottomNavigationBar: state.cart.isNotEmpty
          ? _buildCheckoutBar(context, state, t)
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    CartState state,
    CartController controller,
  ) {
    final t = AppLocalizations.of(context);

    if (state.status == CartStatus.loading && state.cart.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == CartStatus.error && state.cart.isEmpty) {
      return _buildError(context, state.error, controller);
    }

    if (state.cart.isEmpty) {
      return _buildEmpty(context, t);
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final item in state.cart.items)
            CartItemTile(
              item: item,
              removing: _removingItemId == item.id && state.actionInProgress,
              onRemove: () async {
                setState(() => _removingItemId = item.id);
                await controller.removeItem(item.id);
                if (mounted) setState(() => _removingItemId = null);
              },
            ),
          const SizedBox(height: 16),
          CouponInput(
            coupon: state.cart.coupon,
            applying: state.actionInProgress,
            errorKey: state.couponError,
            onApply: (code) async {
              await controller.applyCoupon(code);
            },
            onRemove: () async {
              await controller.removeCoupon();
            },
          ),
          const SizedBox(height: 16),
          CartSummaryCard(cart: state.cart),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, AppLocalizations? t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined,
                size: 96, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              t?.translate('cartEmpty') ?? 'Your cart is empty',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    String? error,
    CartController controller,
  ) {
    final t = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 72, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(
              error ?? t?.translate('error') ?? 'Error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButton.primary(
              text: t?.translate('retry') ?? 'Retry',
              onPressed: () => controller.refresh(),
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutBar(
      BuildContext context, CartState state, AppLocalizations? t) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: AppButton.primary(
          text: t?.translate('cartContinueToCheckout') ??
              'Continue to checkout',
          isLoading: state.actionInProgress,
          onPressed: state.actionInProgress
              ? null
              : () => context.pushNamed(RouteNames.checkout),
        ),
      ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    CartController controller,
  ) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t?.translate('cartClear') ?? 'Clear cart'),
        content: Text(
          t?.translate('cartClearConfirm') ??
              'Are you sure you want to remove all items?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t?.translate('cancel') ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t?.translate('confirm') ?? 'Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.clear();
    }
  }
}
