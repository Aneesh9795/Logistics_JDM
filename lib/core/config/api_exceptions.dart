import 'dart:io';
import 'package:dio/dio.dart';

/// Standard API Exception for comprehensive network error handling
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;

  /// Factory constructor to convert DioException into clean ApiException
  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timed out. Please check your internet connection.',
          statusCode: 408,
        );

      case DioExceptionType.connectionError:
        return ApiException(
          message: 'Unable to connect to the server. Please check your internet connection.',
          statusCode: 503,
        );

      case DioExceptionType.badResponse:
        return ApiException._handleBadResponse(error.response);

      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request was cancelled.',
        );

      case DioExceptionType.unknown:
      default:
        if (error.error is SocketException) {
          return ApiException(
            message: 'No internet connection. Please verify your network.',
            statusCode: 503,
          );
        }
        return ApiException(
          message: error.message ?? 'An unexpected error occurred. Please try again.',
        );
    }
  }

  /// Parses Laravel backend response format (e.g. message, errors)
  static ApiException _handleBadResponse(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;

    String errorMessage = 'Something went wrong. Please try again.';
    Map<String, dynamic>? fieldErrors;

    if (data is Map<String, dynamic>) {
      // 1. Extract backend message
      if (data['message'] != null && data['message'].toString().trim().isNotEmpty) {
        errorMessage = data['message'].toString();
      }

      // 2. Extract validation field errors
      if (data['errors'] is Map) {
        fieldErrors = Map<String, dynamic>.from(data['errors'] as Map);

        // If message is generic, extract first field error
        if (fieldErrors.isNotEmpty) {
          final firstKey = fieldErrors.keys.first;
          final firstVal = fieldErrors[firstKey];
          if (firstVal is List && firstVal.isNotEmpty) {
            errorMessage = firstVal.first.toString();
          } else if (firstVal is String) {
            errorMessage = firstVal;
          }
        }
      }
    } else if (data is String && data.isNotEmpty) {
      errorMessage = data;
    }

    switch (statusCode) {
      case 400:
        return ApiException(
          message: errorMessage,
          statusCode: 400,
          errors: fieldErrors,
        );
      case 401:
        return ApiException(
          message: errorMessage.isNotEmpty ? errorMessage : 'Session expired. Please log in again.',
          statusCode: 401,
          errors: fieldErrors,
        );
      case 403:
        return ApiException(
          message: 'Access denied. You do not have permission.',
          statusCode: 403,
        );
      case 404:
        return ApiException(
          message: 'Requested resource was not found.',
          statusCode: 404,
        );
      case 422:
        return ApiException(
          message: errorMessage,
          statusCode: 422,
          errors: fieldErrors,
        );
      case 500:
      case 502:
      case 503:
        return ApiException(
          message: 'Server error. Our technical team has been notified.',
          statusCode: statusCode,
        );
      default:
        return ApiException(
          message: errorMessage,
          statusCode: statusCode,
          errors: fieldErrors,
        );
    }
  }
}
