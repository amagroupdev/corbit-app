import 'dart:io';

import 'package:dio/dio.dart';

/// Base exception class for all API errors.
///
/// Every specific API exception extends this class so callers can catch
/// [ApiException] for generic handling or catch a specific subtype
/// (e.g. [ValidationException]) for targeted error handling.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  /// Human-readable error message suitable for display.
  final String message;

  /// HTTP status code returned by the server, if available.
  final int? statusCode;

  /// Field-level validation errors returned by the server.
  ///
  /// Keys are field names; values are lists of error messages for that field.
  /// Typically populated only for 422 Unprocessable Entity responses.
  final Map<String, List<String>>? errors;

  // ─── Factory: DioException -> ApiException ─────────────────────────

  /// Converts a [DioException] into the most appropriate [ApiException]
  /// subtype based on the error type and HTTP status code.
  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();

      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badCertificate:
        return const ApiException(
          message: 'Invalid SSL certificate. Please check your connection.',
        );

      case DioExceptionType.cancel:
        return const ApiException(
          message: 'Request was cancelled.',
        );

      case DioExceptionType.badResponse:
        return ApiException.fromResponse(
          statusCode: error.response?.statusCode,
          data: error.response?.data,
        );

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return const NetworkException();
        }
        return ApiException(
          message: error.message ?? 'An unexpected error occurred.',
        );
    }
  }

  // ─── Factory: Response body -> ApiException ───────────────────────

  /// Parses an error response body and returns the appropriate
  /// [ApiException] subtype.
  ///
  /// [statusCode] is the HTTP status code.
  /// [data] is the decoded response body (usually a [Map]).
  factory ApiException.fromResponse({
    int? statusCode,
    dynamic data,
  }) {
    // Attempt to extract message and errors from the response body.
    String message = _extractMessage(data) ?? _defaultMessageForStatus(statusCode);
    final Map<String, List<String>>? fieldErrors = _extractFieldErrors(data);

    switch (statusCode) {
      case 401:
        return UnauthorizedException(message: message);

      case 403:
        return ForbiddenException(message: message);

      case 404:
        return NotFoundException(message: message);

      case 422:
        return ValidationException(
          message: message,
          errors: fieldErrors ?? {},
        );

      case 429:
        return TooManyRequestsException(message: message);

      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(message: message, statusCode: statusCode);

      default:
        return ApiException(
          message: message,
          statusCode: statusCode,
          errors: fieldErrors,
        );
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────

  /// Tries to extract a human-readable message from the response data.
  static String? _extractMessage(dynamic data) {
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      // Common Laravel API response structures.
      return data['message'] as String? ?? data['error'] as String?;
    }

    if (data is String && data.isNotEmpty) {
      return data;
    }

    return null;
  }

  /// Tries to extract field-level validation errors from the response data.
  ///
  /// Expects a Laravel-style errors map:
  /// ```json
  /// { "errors": { "email": ["The email field is required."] } }
  /// ```
  static Map<String, List<String>>? _extractFieldErrors(dynamic data) {
    if (data is! Map<String, dynamic>) return null;

    final rawErrors = data['errors'];
    if (rawErrors is! Map<String, dynamic>) return null;

    final Map<String, List<String>> parsed = {};
    for (final entry in rawErrors.entries) {
      if (entry.value is List) {
        parsed[entry.key] = (entry.value as List)
            .map((e) => e.toString())
            .toList();
      } else if (entry.value is String) {
        parsed[entry.key] = [entry.value as String];
      }
    }

    return parsed.isEmpty ? null : parsed;
  }

  /// Returns a sensible default message for common HTTP status codes.
  static String _defaultMessageForStatus(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 422:
        return 'Validation failed. Please check the form fields.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Internal server error. Please try again later.';
      case 502:
        return 'Bad gateway. The server is temporarily unavailable.';
      case 503:
        return 'Service unavailable. Please try again later.';
      case 504:
        return 'Gateway timeout. The server took too long to respond.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message, errors: $errors)';
}

// ─── Specific Exception Types ─────────────────────────────────────────

/// Thrown when the server responds with 401 Unauthorized.
///
/// Typically means the access token is invalid or expired.
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    String message = 'Your session has expired. Please log in again.',
  }) : super(message: message, statusCode: 401);
}

/// Thrown when the server responds with 403 Forbidden.
class ForbiddenException extends ApiException {
  const ForbiddenException({
    String message = 'You do not have permission to perform this action.',
  }) : super(message: message, statusCode: 403);
}

/// Thrown when the server responds with 404 Not Found.
class NotFoundException extends ApiException {
  const NotFoundException({
    String message = 'The requested resource was not found.',
  }) : super(message: message, statusCode: 404);
}

/// Thrown when the server responds with 422 Unprocessable Entity.
///
/// Contains a map of field-level validation errors.
class ValidationException extends ApiException {
  const ValidationException({
    String message = 'Validation failed. Please check the form fields.',
    Map<String, List<String>> errors = const {},
  }) : super(message: message, statusCode: 422, errors: errors);

  /// Returns the first error message for a specific field, or `null`
  /// if no error exists for that field.
  String? firstErrorFor(String field) {
    final fieldErrors = errors?[field];
    if (fieldErrors == null || fieldErrors.isEmpty) return null;
    return fieldErrors.first;
  }

  /// Returns all error messages flattened into a single list.
  List<String> get allErrors {
    if (errors == null) return [];
    return errors!.values.expand((list) => list).toList();
  }
}

/// Thrown when the server responds with 429 Too Many Requests.
class TooManyRequestsException extends ApiException {
  const TooManyRequestsException({
    String message = 'Too many requests. Please try again later.',
  }) : super(message: message, statusCode: 429);
}

/// Thrown when the server responds with a 5xx status code.
class ServerException extends ApiException {
  const ServerException({
    String message = 'Internal server error. Please try again later.',
    int? statusCode = 500,
  }) : super(message: message, statusCode: statusCode);
}

/// Thrown when there is no internet connection.
class NetworkException extends ApiException {
  const NetworkException({
    String message = 'No internet connection. Please check your network settings.',
  }) : super(message: message, statusCode: null);
}

/// Thrown when a request times out (connect, send, or receive).
class TimeoutException extends ApiException {
  const TimeoutException({
    String message = 'Connection timed out. Please try again.',
  }) : super(message: message, statusCode: null);
}
