import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '🌐 [REQ] ${options.method} -> ${options.uri}\nHeaders: ${options.headers}\nData: ${options.data}',
        name: 'ApiClient',
      );
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '✅ [RES ${response.statusCode}] <- ${response.requestOptions.uri}\nData: ${response.data}',
        name: 'ApiClient',
      );
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '❌ [ERR ${err.response?.statusCode}] <- ${err.requestOptions.uri}\nMessage: ${err.message}\nData: ${err.response?.data}',
        name: 'ApiClient',
        error: err.error,
      );
    }
    return handler.next(err);
  }
}
