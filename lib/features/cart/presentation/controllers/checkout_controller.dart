import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/features/cart/data/models/payment_method_model.dart';
import 'package:orbit_app/features/cart/data/repositories/cart_repository.dart';

/// Lifecycle of the checkout flow.
enum CheckoutStatus { idle, processing, success, failed }

/// Result returned by the server on a successful checkout (mirrors the
/// `data` envelope of `POST /cart/checkout`).
class CheckoutSuccess {
  const CheckoutSuccess({
    this.transactionId,
    this.paymentUrl,
    this.message,
    this.raw = const {},
  });

  final String? transactionId;

  /// External URL the user should be redirected to (Mada/Visa/STC redirect).
  final String? paymentUrl;
  final String? message;
  final Map<String, dynamic> raw;

  factory CheckoutSuccess.fromJson(Map<String, dynamic> json) {
    return CheckoutSuccess(
      transactionId: json['transaction_id']?.toString() ??
          json['id']?.toString(),
      paymentUrl: json['payment_url']?.toString() ??
          json['redirect_url']?.toString() ??
          json['url']?.toString(),
      message: json['message']?.toString(),
      raw: json,
    );
  }
}

class CheckoutState {
  const CheckoutState({
    this.status = CheckoutStatus.idle,
    this.paymentMethod = CartPaymentMethods.mada,
    this.error,
    this.success,
  });

  final CheckoutStatus status;
  final String paymentMethod;
  final String? error;
  final CheckoutSuccess? success;

  bool get isProcessing => status == CheckoutStatus.processing;
  bool get isSuccess => status == CheckoutStatus.success;
  bool get isFailed => status == CheckoutStatus.failed;

  CheckoutState copyWith({
    CheckoutStatus? status,
    String? paymentMethod,
    Object? error = _sentinel,
    Object? success = _sentinel,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      error: identical(error, _sentinel) ? this.error : error as String?,
      success: identical(success, _sentinel)
          ? this.success
          : success as CheckoutSuccess?,
    );
  }

  static const _sentinel = Object();
}

class CheckoutController extends StateNotifier<CheckoutState> {
  CheckoutController(this._repository) : super(const CheckoutState());

  final CartRepository _repository;

  void selectPaymentMethod(String id) {
    if (!CartPaymentMethods.all.contains(id)) return;
    state = state.copyWith(paymentMethod: id);
  }

  /// Initiates `POST /cart/checkout`.
  ///
  /// Returns `true` when the server responded with a successful payload.
  Future<bool> submit({Map<String, dynamic>? extra}) async {
    state = state.copyWith(
      status: CheckoutStatus.processing,
      error: null,
      success: null,
    );

    final result = await _repository.checkout(
      paymentMethod: state.paymentMethod,
      extra: extra,
    );

    if (result.isSuccess) {
      state = state.copyWith(
        status: CheckoutStatus.success,
        success: CheckoutSuccess.fromJson(result.data ?? const {}),
        error: null,
      );
      return true;
    }

    state = state.copyWith(
      status: CheckoutStatus.failed,
      error: result.error,
      success: null,
    );
    return false;
  }

  void reset() {
    state = const CheckoutState();
  }
}

// ─── Provider ────────────────────────────────────────────────────────

final checkoutControllerProvider =
    StateNotifierProvider<CheckoutController, CheckoutState>((ref) {
  final repository = ref.watch(cartRepositoryProvider);
  return CheckoutController(repository);
});
