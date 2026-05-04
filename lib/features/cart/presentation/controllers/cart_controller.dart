import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/features/cart/data/models/cart_model.dart';
import 'package:orbit_app/features/cart/data/repositories/cart_repository.dart';

/// Lifecycle / status of the cart.
enum CartStatus { idle, loading, ready, error }

/// Immutable state owned by [CartController].
class CartState {
  const CartState({
    this.status = CartStatus.idle,
    this.cart = const _EmptyCart(),
    this.error,
    this.actionInProgress = false,
    this.lastMessageKey,
    this.couponError,
  });

  final CartStatus status;
  final CartModel cart;
  final String? error;

  /// True while a write action (add/remove/clear/apply-coupon) is in flight.
  final bool actionInProgress;

  /// Localization key for the most recent transient action result, if any.
  /// Cleared by [CartController.consumeMessage].
  final String? lastMessageKey;

  /// Localization key for an inline coupon error (e.g. `cartCouponInvalid`).
  final String? couponError;

  CartState copyWith({
    CartStatus? status,
    CartModel? cart,
    Object? error = _sentinel,
    bool? actionInProgress,
    Object? lastMessageKey = _sentinel,
    Object? couponError = _sentinel,
  }) {
    return CartState(
      status: status ?? this.status,
      cart: cart ?? this.cart,
      error: identical(error, _sentinel) ? this.error : error as String?,
      actionInProgress: actionInProgress ?? this.actionInProgress,
      lastMessageKey: identical(lastMessageKey, _sentinel)
          ? this.lastMessageKey
          : lastMessageKey as String?,
      couponError: identical(couponError, _sentinel)
          ? this.couponError
          : couponError as String?,
    );
  }

  static const _sentinel = Object();
}

/// Convenience: an empty cart used as the initial value.
class _EmptyCart extends CartModel {
  const _EmptyCart()
      : super(
          id: 0,
          items: const [],
          subtotal: 0,
          discount: 0,
          total: 0,
        );
}

/// Owns the in-memory cart state and exposes mutating actions.
class CartController extends StateNotifier<CartState> {
  CartController(this._repository) : super(const CartState());

  final CartRepository _repository;

  // ─── Load ──────────────────────────────────────────────────────────

  Future<void> load() async {
    state = state.copyWith(status: CartStatus.loading, error: null);
    final result = await _repository.getCart();
    if (result.isSuccess) {
      state = state.copyWith(
        status: CartStatus.ready,
        cart: result.data!,
        error: null,
      );
    } else {
      state = state.copyWith(
        status: CartStatus.error,
        error: result.error,
      );
    }
  }

  Future<void> refresh() => load();

  // ─── Items ─────────────────────────────────────────────────────────

  Future<bool> addItem({
    required String itemType,
    required int itemId,
    int? senderId,
    int? addonId,
    int? quantity,
  }) async {
    state = state.copyWith(actionInProgress: true);
    final result = await _repository.addItem(
      itemType: itemType,
      itemId: itemId,
      senderId: senderId,
      addonId: addonId,
      quantity: quantity,
    );
    if (result.isSuccess) {
      state = state.copyWith(
        status: CartStatus.ready,
        cart: result.data!,
        actionInProgress: false,
        error: null,
        lastMessageKey: 'cartItemAdded',
      );
      return true;
    }
    state = state.copyWith(
      actionInProgress: false,
      error: result.error,
    );
    return false;
  }

  Future<bool> removeItem(int itemId) async {
    state = state.copyWith(actionInProgress: true);
    final result = await _repository.removeItem(itemId);
    if (result.isSuccess) {
      state = state.copyWith(
        cart: result.data!,
        actionInProgress: false,
        lastMessageKey: 'cartItemRemoved',
      );
      return true;
    }
    state = state.copyWith(
      actionInProgress: false,
      error: result.error,
    );
    return false;
  }

  Future<bool> clear() async {
    state = state.copyWith(actionInProgress: true);
    final result = await _repository.clearCart();
    if (result.isSuccess) {
      state = state.copyWith(
        cart: result.data!,
        actionInProgress: false,
        lastMessageKey: 'cartCleared',
      );
      return true;
    }
    state = state.copyWith(
      actionInProgress: false,
      error: result.error,
    );
    return false;
  }

  // ─── Coupons ───────────────────────────────────────────────────────

  Future<bool> applyCoupon(String code) async {
    state = state.copyWith(
      actionInProgress: true,
      couponError: null,
    );
    final result = await _repository.applyCoupon(code);
    if (result.isSuccess) {
      state = state.copyWith(
        cart: result.data!,
        actionInProgress: false,
        lastMessageKey: 'cartCouponApplied',
        couponError: null,
      );
      return true;
    }
    state = state.copyWith(
      actionInProgress: false,
      couponError: 'cartCouponInvalid',
      error: result.error,
    );
    return false;
  }

  Future<bool> removeCoupon() async {
    state = state.copyWith(actionInProgress: true);
    final result = await _repository.removeCoupon();
    if (result.isSuccess) {
      state = state.copyWith(
        cart: result.data!,
        actionInProgress: false,
        couponError: null,
      );
      return true;
    }
    state = state.copyWith(
      actionInProgress: false,
      error: result.error,
    );
    return false;
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  /// Reads (and clears) the latest transient message key.
  String? consumeMessage() {
    final key = state.lastMessageKey;
    if (key != null) {
      state = state.copyWith(lastMessageKey: null);
    }
    return key;
  }

  void clearError() {
    state = state.copyWith(error: null, couponError: null);
  }
}

// ─── Provider ────────────────────────────────────────────────────────

final cartControllerProvider =
    StateNotifierProvider<CartController, CartState>((ref) {
  final repository = ref.watch(cartRepositoryProvider);
  return CartController(repository);
});

/// Convenience provider exposing just the item count (for badges, …).
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartControllerProvider).cart.itemCount;
});
