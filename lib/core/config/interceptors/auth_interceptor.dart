import 'package:dio/dio.dart';
import '../../services/storage_service.dart';

class AuthInterceptor extends Interceptor {
  final StorageService _storageService;
  final void Function()? onUnauthorized;

  AuthInterceptor({
    required StorageService storageService,
    this.onUnauthorized,
  }) : _storageService = storageService;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Inject Bearer token if available
    final token = _storageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Ensure standard headers
    options.headers['Accept'] = 'application/json';
    if (!options.headers.containsKey('Content-Type') && options.data is! FormData) {
      options.headers['Content-Type'] = 'application/json';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401 Unauthorized handling
    if (err.response?.statusCode == 401) {
      _storageService.clearAll();
      onUnauthorized?.call();
    }
    return handler.next(err);
  }
}
