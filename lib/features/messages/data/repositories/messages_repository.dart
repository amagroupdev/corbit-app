import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/messages/data/datasources/messages_remote_datasource.dart';
import 'package:orbit_app/features/messages/data/datasources/senders_remote_datasource.dart';
import 'package:orbit_app/features/messages/data/datasources/templates_remote_datasource.dart';
import 'package:orbit_app/features/messages/data/models/message_model.dart';
import 'package:orbit_app/features/messages/data/models/sender_model.dart';
import 'package:orbit_app/features/messages/data/models/template_model.dart';
import 'package:orbit_app/shared/models/api_response_model.dart';
import 'package:orbit_app/shared/models/pagination_model.dart';

/// Repository that coordinates all message-related data operations.
///
/// Acts as a single entry point for the presentation layer, wrapping
/// the three remote datasources and providing consistent error handling.
class MessagesRepository {
  const MessagesRepository({
    required MessagesRemoteDatasource messagesDatasource,
    required SendersRemoteDatasource sendersDatasource,
    required TemplatesRemoteDatasource templatesDatasource,
  })  : _messagesDatasource = messagesDatasource,
        _sendersDatasource = sendersDatasource,
        _templatesDatasource = templatesDatasource;

  final MessagesRemoteDatasource _messagesDatasource;
  final SendersRemoteDatasource _sendersDatasource;
  final TemplatesRemoteDatasource _templatesDatasource;

  // ═══════════════════════════════════════════════════════════════════════
  // MESSAGES
  // ═══════════════════════════════════════════════════════════════════════

  /// Sends a message through the unified V3 endpoint.
  ///
  /// Returns the raw response data on success; throws [ApiException] on error.
  Future<ApiResponse<Map<String, dynamic>>> sendMessage(
    SendMessageRequest request,
  ) async {
    try {
      return await _messagesDatasource.sendMessage(request);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Previews message cost and recipient count.
  Future<MessagePreview> previewMessage(SendMessageRequest request) async {
    try {
      return await _messagesDatasource.previewMessage(request);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Calculates how many SMS segments a message body requires.
  ///
  /// Uses the server-side calculation; falls back to local calculation
  /// if the API call fails.
  Future<SmsCountResult> calculateSmsCount(String message) async {
    try {
      return await _messagesDatasource.calculateSmsCount(message);
    } on ApiException {
      // Fall back to local calculation on API failure.
      return SmsCountResult.calculate(message);
    } catch (_) {
      return SmsCountResult.calculate(message);
    }
  }

  /// Validates whether the message body contains blocked links.
  Future<bool> validateBlockedLinks(String message) async {
    try {
      return await _messagesDatasource.validateBlockedLinks(message);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Checks for duplicate messages.
  Future<bool> checkDuplicate({
    required int senderId,
    required String number,
    required String message,
  }) async {
    try {
      return await _messagesDatasource.checkDuplicate(
        senderId: senderId,
        number: number,
        message: message,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Fetches paginated sent messages, optionally filtered by type.
  Future<PaginatedResponse<SentMessageModel>> listMessages({
    MessageType? type,
    String? search,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      return await _messagesDatasource.listMessages(
        type: type,
        search: search,
        page: page,
        perPage: perPage,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Fetches a single message's details.
  Future<SentMessageModel> getMessageDetail(int id) async {
    try {
      return await _messagesDatasource.getMessageDetail(id);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SENDERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns all sender names for the current account.
  Future<List<SenderModel>> listSenders() async {
    try {
      return await _sendersDatasource.listSenders();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Validates whether a sender ID is active and usable.
  Future<bool> validateSender(int senderId) async {
    try {
      return await _sendersDatasource.validateSender(senderId);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TEMPLATES
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns all message templates.
  Future<List<TemplateModel>> listTemplates() async {
    try {
      return await _templatesDatasource.listTemplates();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Fetches a single template by ID.
  Future<TemplateModel> getTemplate(int id) async {
    try {
      return await _templatesDatasource.getTemplate(id);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Creates a new template.
  Future<TemplateModel> createTemplate({
    required String name,
    required String body,
  }) async {
    try {
      return await _templatesDatasource.createTemplate(name: name, body: body);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Updates an existing template.
  Future<TemplateModel> updateTemplate({
    required int id,
    required String name,
    required String body,
  }) async {
    try {
      return await _templatesDatasource.updateTemplate(
        id: id,
        name: name,
        body: body,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Deletes a template by its ID.
  Future<void> deleteTemplate(int id) async {
    try {
      await _templatesDatasource.deleteTemplate(id);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return MessagesRepository(
    messagesDatasource: ref.watch(messagesRemoteDatasourceProvider),
    sendersDatasource: ref.watch(sendersRemoteDatasourceProvider),
    templatesDatasource: ref.watch(templatesRemoteDatasourceProvider),
  );
});
