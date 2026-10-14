import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/token_storage.dart';
import 'api_endpoints.dart';

class ApiClient {
  final TokenStorage _tokenStorage;
  late final Dio dio;

  ApiClient(this._tokenStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Attach token automatically to all requests
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (kDebugMode) {
            print('🌐 [API REQ] ${options.method} -> ${options.uri}');
            print('📦 [API DATA SENT] ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('✅ [API RES] ${response.statusCode} <- ${response.requestOptions.uri}');
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          if (kDebugMode) {
            print('❌ [API ERR] ${error.response?.statusCode} <- ${error.requestOptions.uri}');
            print('❌ [API ERR RESPONSE FROM SERVER] ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  // --- GET Method ---
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await dio.get(endpoint, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // --- POST Method ---
  Future<dynamic> post(String endpoint, {dynamic data}) async {
    try {
      final response = await dio.post(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // Helper to extract clean error message from backend
  String _parseError(DioException e) {
    if (e.response?.data != null && e.response?.data is Map) {
      final data = e.response!.data as Map;

      // Check for validation errors { errors: { field: ["error"] } }
      if (data['errors'] is Map && (data['errors'] as Map).isNotEmpty) {
        final errors = data['errors'] as Map;
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
      }

      // Check for message { message: "error text" }
      if (data['message'] != null) {
        return data['message'].toString();
      }
    }

    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please try again.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please check your network.';
    }

    return e.message ?? 'Something went wrong. Please try again.';
  }
}

/// Provider for ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage);
});
