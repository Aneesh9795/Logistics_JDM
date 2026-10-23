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
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
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

  // --- PATCH Method (Used for Status & POD updates) ---
  Future<dynamic> patch(String endpoint, {dynamic data}) async {
    try {
      final response = await dio.patch(endpoint, data: data);
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
        final msg = data['message'].toString();
        if (msg == 'Unauthenticated.' || e.response?.statusCode == 401) {
          return 'Session expired. Please login again.';
        }
        if (msg == 'Server Error') {
          return 'Server Error (500): Backend controller threw an unhandled exception.';
        }
        return msg;
      }
    }

    if (e.response?.statusCode == 401) {
      return 'Session expired. Please login again.';
    }

    if (e.response?.statusCode == 500) {
      return 'Server Error (500): Backend failed to process the request. Please notify backend developer.';
    }

    if (e.response?.statusCode == 503 || e.response?.statusCode == 502) {
      return 'Server is temporarily unavailable (503). Backend might be restarting or in maintenance.';
    }

    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your network and try again.';
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
