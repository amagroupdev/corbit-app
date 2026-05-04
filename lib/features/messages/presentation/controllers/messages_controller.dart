import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/storage/secure_storage.dart';
import 'package:orbit_app/features/groups/data/datasources/groups_remote_datasource.dart';
import 'package:orbit_app/features/groups/data/models/group_model.dart';
import 'package:orbit_app/features/groups/data/models/number_model.dart';
import 'package:orbit_app/features/messages/data/models/dynamic_text_model.dart';
import 'package:orbit_app/features/messages/data/models/message_model.dart';
import 'package:orbit_app/features/messages/data/models/receipt_report_model.dart';
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
    this.variant = SendVariant.fromNumbers,
    this.groupId,
    this.shortLink,
    this.voiceId,
    this.fileId,
    this.attendanceType,
    this.attendanceRecordIds = const [],
    this.certificationRecordIds = const [],
    this.vipCardTemplateId,
    this.vipCardType,
  });

  final MessageType messageType;
  final int? senderId;
  final String messageBody;
  final SendAtOption sendAtOption;
  final DateTime? sendAt;
  final List<String> numbers;
  final List<int> groupIds;
  final int? templateId;

  // Wave 5 variant-specific state.
  final SendVariant variant;
  final int? groupId;
  final String? shortLink;
  final int? voiceId;
  final int? fileId;
  final String? attendanceType;
  final List<int> attendanceRecordIds;
  final List<int> certificationRecordIds;
  final int? vipCardTemplateId;
  final String? vipCardType;

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
    SendVariant? variant,
    int? groupId,
    String? shortLink,
    int? voiceId,
    int? fileId,
    String? attendanceType,
    List<int>? attendanceRecordIds,
    List<int>? certificationRecordIds,
    int? vipCardTemplateId,
    String? vipCardType,
    bool clearGroupId = false,
    bool clearShortLink = false,
    bool clearVoiceId = false,
    bool clearFileId = false,
    bool clearAttendanceType = false,
    bool clearVipCardTemplateId = false,
    bool clearVipCardType = false,
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
      variant: variant ?? this.variant,
      groupId: clearGroupId ? null : (groupId ?? this.groupId),
      shortLink: clearShortLink ? null : (shortLink ?? this.shortLink),
      voiceId: clearVoiceId ? null : (voiceId ?? this.voiceId),
      fileId: clearFileId ? null : (fileId ?? this.fileId),
      attendanceType:
          clearAttendanceType ? null : (attendanceType ?? this.attendanceType),
      attendanceRecordIds: attendanceRecordIds ?? this.attendanceRecordIds,
      certificationRecordIds:
          certificationRecordIds ?? this.certificationRecordIds,
      vipCardTemplateId: clearVipCardTemplateId
          ? null
          : (vipCardTemplateId ?? this.vipCardTemplateId),
      vipCardType:
          clearVipCardType ? null : (vipCardType ?? this.vipCardType),
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
      variant: variant,
      groupId: groupId,
      shortLink: shortLink,
      voiceId: voiceId,
      fileId: fileId,
      attendanceType: attendanceType,
      attendanceRecordIds: attendanceRecordIds,
      certificationRecordIds: certificationRecordIds,
      vipCardTemplateId: vipCardTemplateId,
      vipCardType: vipCardType,
    );
  }

  /// Basic validation of the form before sending.
  /// Returns a localization key for the error message, or null if valid.
  String? validate() {
    if (senderId == null || senderId == 0) {
      return 'msg_validate_select_sender';
    }
    if (messageBody.trim().isEmpty &&
        variant != SendVariant.attendanceRecords &&
        variant != SendVariant.certificationWithTool &&
        variant != SendVariant.vipCard &&
        variant != SendVariant.fromExcel &&
        variant != SendVariant.withVoice) {
      return 'msg_validate_write_body';
    }
    // Recipient validation depends on the variant.
    switch (variant) {
      case SendVariant.fromNumbers:
      case SendVariant.withShortLink:
      case SendVariant.withFile:
      case SendVariant.withVoice:
      case SendVariant.fromGroups:
      case SendVariant.vipCard:
        if (numbers.isEmpty && groupIds.isEmpty) {
          return 'msg_validate_add_recipients';
        }
        break;
      case SendVariant.fromSpecificGroup:
        if (groupId == null) return 'msg_validate_add_recipients';
        break;
      case SendVariant.attendanceRecords:
        if (attendanceRecordIds.isEmpty) {
          return 'msg_validate_add_recipients';
        }
        break;
      case SendVariant.certificationWithTool:
        if (certificationRecordIds.isEmpty) {
          return 'msg_validate_add_recipients';
        }
        break;
      case SendVariant.fromExcel:
        // The screen is responsible for verifying a file was attached.
        break;
    }
    if (sendAtOption == SendAtOption.later && sendAt == null) {
      return 'msg_validate_select_datetime';
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

  /// Inserts the [token] (already wrapped with `{...}`) at [cursorPos].
  /// Used by [DynamicTextsPicker] to honour the actual cursor position
  /// of the message body field.
  void insertTokenAt({required String token, required int cursorPos}) {
    final body = state.messageBody;
    final clamped =
        cursorPos < 0 ? 0 : (cursorPos > body.length ? body.length : cursorPos);
    final newBody =
        body.substring(0, clamped) + token + body.substring(clamped);
    state = state.copyWith(messageBody: newBody);
  }

  // ─── Wave 5 — variant setters ─────────────────────────────────────

  void setVariant(SendVariant variant) {
    state = state.copyWith(variant: variant);
  }

  void setGroupId(int? id) {
    if (id == null) {
      state = state.copyWith(clearGroupId: true);
    } else {
      state = state.copyWith(groupId: id);
    }
  }

  void setShortLink(String? link) {
    if (link == null || link.isEmpty) {
      state = state.copyWith(clearShortLink: true);
    } else {
      state = state.copyWith(shortLink: link);
    }
  }

  void setVoiceId(int? id) {
    if (id == null) {
      state = state.copyWith(clearVoiceId: true);
    } else {
      state = state.copyWith(voiceId: id);
    }
  }

  void setFileId(int? id) {
    if (id == null) {
      state = state.copyWith(clearFileId: true);
    } else {
      state = state.copyWith(fileId: id);
    }
  }

  void setAttendance({
    String? type,
    List<int>? recordIds,
  }) {
    state = state.copyWith(
      attendanceType: type,
      attendanceRecordIds: recordIds,
    );
  }

  void setCertificationRecordIds(List<int> ids) {
    state = state.copyWith(certificationRecordIds: ids);
  }

  void setVipCard({int? templateId, String? type}) {
    state = state.copyWith(
      vipCardTemplateId: templateId,
      vipCardType: type,
    );
  }

  void reset() {
    state = const MessageFormState();
  }

  void resetKeepType() {
    state = MessageFormState(
      messageType: state.messageType,
      variant: state.variant,
    );
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
  final storage = ref.read(secureStorageProvider);
  if (await storage.isGuestMode()) {
    // Empty fallback - real senders come from API only
    return const [];
  }
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
  final storage = ref.read(secureStorageProvider);
  if (await storage.isGuestMode()) {
    return [
      TemplateModel(id: 1, name: 'رسالة ترحيب', body: 'مرحباً {name}، شكراً لتواصلك معنا!', createdAt: DateTime.now()),
      TemplateModel(id: 2, name: 'تذكير موعد', body: 'نذكرك بموعدك يوم {date} الساعة {time}', createdAt: DateTime.now()),
    ];
  }
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
  final storage = ref.read(secureStorageProvider);
  if (await storage.isGuestMode()) {
    // Empty fallback - real messages come from API only
    return PaginatedResponse<SentMessageModel>(
      data: const [],
      currentPage: 1,
      perPage: 15,
      total: 0,
      lastPage: 1,
    );
  }

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

  /// Server response data from the last successful send.
  Map<String, dynamic>? lastSendData;

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
        lastSendData = response.data;
        state = const AsyncData(null);
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
  ///
  /// Always returns a non-null preview: if the server response is missing
  /// or any field is zero, fall back to a local calculation so the UI
  /// never silently shows zeros.
  Future<MessagePreview?> preview() async {
    final formState = ref.read(messageFormProvider);
    final localFallback = _localPreview(formState);

    try {
      final repo = ref.read(messagesRepositoryProvider);
      final remote = await repo.previewMessage(formState.toRequest());

      // If the backend returned partial/zeroed data (different key names,
      // missing recipients on group expansion, etc.), reconcile with the
      // local estimate so the user always sees a sensible number.
      return MessagePreview(
        messageCount: remote.messageCount > 0
            ? remote.messageCount
            : localFallback.messageCount,
        recipientCount: remote.recipientCount > 0
            ? remote.recipientCount
            : localFallback.recipientCount,
        costEstimate:
            remote.costEstimate > 0 ? remote.costEstimate : localFallback.costEstimate,
      );
    } catch (_) {
      // Network/API failure: still show a local estimate.
      return localFallback;
    }
  }

  /// Computes a local preview estimate without contacting the server.
  ///
  /// - SMS segments are computed via [SmsCountResult.calculate] (GSM-7 vs Unicode).
  /// - Recipient count = direct numbers + (best-effort) sum of selected groups.
  /// - Cost = segments × recipients (one credit per segment per recipient).
  MessagePreview _localPreview(MessageFormState formState) {
    final smsResult = SmsCountResult.calculate(formState.messageBody);
    final segments = smsResult.smsCount;

    // Count direct numbers.
    int recipients = formState.numbers.length;

    // Add member counts of selected groups when their data is loaded.
    if (formState.groupIds.isNotEmpty) {
      final groupsAsync = ref.read(groupsForSendProvider);
      final loadedGroups = groupsAsync.valueOrNull;
      if (loadedGroups != null) {
        for (final id in formState.groupIds) {
          final group = loadedGroups.where((g) => g.id == id).firstOrNull;
          if (group != null) recipients += group.numbersCount;
        }
      }
    }

    // 1 credit per segment per recipient (matches the V3 pricing model).
    final cost = (segments * recipients).toDouble();

    return MessagePreview(
      messageCount: segments,
      recipientCount: recipients,
      costEstimate: cost,
    );
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
  final storage = ref.read(secureStorageProvider);
  if (await storage.isGuestMode()) {
    return const [
      GroupModel(id: 1, name: 'عملاء VIP', numbersCount: 50),
      GroupModel(id: 2, name: 'موظفين', numbersCount: 25),
      GroupModel(id: 3, name: 'تسويق', numbersCount: 100),
    ];
  }
  final datasource = ref.watch(groupsRemoteDatasourceProvider);
  final result = await datasource.listGroups(page: 1, perPage: 100);
  return result.data;
});

/// Loads numbers for a specific group (on-demand when expanding).
final groupNumbersProvider =
    FutureProvider.family<List<NumberModel>, int>((ref, groupId) async {
  final storage = ref.read(secureStorageProvider);
  if (await storage.isGuestMode()) {
    return const [];
  }
  final datasource = ref.watch(groupsRemoteDatasourceProvider);
  final result = await datasource.listNumbers(groupId: groupId, perPage: 100);
  return result.data;
});

// ═══════════════════════════════════════════════════════════════════════════
// WAVE 5 — DYNAMIC TEXTS / RECEIPT REPORT PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Caches the list of dynamic-text variables exposed by the gateway.
final dynamicTextsProvider =
    FutureProvider<List<DynamicTextModel>>((ref) async {
  final repo = ref.watch(messagesRepositoryProvider);
  return repo.listDynamicTexts();
});

/// Loads the receipt report for a specific message UUID.
final receiptReportProvider = FutureProvider.autoDispose
    .family<ReceiptReportModel, String>((ref, uuid) async {
  final repo = ref.watch(messagesRepositoryProvider);
  return repo.getReceiptReport(uuid);
});
