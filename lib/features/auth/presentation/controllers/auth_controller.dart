import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/features/auth/data/models/auth_response_model.dart';
import 'package:orbit_app/features/auth/data/models/user_model.dart';
import 'package:orbit_app/features/auth/data/repositories/auth_repository.dart';

// =============================================================================
// Auth state -- tracks whether the user is logged in
// =============================================================================

/// Async provider that checks for a persisted token to determine initial
/// authentication state. Screens observe this to decide whether to show the
/// login screen or the main app.
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AsyncValue<bool>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(repository);
});

class AuthStateNotifier extends StateNotifier<AsyncValue<bool>> {
  AuthStateNotifier(this._repository) : super(const AsyncValue.loading()) {
    _checkAuthStatus();
  }

  final AuthRepository _repository;

  Future<void> _checkAuthStatus() async {
    state = const AsyncValue.loading();
    final hasToken = await _repository.hasToken();
    state = AsyncValue.data(hasToken);
  }

  void setAuthenticated() {
    state = const AsyncValue.data(true);
  }

  void setUnauthenticated() {
    state = const AsyncValue.data(false);
  }

  Future<void> refresh() => _checkAuthStatus();
}

// =============================================================================
// Current user provider
// =============================================================================

/// Holds the currently authenticated user's data. Populated after login /
/// token verification.
final currentUserProvider = StateProvider<UserModel?>((ref) => null);

// =============================================================================
// Login controller
// =============================================================================

/// State for the login flow.
class LoginState {
  const LoginState({
    this.isLoading = false,
    this.error,
    this.response,
    this.fieldErrors,
  });

  final bool isLoading;
  final String? error;
  final AuthResponseModel? response;
  final Map<String, List<String>>? fieldErrors;

  LoginState copyWith({
    bool? isLoading,
    String? error,
    AuthResponseModel? response,
    Map<String, List<String>>? fieldErrors,
    bool clearError = false,
    bool clearResponse = false,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      response: clearResponse ? null : (response ?? this.response),
      fieldErrors: clearError ? null : (fieldErrors ?? this.fieldErrors),
    );
  }
}

final loginControllerProvider =
    StateNotifierProvider.autoDispose<LoginController, LoginState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginController(repository, ref);
});

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._repository, this._ref) : super(const LoginState());

  final AuthRepository _repository;
  final Ref _ref;

  /// Attempts to log in with [username] (phone or username) and [password].
  Future<void> login({
    required String username,
    required String password,
    String? fcmToken,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearResponse: true);

    final result = await _repository.login(
      username: username,
      password: password,
      fcmToken: fcmToken,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      final response = result.data!;
      state = state.copyWith(isLoading: false, response: response);

      if (response.isAuthenticated && response.user != null) {
        _ref.read(currentUserProvider.notifier).state = response.user;
        _ref.read(authStateProvider.notifier).setAuthenticated();
      }
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
        fieldErrors: result.fieldErrors,
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// =============================================================================
// Register controller
// =============================================================================

class RegisterState {
  const RegisterState({
    this.isLoading = false,
    this.error,
    this.response,
    this.fieldErrors,
  });

  final bool isLoading;
  final String? error;
  final AuthResponseModel? response;
  final Map<String, List<String>>? fieldErrors;

  RegisterState copyWith({
    bool? isLoading,
    String? error,
    AuthResponseModel? response,
    Map<String, List<String>>? fieldErrors,
    bool clearError = false,
    bool clearResponse = false,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      response: clearResponse ? null : (response ?? this.response),
      fieldErrors: clearError ? null : (fieldErrors ?? this.fieldErrors),
    );
  }
}

final registerControllerProvider =
    StateNotifierProvider.autoDispose<RegisterController, RegisterState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RegisterController(repository, ref);
});

class RegisterController extends StateNotifier<RegisterState> {
  RegisterController(this._repository, this._ref) : super(const RegisterState());

  final AuthRepository _repository;
  final Ref _ref;

  Future<void> register({
    required Map<String, dynamic> data,
    Map<String, MultipartFile>? files,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearResponse: true);

    final result = await _repository.register(data: data, files: files);

    if (!mounted) return;

    if (result.isSuccess) {
      final response = result.data!;
      state = state.copyWith(isLoading: false, response: response);

      if (response.isAuthenticated && response.user != null) {
        _ref.read(currentUserProvider.notifier).state = response.user;
        _ref.read(authStateProvider.notifier).setAuthenticated();
      }
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
        fieldErrors: result.fieldErrors,
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// =============================================================================
// OTP controller
// =============================================================================

class OtpState {
  const OtpState({
    this.isLoading = false,
    this.isResending = false,
    this.error,
    this.response,
    this.message,
    this.remainingSeconds = 120,
    this.canResend = false,
  });

  final bool isLoading;
  final bool isResending;
  final String? error;
  final AuthResponseModel? response;
  final String? message;
  final int remainingSeconds;
  final bool canResend;

  OtpState copyWith({
    bool? isLoading,
    bool? isResending,
    String? error,
    AuthResponseModel? response,
    String? message,
    int? remainingSeconds,
    bool? canResend,
    bool clearError = false,
    bool clearResponse = false,
  }) {
    return OtpState(
      isLoading: isLoading ?? this.isLoading,
      isResending: isResending ?? this.isResending,
      error: clearError ? null : (error ?? this.error),
      response: clearResponse ? null : (response ?? this.response),
      message: message ?? this.message,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      canResend: canResend ?? this.canResend,
    );
  }

  /// Formats remaining seconds as MM:SS.
  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

final otpControllerProvider =
    StateNotifierProvider.autoDispose<OtpController, OtpState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return OtpController(repository, ref);
});

class OtpController extends StateNotifier<OtpState> {
  OtpController(this._repository, this._ref) : super(const OtpState()) {
    _startCountdown();
  }

  final AuthRepository _repository;
  final Ref _ref;
  Timer? _timer;

  void _startCountdown() {
    _timer?.cancel();
    state = state.copyWith(remainingSeconds: 120, canResend: false);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final remaining = state.remainingSeconds - 1;
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(remainingSeconds: 0, canResend: true);
      } else {
        state = state.copyWith(remainingSeconds: remaining);
      }
    });
  }

  /// Verifies the phone OTP code.
  Future<void> verifyPhone({
    required String code,
    required int userId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.verifyPhone(code: code, userId: userId);

    if (!mounted) return;

    if (result.isSuccess) {
      final response = result.data!;
      state = state.copyWith(isLoading: false, response: response);

      if (response.isAuthenticated && response.user != null) {
        _ref.read(currentUserProvider.notifier).state = response.user;
        _ref.read(authStateProvider.notifier).setAuthenticated();
      }
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  /// Verifies the 2FA code.
  Future<void> verify2fa({
    required String code,
    required String verificationUuid,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.verify2fa(
      code: code,
      verificationUuid: verificationUuid,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      final response = result.data!;
      state = state.copyWith(isLoading: false, response: response);

      if (response.isAuthenticated && response.user != null) {
        _ref.read(currentUserProvider.notifier).state = response.user;
        _ref.read(authStateProvider.notifier).setAuthenticated();
      }
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  /// Resends the OTP code.
  Future<void> resendOtp({required int userId}) async {
    if (!state.canResend) return;

    state = state.copyWith(isResending: true, clearError: true);

    final result = await _repository.resendOtp(userId: userId);

    if (!mounted) return;

    if (result.isSuccess) {
      state = state.copyWith(isResending: false, message: result.data);
      _startCountdown();
    } else {
      state = state.copyWith(isResending: false, error: result.error);
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// =============================================================================
// Forgot password controller
// =============================================================================

class ForgotPasswordState {
  const ForgotPasswordState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  final bool isLoading;
  final String? error;
  final String? successMessage;

  ForgotPasswordState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

final forgotPasswordControllerProvider =
    StateNotifierProvider.autoDispose<ForgotPasswordController, ForgotPasswordState>(
        (ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ForgotPasswordController(repository);
});

class ForgotPasswordController extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordController(this._repository) : super(const ForgotPasswordState());

  final AuthRepository _repository;

  Future<void> sendResetLink({required String phone}) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final result = await _repository.forgotPassword(phone: phone);

    if (!mounted) return;

    if (result.isSuccess) {
      state = state.copyWith(isLoading: false, successMessage: result.data);
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// =============================================================================
// Reset password controller
// =============================================================================

class ResetPasswordState {
  const ResetPasswordState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  final bool isLoading;
  final String? error;
  final String? successMessage;

  ResetPasswordState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ResetPasswordState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

final resetPasswordControllerProvider =
    StateNotifierProvider.autoDispose<ResetPasswordController, ResetPasswordState>(
        (ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ResetPasswordController(repository);
});

class ResetPasswordController extends StateNotifier<ResetPasswordState> {
  ResetPasswordController(this._repository) : super(const ResetPasswordState());

  final AuthRepository _repository;

  Future<void> resetPassword({
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final result = await _repository.resetPassword(
      token: token,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      state = state.copyWith(isLoading: false, successMessage: result.data);
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// =============================================================================
// Logout helper
// =============================================================================

final logoutControllerProvider = Provider<LogoutController>((ref) {
  return LogoutController(ref);
});

class LogoutController {
  const LogoutController(this._ref);
  final Ref _ref;

  Future<void> logout() async {
    final repository = _ref.read(authRepositoryProvider);
    await repository.logout();
    _ref.read(currentUserProvider.notifier).state = null;
    _ref.read(authStateProvider.notifier).setUnauthenticated();
  }
}
