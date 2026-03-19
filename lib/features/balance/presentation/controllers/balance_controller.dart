import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/balance/data/models/balance_model.dart';
import 'package:orbit_app/features/balance/data/models/bank_model.dart';
import 'package:orbit_app/features/balance/data/models/offer_model.dart';
import 'package:orbit_app/features/balance/data/models/price_tier_model.dart';
import 'package:orbit_app/features/balance/data/models/transaction_model.dart';
import 'package:orbit_app/features/balance/data/repositories/balance_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// STATE CLASSES
// ═══════════════════════════════════════════════════════════════════════

/// State for the main balance screen.
class BalanceScreenState {
  const BalanceScreenState({
    this.balance,
    this.offers = const [],
    this.recentTransactions = const [],
    this.isLoading = false,
    this.error,
  });

  final BalanceModel? balance;
  final List<OfferModel> offers;
  final List<TransactionModel> recentTransactions;
  final bool isLoading;
  final String? error;

  BalanceScreenState copyWith({
    BalanceModel? balance,
    List<OfferModel>? offers,
    List<TransactionModel>? recentTransactions,
    bool? isLoading,
    String? error,
  }) {
    return BalanceScreenState(
      balance: balance ?? this.balance,
      offers: offers ?? this.offers,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// State for the transactions listing screen.
class TransactionsState {
  const TransactionsState({
    this.transactions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.statusFilter,
    this.dateFrom,
    this.dateTo,
    this.search = '',
  });

  final List<TransactionModel> transactions;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? statusFilter;
  final String? dateFrom;
  final String? dateTo;
  final String search;

  bool get hasMore => currentPage < lastPage;
  bool get isEmpty => transactions.isEmpty && !isLoading;

  TransactionsState copyWith({
    List<TransactionModel>? transactions,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    int? lastPage,
    int? total,
    String? statusFilter,
    String? dateFrom,
    String? dateTo,
    String? search,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      statusFilter: statusFilter ?? this.statusFilter,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      search: search ?? this.search,
    );
  }
}

/// State for the buy balance screen.
class BuyBalanceState {
  const BuyBalanceState({
    this.priceTiers = const [],
    this.banks = const [],
    this.calculation,
    this.isCalculating = false,
    this.isPurchasing = false,
    this.purchaseResult,
    this.error,
    this.selectedPaymentMethod = 'online',
    this.awaitingOtp = false,
    this.transactionId,
  });

  final List<PriceTierModel> priceTiers;
  final List<BankModel> banks;
  final Map<String, dynamic>? calculation;
  final bool isCalculating;
  final bool isPurchasing;
  final Map<String, dynamic>? purchaseResult;
  final String? error;
  final String selectedPaymentMethod;
  final bool awaitingOtp;
  final String? transactionId;

  BuyBalanceState copyWith({
    List<PriceTierModel>? priceTiers,
    List<BankModel>? banks,
    Map<String, dynamic>? calculation,
    bool? isCalculating,
    bool? isPurchasing,
    Map<String, dynamic>? purchaseResult,
    String? error,
    String? selectedPaymentMethod,
    bool? awaitingOtp,
    String? transactionId,
  }) {
    return BuyBalanceState(
      priceTiers: priceTiers ?? this.priceTiers,
      banks: banks ?? this.banks,
      calculation: calculation ?? this.calculation,
      isCalculating: isCalculating ?? this.isCalculating,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      purchaseResult: purchaseResult ?? this.purchaseResult,
      error: error,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      awaitingOtp: awaitingOtp ?? this.awaitingOtp,
      transactionId: transactionId ?? this.transactionId,
    );
  }
}

/// State for the transfer balance screen.
class TransferBalanceState {
  const TransferBalanceState({
    this.isTransferring = false,
    this.transferResult,
    this.error,
    this.history = const [],
    this.isLoadingHistory = false,
  });

  final bool isTransferring;
  final Map<String, dynamic>? transferResult;
  final String? error;
  final List<Map<String, dynamic>> history;
  final bool isLoadingHistory;

  TransferBalanceState copyWith({
    bool? isTransferring,
    Map<String, dynamic>? transferResult,
    String? error,
    List<Map<String, dynamic>>? history,
    bool? isLoadingHistory,
  }) {
    return TransferBalanceState(
      isTransferring: isTransferring ?? this.isTransferring,
      transferResult: transferResult ?? this.transferResult,
      error: error,
      history: history ?? this.history,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// BALANCE SCREEN CONTROLLER
// ═══════════════════════════════════════════════════════════════════════

class BalanceScreenController extends StateNotifier<BalanceScreenState> {
  BalanceScreenController(this._repository)
      : super(const BalanceScreenState());

  final BalanceRepository _repository;

  /// Load all data for the balance overview screen.
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _repository.getCurrentBalance(),
        _repository.getOffers(),
        _repository.getTransactions(perPage: 5),
        _repository.getBalanceSummary(),
      ]);

      final currentBalance = results[0] as BalanceModel;
      final summary = results[3] as BalanceSummaryModel;

      // Merge summary data (total_purchased, total_sent, total_transferred) into the balance model
      // since /balance/current doesn't return those fields.
      
      debugPrint('[BalanceController] currentBalance: ${currentBalance.balance}, totalSent: ${currentBalance.totalSent}, totalPurchased: ${currentBalance.totalPurchased}');
      debugPrint('[BalanceController] summary: currentBalance: ${summary.currentBalance}, totalSent: ${summary.totalSent}, totalPurchased: ${summary.totalPurchased}');
      
      // Get the best values from both responses
      final balanceValue = currentBalance.balance > 0
          ? currentBalance.balance
          : summary.currentBalance;
      final totalPurchasedValue = currentBalance.totalPurchased > 0
          ? currentBalance.totalPurchased
          : summary.totalPurchased;
      
      debugPrint('[BalanceController] balanceValue: $balanceValue, totalPurchasedValue: $totalPurchasedValue');
      
      // Calculate consumed (total_sent) if API returns 0
      // Consumed = Total Purchased - Current Balance
      int totalSentValue = currentBalance.totalSent > 0
          ? currentBalance.totalSent
          : summary.totalSent;
      debugPrint('[BalanceController] totalSentValue before calc: $totalSentValue');
      if (totalSentValue == 0 && totalPurchasedValue > 0 && balanceValue > 0) {
        totalSentValue = (totalPurchasedValue - balanceValue).toInt();
        if (totalSentValue < 0) totalSentValue = 0;
        debugPrint('[BalanceController] totalSentValue after calc: $totalSentValue');
      }
      
      final mergedBalance = BalanceModel(
        balance: balanceValue,
        formattedBalance: currentBalance.formattedBalance,
        expiredAt: currentBalance.expiredAt ?? summary.expiredAt,
        remainingDays: currentBalance.remainingDays > 0
            ? currentBalance.remainingDays
            : summary.remainingDays,
        totalSent: totalSentValue,
        totalPurchased: totalPurchasedValue,
        totalTransferred: currentBalance.totalTransferred > 0
            ? currentBalance.totalTransferred
            : summary.totalTransferred,
        currency: currentBalance.currency,
      );

      state = state.copyWith(
        balance: mergedBalance,
        offers: results[1] as List<OfferModel>,
        recentTransactions:
            (results[2] as dynamic).data as List<TransactionModel>,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load balance data.',
      );
    }
  }

  /// Refresh the balance only.
  Future<void> refreshBalance() async {
    try {
      final balance = await _repository.getCurrentBalance();
      state = state.copyWith(balance: balance);
    } catch (_) {}
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TRANSACTIONS CONTROLLER
// ═══════════════════════════════════════════════════════════════════════

class TransactionsController extends StateNotifier<TransactionsState> {
  TransactionsController(this._repository) : super(const TransactionsState());

  final BalanceRepository _repository;

  /// Load the first page of transactions.
  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.getTransactions(
        page: 1,
        search: state.search.isNotEmpty ? state.search : null,
        status: state.statusFilter,
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
      );

      state = state.copyWith(
        transactions: response.data,
        isLoading: false,
        currentPage: response.currentPage,
        lastPage: response.lastPage,
        total: response.total,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load transactions.',
      );
    }
  }

  /// Load the next page (infinite scroll).
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final response = await _repository.getTransactions(
        page: state.currentPage + 1,
        search: state.search.isNotEmpty ? state.search : null,
        status: state.statusFilter,
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
      );

      state = state.copyWith(
        transactions: [...state.transactions, ...response.data],
        isLoadingMore: false,
        currentPage: response.currentPage,
        lastPage: response.lastPage,
        total: response.total,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Set status filter and reload.
  Future<void> setStatusFilter(String? status) async {
    state = TransactionsState(
      statusFilter: status,
      dateFrom: state.dateFrom,
      dateTo: state.dateTo,
      search: state.search,
    );
    await loadTransactions();
  }

  /// Set date range filter and reload.
  Future<void> setDateRange(String? from, String? to) async {
    state = TransactionsState(
      statusFilter: state.statusFilter,
      dateFrom: from,
      dateTo: to,
      search: state.search,
    );
    await loadTransactions();
  }

  /// Search transactions.
  Future<void> searchTransactions(String query) async {
    state = TransactionsState(
      statusFilter: state.statusFilter,
      dateFrom: state.dateFrom,
      dateTo: state.dateTo,
      search: query,
    );
    await loadTransactions();
  }
}

// ═══════════════════════════════════════════════════════════════════════
// BUY BALANCE CONTROLLER
// ═══════════════════════════════════════════════════════════════════════

class BuyBalanceController extends StateNotifier<BuyBalanceState> {
  BuyBalanceController(this._repository) : super(const BuyBalanceState());

  final BalanceRepository _repository;

  /// Load price tiers and banks.
  Future<void> loadInitialData() async {
    try {
      final results = await Future.wait([
        _repository.getPriceTiers(),
        _repository.getBanks(),
      ]);

      state = state.copyWith(
        priceTiers: results[0] as List<PriceTierModel>,
        banks: results[1] as List<BankModel>,
      );
    } catch (_) {}
  }

  /// Calculate the purchase price.
  Future<void> calculatePurchase(int amount) async {
    if (amount <= 0) return;

    state = state.copyWith(isCalculating: true, error: null);

    try {
      final result = await _repository.calculatePurchase(
        amount: amount,
        paymentMethod: state.selectedPaymentMethod,
      );
      state = state.copyWith(
        calculation: result,
        isCalculating: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isCalculating: false, error: e.message);
    } catch (_) {
      state = state.copyWith(isCalculating: false);
    }
  }

  /// Set payment method.
  void setPaymentMethod(String method) {
    state = state.copyWith(selectedPaymentMethod: method);
  }

  /// Purchase online (Noon).
  Future<Map<String, dynamic>?> purchaseOnline(int amount) async {
    state = state.copyWith(isPurchasing: true, error: null);

    try {
      final result = await _repository.purchaseOnline(amount: amount);
      state = state.copyWith(isPurchasing: false, purchaseResult: result);
      return result;
    } on ApiException catch (e) {
      state = state.copyWith(isPurchasing: false, error: e.message);
      return null;
    } catch (_) {
      state = state.copyWith(isPurchasing: false, error: 'Purchase failed.');
      return null;
    }
  }

  /// Purchase via bank transfer.
  Future<bool> purchaseBankTransfer({
    required int amount,
    required int bankId,
    required String depositorName,
    required String transferDate,
    String? receiptFilePath,
    String? receiptFileName,
  }) async {
    state = state.copyWith(isPurchasing: true, error: null);

    try {
      final result = await _repository.purchaseBankTransfer(
        amount: amount,
        bankId: bankId,
        depositorName: depositorName,
        transferDate: transferDate,
        receiptFilePath: receiptFilePath,
        receiptFileName: receiptFileName,
      );
      state = state.copyWith(isPurchasing: false, purchaseResult: result);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isPurchasing: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(isPurchasing: false, error: 'Purchase failed.');
      return false;
    }
  }

  /// Purchase via STC Pay (first step: sends OTP).
  Future<bool> purchaseStcPay({
    required int amount,
    required String phoneNumber,
  }) async {
    state = state.copyWith(isPurchasing: true, error: null);

    try {
      final result = await _repository.purchaseStcPay(
        amount: amount,
        phoneNumber: phoneNumber,
      );

      final txId = result['data']?['transaction_id']?.toString() ??
          result['transaction_id']?.toString();

      state = state.copyWith(
        isPurchasing: false,
        awaitingOtp: true,
        transactionId: txId,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isPurchasing: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(isPurchasing: false, error: 'STC Pay failed.');
      return false;
    }
  }

  /// Verify STC Pay OTP.
  Future<bool> verifyStcPayOtp(String otp) async {
    if (state.transactionId == null) return false;

    state = state.copyWith(isPurchasing: true, error: null);

    try {
      final result = await _repository.verifyStcPayOtp(
        otp: otp,
        transactionId: state.transactionId!,
      );
      state = state.copyWith(
        isPurchasing: false,
        awaitingOtp: false,
        purchaseResult: result,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isPurchasing: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(isPurchasing: false, error: 'OTP verification failed.');
      return false;
    }
  }

  /// Purchase via SADAD.
  Future<bool> purchaseSadad({
    required int amount,
    required String phoneNumber,
    required String nationalId,
  }) async {
    state = state.copyWith(isPurchasing: true, error: null);

    try {
      final result = await _repository.purchaseSadad(
        amount: amount,
        phoneNumber: phoneNumber,
        nationalId: nationalId,
      );
      state = state.copyWith(isPurchasing: false, purchaseResult: result);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isPurchasing: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(isPurchasing: false, error: 'SADAD failed.');
      return false;
    }
  }

  /// Reset purchase state.
  void reset() {
    state = BuyBalanceState(
      priceTiers: state.priceTiers,
      banks: state.banks,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TRANSFER BALANCE CONTROLLER
// ═══════════════════════════════════════════════════════════════════════

class TransferBalanceController extends StateNotifier<TransferBalanceState> {
  TransferBalanceController(this._repository)
      : super(const TransferBalanceState());

  final BalanceRepository _repository;

  /// Load transfer history.
  Future<void> loadHistory() async {
    state = state.copyWith(isLoadingHistory: true);

    try {
      final history = await _repository.getTransferHistory();
      state = state.copyWith(
        history: history,
        isLoadingHistory: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingHistory: false);
    }
  }

  /// Transfer balance to another user by phone number.
  Future<bool> transfer({
    required String phoneNumber,
    required int amount,
  }) async {
    state = state.copyWith(isTransferring: true, error: null);

    try {
      final result = await _repository.transferBalance(
        phoneNumber: phoneNumber,
        amount: amount,
      );
      state = state.copyWith(
        isTransferring: false,
        transferResult: result,
      );
      await loadHistory();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isTransferring: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isTransferring: false,
        error: 'Transfer failed.',
      );
      return false;
    }
  }

  /// Reset transfer state.
  void reset() {
    state = TransferBalanceState(history: state.history);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provider for the balance overview screen controller.
final balanceScreenControllerProvider =
    StateNotifierProvider<BalanceScreenController, BalanceScreenState>((ref) {
  final repository = ref.watch(balanceRepositoryProvider);
  return BalanceScreenController(repository);
});

/// Provider for the transactions list controller.
final transactionsControllerProvider =
    StateNotifierProvider<TransactionsController, TransactionsState>((ref) {
  final repository = ref.watch(balanceRepositoryProvider);
  return TransactionsController(repository);
});

/// Provider for the buy balance controller.
final buyBalanceControllerProvider =
    StateNotifierProvider<BuyBalanceController, BuyBalanceState>((ref) {
  final repository = ref.watch(balanceRepositoryProvider);
  return BuyBalanceController(repository);
});

/// Provider for the transfer balance controller.
final transferBalanceControllerProvider =
    StateNotifierProvider<TransferBalanceController, TransferBalanceState>(
        (ref) {
  final repository = ref.watch(balanceRepositoryProvider);
  return TransferBalanceController(repository);
});
