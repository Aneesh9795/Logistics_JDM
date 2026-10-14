import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/config.dart';
import '../../models/login_response.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login({
    required String mobile,
    required String password,
  });

  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<LoginResponse> login({
    required String mobile,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {
        'mobile': mobile.trim(),
        'password': password,
      },
    );

    return LoginResponse.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Best-effort logout on server
    }
  }
}

/// Provider for AuthRemoteDataSource
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient);
});
