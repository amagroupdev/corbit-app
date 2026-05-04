import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/features/cart/data/models/cart_model.dart';

/// Remote data source for `/cart/*` endpoints.
///
/// Each method maps 1:1 to an API v3 endpoint and returns the parsed
/// [CartModel] (or the raw response for actions that don't return a cart).
class CartRemoteDatasource {
  CartRemoteDatasource(this._client);

  final ApiClient _client;

  // ─── Read ──────────────────────────────────────────────────────────

  /// GET /cart
  Future<CartModel> getCart() async {
    final response = await _client.get<Map<String, dynamic>>(ApiConstants.cart);
    return _parseCart(response.data);
  }

  // ─── Write ─────────────────────────────────────────────────────────

  /// POST /cart/items
  ///
  /// [itemType] must be one of `'package' | 'service' | 'sender'`.
  Future<CartModel> addItem({
    required String itemType,
    required int itemId,
    int? senderId,
    int? addonId,
    int? quantity,
  }) async {
    final body = <String, dynamic>{
      'item_type': itemType,
      'item_id': itemId,
      if (senderId != null) 'sender_id': senderId,
      if (addonId != null) 'addon_id': addonId,
      if (quantity != null) 'quantity': quantity,
    };

    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.cartItems,
      data: body,
    );
    return _parseCart(response.data);
  }

  /// DELETE /cart/items/{id}
  Future<CartModel> removeItem(int itemId) async {
    final response = await _client.delete<Map<String, dynamic>>(
      ApiConstants.cartItemDelete(itemId),
    );
    return _parseCart(response.data);
  }

  /// DELETE /cart/clear
  Future<CartModel> clearCart() async {
    final response = await _client.delete<Map<String, dynamic>>(
      ApiConstants.cartClear,
    );
    return _parseCart(response.data, allowEmpty: true);
  }

  // ─── Coupons ───────────────────────────────────────────────────────

  /// POST /cart/apply-coupon
  Future<CartModel> applyCoupon(String code) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.cartApplyCoupon,
      data: {'code': code},
    );
    return _parseCart(response.data);
  }

  /// DELETE /cart/remove-coupon
  Future<CartModel> removeCoupon() async {
    final response = await _client.delete<Map<String, dynamic>>(
      ApiConstants.cartRemoveCoupon,
    );
    return _parseCart(response.data);
  }

  // ─── Checkout ──────────────────────────────────────────────────────

  /// POST /cart/checkout
  ///
  /// [paymentMethod] must be one of:
  /// `'mada' | 'visa' | 'stc_pay' | 'sadad' | 'bank_transfer'`.
  ///
  /// Returns the raw response payload (may include payment URLs, OTP
  /// challenges, transaction IDs, …).
  Future<Map<String, dynamic>> checkout({
    required String paymentMethod,
    Map<String, dynamic>? extra,
  }) async {
    final body = <String, dynamic>{
      'payment_method': paymentMethod,
      if (extra != null) ...extra,
    };

    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.cartCheckout,
      data: body,
    );

    final payload = response.data ?? {};
    if (payload['data'] is Map<String, dynamic>) {
      return payload['data'] as Map<String, dynamic>;
    }
    return payload;
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  /// Parses `{ data: { cart: { … } } }` into a [CartModel].
  ///
  /// When [allowEmpty] is true and the server returns no cart payload
  /// (e.g. after a clear) an empty cart is returned instead of throwing.
  CartModel _parseCart(
    Map<String, dynamic>? body, {
    bool allowEmpty = false,
  }) {
    if (body == null) {
      if (allowEmpty) return CartModel.empty();
      throw StateError('Empty response body for cart endpoint.');
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final inner = data['cart'];
      if (inner is Map<String, dynamic>) {
        return CartModel.fromJson(inner);
      }
      // Some endpoints may return the cart at `data` level directly.
      return CartModel.fromJson(data);
    }

    if (allowEmpty) return CartModel.empty();
    return CartModel.fromJson(body);
  }
}

// ─── Provider ────────────────────────────────────────────────────────

final cartRemoteDatasourceProvider = Provider<CartRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CartRemoteDatasource(apiClient);
});
