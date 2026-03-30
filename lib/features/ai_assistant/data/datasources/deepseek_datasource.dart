import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/storage/secure_storage.dart';

/// Remote datasource for the DeepSeek chat completions API.
///
/// Uses a **separate** [Dio] instance (not the app's shared [ApiClient])
/// because DeepSeek has its own base URL, auth scheme, and response format.
///
/// Supports SSE streaming for real-time token-by-token display.
class DeepSeekDatasource {
  DeepSeekDatasource(this._secureStorage);

  final SecureStorageService _secureStorage;

  /// Secure storage key for the DeepSeek API key.
  static const String _apiKeyStorageKey = 'orbit_deepseek_api_key';

  /// Default API key seeded on first launch.
  static const String _defaultApiKey = 'sk-1fbe3ce794d24ed08da1424adcb787c3';

  /// Ensures the API key exists in secure storage.
  ///
  /// If the key is not already stored, writes the default key.
  /// This is a no-op when the key is already present.
  Future<void> ensureApiKey() async {
    final existing = await _secureStorage.read(key: _apiKeyStorageKey);
    if (existing == null || existing.isEmpty) {
      await _secureStorage.write(
        key: _apiKeyStorageKey,
        value: _defaultApiKey,
      );
      // Reset the cached Dio so it picks up the newly stored key.
      _dio = null;
    }
  }

  /// DeepSeek API base URL.
  static const String _baseUrl = 'https://api.deepseek.com';

  /// The model to use for chat completions.
  static const String _model = 'deepseek-chat';

  /// Sampling temperature (low = more deterministic).
  static const double _temperature = 0.3;

  /// Maximum tokens to generate per response.
  static const int _maxTokens = 1024;

  // ─── Dio Instance (lazy) ────────────────────────────────────────────────

  Dio? _dio;

  /// Returns a configured [Dio] instance for DeepSeek API calls.
  ///
  /// Lazily initialised with the API key from secure storage.
  Future<Dio> _getDio() async {
    if (_dio != null) return _dio!;

    final apiKey = await _secureStorage.read(key: _apiKeyStorageKey);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('DeepSeek API key not found in secure storage');
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    return _dio!;
  }

  // ─── Streaming Chat ─────────────────────────────────────────────────────

  /// Sends a chat completion request and returns a [Stream] of text chunks.
  ///
  /// [systemPrompt] is injected as the first message with role `system`.
  /// [messages] is the conversation history as a list of `{role, content}` maps.
  ///
  /// The stream emits individual text tokens as they arrive via SSE.
  /// The stream closes when the `[DONE]` signal is received or the
  /// response ends.
  Future<Stream<String>> sendMessageStream(
    String systemPrompt,
    List<Map<String, String>> messages,
  ) async {
    try {
      final dio = await _getDio();

      final allMessages = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt},
        ...messages,
      ];

      final response = await dio.post(
        '/chat/completions',
        data: {
          'model': _model,
          'messages': allMessages,
          'temperature': _temperature,
          'max_tokens': _maxTokens,
          'stream': true,
        },
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      final responseStream =
          response.data!.stream as Stream<List<int>>;

      return _parseSseStream(responseStream);
    } on DioException catch (e) {
      throw Exception(
        'DeepSeek API error: ${e.response?.statusCode} - '
        '${e.response?.statusMessage ?? e.message}',
      );
    } catch (e) {
      throw Exception('DeepSeek request failed: $e');
    }
  }

  /// Parses an SSE byte stream into a stream of content text chunks.
  ///
  /// SSE format:
  /// ```
  /// data: {"choices":[{"delta":{"content":"Hello"}}]}
  ///
  /// data: [DONE]
  /// ```
  Stream<String> _parseSseStream(Stream<List<int>> byteStream) {
    final controller = StreamController<String>();
    String buffer = '';

    byteStream
        .transform(utf8.decoder)
        .listen(
      (chunk) {
        buffer += chunk;
        final lines = buffer.split('\n');
        // Keep the last incomplete line in the buffer.
        buffer = lines.removeLast();

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;

          if (!trimmed.startsWith('data: ')) continue;

          final data = trimmed.substring(6); // Remove 'data: ' prefix.

          // Handle end-of-stream signal.
          if (data == '[DONE]') {
            controller.close();
            return;
          }

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List<dynamic>?;
            if (choices != null && choices.isNotEmpty) {
              final delta =
                  choices[0]['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                controller.add(content);
              }
            }
          } catch (_) {
            // Skip malformed JSON lines silently.
          }
        }
      },
      onError: (Object error) {
        controller.addError(Exception('SSE stream error: $error'));
        controller.close();
      },
      onDone: () {
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );

    return controller.stream;
  }

  /// Resets the cached [Dio] instance.
  ///
  /// Call this when the API key changes so the next request picks up the
  /// new key from secure storage.
  void resetClient() {
    _dio = null;
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final deepSeekDatasourceProvider = Provider<DeepSeekDatasource>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return DeepSeekDatasource(secureStorage);
});
