import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/support/data/models/ticket_model.dart';
import 'package:orbit_app/features/support/data/repositories/support_repository.dart';

/// Immutable state for the tickets list screen.
class SupportListState {
  const SupportListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
  });

  final List<SupportTicketModel> items;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int lastPage;

  bool get isEmpty => !isLoading && items.isEmpty && error == null;
  bool get hasError => error != null;

  SupportListState copyWith({
    List<SupportTicketModel>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? currentPage,
    int? lastPage,
  }) {
    return SupportListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
    );
  }
}

/// Notifier driving the tickets list screen.
class SupportListController extends StateNotifier<SupportListState> {
  SupportListController(this._repo) : super(const SupportListState());

  final SupportRepository _repo;

  Future<void> load({int page = 1}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.listTickets(page: page);
      state = state.copyWith(
        items: result.data,
        isLoading: false,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    }
  }

  Future<void> refresh() => load();
}

/// Provider for the tickets list controller.
final supportListControllerProvider =
    StateNotifierProvider<SupportListController, SupportListState>((ref) {
  return SupportListController(ref.watch(supportRepositoryProvider));
});

// ─── Create Ticket ───────────────────────────────────────────────────

/// Outcome of a create-ticket attempt. UI inspects this to decide between
/// success snackbar + pop, or rendering field/general errors.
class CreateTicketResult {
  const CreateTicketResult({
    required this.success,
    this.ticket,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  final bool success;
  final SupportTicketModel? ticket;
  final String? errorMessage;
  final Map<String, List<String>> fieldErrors;
}

class CreateTicketController extends StateNotifier<bool> {
  CreateTicketController(this._repo) : super(false);

  final SupportRepository _repo;

  Future<CreateTicketResult> submit({required String title}) async {
    if (state) {
      return const CreateTicketResult(success: false);
    }
    state = true;
    try {
      final ticket = await _repo.createTicket(title: title);
      return CreateTicketResult(success: true, ticket: ticket);
    } on ValidationException catch (e) {
      return CreateTicketResult(
        success: false,
        errorMessage: e.message,
        fieldErrors: e.errors ?? const {},
      );
    } on ApiException catch (e) {
      return CreateTicketResult(success: false, errorMessage: e.message);
    } finally {
      state = false;
    }
  }
}

final createTicketControllerProvider =
    StateNotifierProvider<CreateTicketController, bool>((ref) {
  return CreateTicketController(ref.watch(supportRepositoryProvider));
});
