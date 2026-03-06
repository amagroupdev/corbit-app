import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/features/groups/data/datasources/groups_remote_datasource.dart';
import 'package:orbit_app/features/groups/data/models/group_model.dart';
import 'package:orbit_app/features/groups/data/models/number_model.dart';
import 'package:orbit_app/features/messages/data/models/message_model.dart';
import 'package:orbit_app/features/messages/data/models/sender_model.dart';
import 'package:orbit_app/features/messages/data/models/template_model.dart';
import 'package:orbit_app/features/messages/data/repositories/messages_repository.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MESSAGE FORM STATE
// ═══════════════════════════════════════════════════════════════════════════

/// Holds all form state for composing a message.
class MessageFormState {
  const MessageFormState({
    this.messageType = MessageType.fromNumbers,
    this.senderId,
    this.messageBody = '',
    this.sendAtOption = SendAtOption.now,
    this.sendAt,
    this.numbers = const [],
    this.groupIds = const [],
    this.templateId,
  });

  final MessageType messageType;
  final int? senderId;
  final String messageBody;
  final SendAtOption sendAtOption;
  final DateTime? sendAt;
  final List<String> numbers;
  final List<int> groupIds;
  final int? templateId;

  MessageFormState copyWith({
    MessageType? messageType,
    int? senderId,
    String? messageBody,
    SendAtOption? sendAtOption,
    DateTime? sendAt,
    List<String>? numbers,
    List<int>? groupIds,
    int? templateId,
    bool clearSendAt = false,
    bool clearTemplateId = false,
  }) {
    return MessageFormState(
      messageType: messageType ?? this.messageType,
      senderId: senderId ?? this.senderId,
      messageBody: messageBody ?? this.messageBody,
      sendAtOption: sendAtOption ?? this.sendAtOption,
      sendAt: clearSendAt ? null : (sendAt ?? this.sendAt),
      numbers: numbers ?? this.numbers,
      groupIds: groupIds ?? this.groupIds,
      templateId: clearTemplateId ? null : (templateId ?? this.templateId),
    );
  }

  /// Converts the form state into a [SendMessageRequest].
  SendMessageRequest toRequest() {
    return SendMessageRequest(
      messageType: messageType,
      senderId: senderId ?? 0,
      messageBody: messageBody,
      sendAtOption: sendAtOption,
      sendAt: sendAt,
      numbers: numbers,
      groupIds: groupIds,
      templateId: templateId,
    );
  }

  /// Basic validation of the form before sending.
  String? validate() {
    if (senderId == null || senderId == 0) {
      return 'الرجاء اختيار اسم المرسل';
    }
    if (messageBody.trim().isEmpty) {
      return 'الرجاء كتابة نص الرسالة';
    }
    // Must have either numbers or groups selected.
    if (numbers.isEmpty && groupIds.isEmpty) {
      return 'الرجاء إضافة أرقام أو اختيار مجموعة';
    }
    if (sendAtOption == SendAtOption.later && sendAt == null) {
      return 'الرجاء تحديد تاريخ ووقت الإرسال';
    }
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MESSAGE FORM PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Manages the send-message form state.
class MessageFormNotifier extends StateNotifier<MessageFormState> {
  MessageFormNotifier() : super(const MessageFormState());

  void setMessageType(MessageType type) {
    state = state.copyWith(messageType: type);
  }

  void setSenderId(int id) {
    state = state.copyWith(senderId: id);
  }

  void setMessageBody(String body) {
    state = state.copyWith(messageBody: body);
  }

  void setSendAtOption(SendAtOption option) {
    if (option == SendAtOption.now) {
      state = state.copyWith(sendAtOption: option, clearSendAt: true);
    } else {
      state = state.copyWith(sendAtOption: option);
    }
  }

  void setSendAt(DateTime dateTime) {
    state = state.copyWith(sendAt: dateTime);
  }

  void addNumber(String number) {
    final trimmed = number.trim();
    if (trimmed.isEmpty || state.numbers.contains(trimmed)) return;
    state = state.copyWith(numbers: [...state.numbers, trimmed]);
  }

  void addNumbers(List<String> newNumbers) {
    final cleaned = newNumbers
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty && !state.numbers.contains(n))
        .toList();
    if (cleaned.isEmpty) return;
    state = state.copyWith(numbers: [...state.numbers, ...cleaned]);
  }

  void removeNumber(String number) {
    state = state.copyWith(
      numbers: state.numbers.where((n) => n != number).toList(),
    );
  }

  void clearNumbers() {
    state = state.copyWith(numbers: []);
  }

  void setGroupIds(List<int> ids) {
    state = state.copyWith(groupIds: ids);
  }

  void toggleGroupId(int id) {
    if (state.groupIds.contains(id)) {
      state = state.copyWith(
        groupIds: state.groupIds.where((g) => g != id).toList(),
      );
    } else {
      state = state.copyWith(groupIds: [...state.groupIds, id]);
    }
  }

  void setTemplateId(int? id) {
    if (id == null) {
      state = state.copyWith(clearTemplateId: true);
    } else {
      state = state.copyWith(templateId: id);
    }
  }

  void insertTemplate(TemplateModel template) {
    state = state.copyWith(
      messageBody: template.body,
      templateId: template.id,
    );
  }

  void insertVariable(String variable) {
    state = state.copyWith(
      messageBody: '${state.messageBody}{$variable}',
    );
  }

  void reset() {
    state = const MessageFormState();
  }

  void resetKeepType() {
    state = MessageFormState(messageType: state.messageType);
  }
}

final messageFormProvider =
    StateNotifierProvider<MessageFormNotifier, MessageFormState>((ref) {
  return MessageFormNotifier();
});

// ═══════════════════════════════════════════════════════════════════════════
// SEND MESSAGE PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Async provider that handles the actual message sending operation.
final sendMessageProvider = FutureProvider.autoDispose
    .family<bool, SendMessageRequest>((ref, request) async {
  final repo = ref.watch(messagesRepositoryProvider);
  final response = await repo.sendMessage(request);
  return response.success;
});

// ═══════════════════════════════════════════════════════════════════════════
// PREVIEW PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Fetches a message preview (cost estimate) for the current form state.
final previewProvider = FutureProvider.autoDispose
    .family<MessagePreview, SendMessageRequest>((ref, request) async {
  final repo = ref.watch(messagesRepositoryProvider);
  return repo.previewMessage(request);
});

// ═══════════════════════════════════════════════════════════════════════════
// SENDERS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Loads the list of available sender names.
final sendersProvider = FutureProvider<List<SenderModel>>((ref) async {
  final repo = ref.watch(messagesRepositoryProvider);
  final senders = await repo.listSenders();
  // Only return active senders for the send form.
  return senders.where((s) => s.isActive).toList();
});

// ═══════════════════════════════════════════════════════════════════════════
// TEMPLATES PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Loads the list of message templates.
final templatesProvider = FutureProvider<List<TemplateModel>>((ref) async {
  final repo = ref.watch(messagesRepositoryProvider);
  return repo.listTemplates();
});

// ═══════════════════════════════════════════════════════════════════════════
// SMS COUNT PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Calculates SMS count as the user types. Uses local calculation for
/// instant feedback without network calls.
final smsCountProvider = Provider.autoDispose<SmsCountResult>((ref) {
  final formState = ref.watch(messageFormProvider);
  return SmsCountResult.calculate(formState.messageBody);
});

// ═══════════════════════════════════════════════════════════════════════════
// MESSAGE LIST PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Currently selected message type tab for the message center.
final selectedMessageTypeProvider = StateProvider<MessageType?>((ref) => null);

/// Search query for the message center.
final messageSearchQueryProvider = StateProvider<String>((ref) => '');

/// Current page for pagination.
final messagePageProvider = StateProvider<int>((ref) => 1);

/// Fetches paginated messages based on the selected filters.
final messagesListProvider =
    FutureProvider.autoDispose<PaginatedResponse<SentMessageModel>>((ref) async {
  final repo = ref.watch(messagesRepositoryProvider);
  final type = ref.watch(selectedMessageTypeProvider);
  final search = ref.watch(messageSearchQueryProvider);
  final page = ref.watch(messagePageProvider);

  return repo.listMessages(
    type: type,
    search: search.isNotEmpty ? search : null,
    page: page,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// SEND MESSAGE CONTROLLER (for imperative operations)
// ═══════════════════════════════════════════════════════════════════════════

/// Controller notifier for handling the send message flow.
///
/// Holds the async state of the send operation and exposes methods
/// for sending, previewing, and validating messages.
class SendMessageController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state is idle (data = null).
  }

  /// Sends the message using the current form state.
  Future<bool> send() async {
    final formState = ref.read(messageFormProvider);
    final validationError = formState.validate();
    if (validationError != null) {
      state = AsyncError(validationError, StackTrace.current);
      return false;
    }

    state = const AsyncLoading();

    try {
      final repo = ref.read(messagesRepositoryProvider);
      final response = await repo.sendMessage(formState.toRequest());

      if (response.success) {
        state = const AsyncData(null);
        // Refresh the messages list.
        ref.invalidate(messagesListProvider);
        return true;
      } else {
        state = AsyncError(response.message, StackTrace.current);
        return false;
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Previews the message cost.
  Future<MessagePreview?> preview() async {
    final formState = ref.read(messageFormProvider);
    try {
      final repo = ref.read(messagesRepositoryProvider);
      return await repo.previewMessage(formState.toRequest());
    } catch (_) {
      return null;
    }
  }

  /// Validates the message body for blocked links.
  Future<bool> validateLinks() async {
    final formState = ref.read(messageFormProvider);
    if (formState.messageBody.trim().isEmpty) return true;
    try {
      final repo = ref.read(messagesRepositoryProvider);
      return await repo.validateBlockedLinks(formState.messageBody);
    } catch (_) {
      return true; // Allow sending if validation fails.
    }
  }
}

final sendMessageControllerProvider =
    AsyncNotifierProvider<SendMessageController, void>(
  SendMessageController.new,
);

// ═══════════════════════════════════════════════════════════════════════════
// GROUPS PROVIDERS (for send message screen)
// ═══════════════════════════════════════════════════════════════════════════

/// Loads all groups for the group picker in send message.
final groupsForSendProvider = FutureProvider<List<GroupModel>>((ref) async {
  final datasource = ref.watch(groupsRemoteDatasourceProvider);
  final result = await datasource.listGroups(page: 1, perPage: 100);
  return result.data;
});

/// Loads numbers for a specific group (on-demand when expanding).
final groupNumbersProvider =
    FutureProvider.family<List<NumberModel>, int>((ref, groupId) async {
  final datasource = ref.watch(groupsRemoteDatasourceProvider);
  final result = await datasource.listNumbers(groupId: groupId, perPage: 100);
  return result.data;
});
