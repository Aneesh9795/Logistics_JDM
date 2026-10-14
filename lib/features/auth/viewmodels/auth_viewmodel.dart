import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/api_client.dart';
import '../../../core/config/api_endpoints.dart';
import '../../../core/services/storage_service.dart';
import '../models/partner_model.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final PartnerModel? partner;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.partner,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    PartnerModel? partner,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      partner: partner ?? this.partner,
      errorMessage: errorMessage,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthViewModel({
    required ApiClient apiClient,
    required StorageService storageService,
  })  : _apiClient = apiClient,
        _storageService = storageService,
        super(const AuthState());

  /// Check if user is already logged in on app startup
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    final hasToken = _storageService.hasAuthToken();
    final cachedPartner = _storageService.getPartner();

    state = state.copyWith(
      isLoading: false,
      isAuthenticated: hasToken && cachedPartner != null,
      partner: cachedPartner,
    );
  }

  /// Live login with Mobile Number and Password
  Future<bool> login(String mobile, String password) async {
    final cleanMobile = mobile.trim();
    final cleanPassword = password.trim();

    if (cleanMobile.isEmpty || cleanPassword.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter registered Mobile Number and Password',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'mobile': cleanMobile,
          'password': cleanPassword,
        },
      );

      // Parse token & partner data from API response
      final token = response['token']?.toString() ?? '';
      final partnerData = response['delivery_boy'] as Map<String, dynamic>? ?? {};
      final partner = PartnerModel.fromJson(partnerData);

      // Save token and partner data in local storage
      if (token.isNotEmpty) {
        await _storageService.saveAuthToken(token);
      }
      await _storageService.savePartner(partner);
      await _storageService.setLoggedIn(true);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        partner: partner,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Logout and clear saved data
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {}

    await _storageService.clearAll();

    state = const AuthState(
      isLoading: false,
      isAuthenticated: false,
      partner: null,
      errorMessage: null,
    );
  }
}

/// Provider for AuthViewModel
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storageService = ref.watch(storageServiceProvider);

  return AuthViewModel(
    apiClient: apiClient,
    storageService: storageService,
  );
});
