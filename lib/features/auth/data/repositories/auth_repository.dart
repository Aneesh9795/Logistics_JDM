import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/config.dart';
import '../../../../core/services/storage_service.dart';
import '../datasources/auth_remote_data_source.dart';
import '../../models/partner_model.dart';
import '../../models/login_response.dart';

abstract class AuthRepository {
  Future<LoginResponse> login({
    required String mobile,
    required String password,
  });

  Future<void> logout();

  PartnerModel? getCachedPartner();

  bool isAuthenticated();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final StorageService _storageService;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required StorageService storageService,
  })  : _remoteDataSource = remoteDataSource,
        _storageService = storageService;

  @override
  Future<LoginResponse> login({
    required String mobile,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.login(
        mobile: mobile,
        password: password,
      );

      // Save token and partner data securely
      if (response.token.isNotEmpty) {
        await _storageService.saveAuthToken(response.token);
      }
      await _storageService.savePartner(response.deliveryBoy);
      await _storageService.setLoggedIn(true);

      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Authentication failed: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    await _remoteDataSource.logout();
    await _storageService.clearAll();
  }

  @override
  PartnerModel? getCachedPartner() {
    return _storageService.getPartner();
  }

  @override
  bool isAuthenticated() {
    return _storageService.isLoggedIn() && _storageService.hasAuthToken();
  }
}

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final storageService = ref.watch(storageServiceProvider);

  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    storageService: storageService,
  );
});
