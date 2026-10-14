import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/api_client.dart';
import '../core/config/api_endpoints.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  /// Call login API and return token + user model
  Future<({String token, UserModel user})> login({
    required String mobile,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {
        'mobile': mobile.trim(),
        'password': password.trim(),
      },
    );

    final token = response['token']?.toString() ?? '';
    final userData = response['delivery_boy'] as Map<String, dynamic>? ?? {};
    final user = UserModel.fromJson(userData);

    return (token: token, user: user);
  }

  /// Call logout API
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Best-effort logout
    }
  }
}

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});
