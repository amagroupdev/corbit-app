import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/auth/data/repositories/auth_repository.dart'
    show Result;
import 'package:orbit_app/features/cart/data/datasources/cart_remote_datasource.dart';
import 'package:orbit_app/features/cart/data/models/cart_model.dart';

/// Repository that wraps [CartRemoteDatasource] with unified error handling.
///
/// Every method returns a [Result<T>] so the presentation layer can react
/// to validation/API failures without `try/catch` everywhere.
class CartRepository {
  CartRepository(this._datasource);

  final CartRemoteDatasource _datasource;

  // ─── Read ──────────────────────────────────────────────────────────

  Future<Result<CartModel>> getCart() {
    return _guard(() => _datasource.getCart());
  }

  // ─── Items ─────────────────────────────────────────────────────────

  Future<Result<CartModel>> addItem({
    required String itemType,
    required int itemId,
    int? senderId,
    int? addonId,
    int? quantity,
  }) {
    return _guard(() => _datasource.addItem(
          itemType: itemType,
          itemId: itemId,
          senderId: senderId,
          addonId: addonId,
          quantity: quantity,
        ));
  }

  Future<Result<CartModel>> removeItem(int itemId) {
    return _guard(() => _datasource.removeItem(itemId));
  }

  Future<Result<CartModel>> clearCart() {
    return _guard(() => _datasource.clearCart());
  }

  // ─── Coupons ───────────────────────────────────────────────────────

  Future<Result<CartModel>> applyCoupon(String code) {
    return _guard(() => _datasource.applyCoupon(code));
  }

  Future<Result<CartModel>> removeCoupon() {
    return _guard(() => _datasource.removeCoupon());
  }

  // ─── Checkout ──────────────────────────────────────────────────────

  Future<Result<Map<String, dynamic>>> checkout({
    required String paymentMethod,
    Map<String, dynamic>? extra,
  }) {
    return _guard(() => _datasource.checkout(
          paymentMethod: paymentMethod,
          extra: extra,
        ));
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      final data = await body();
      return Result.success(data);
    } on ValidationException catch (e) {
      return Result.failure(e.message, fieldErrors: e.errors);
    } on ApiException catch (e) {
      return Result.failure(e.message);
    } catch (_) {
      return Result.failure('unexpectedError');
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final datasource = ref.watch(cartRemoteDatasourceProvider);
  return CartRepository(datasource);
});
