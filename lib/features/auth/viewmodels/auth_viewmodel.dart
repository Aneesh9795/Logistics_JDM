import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/config.dart';
import '../data/repositories/auth_repository.dart';
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
  final AuthRepository _authRepository;

  AuthViewModel(this._authRepository) : super(const AuthState());

  /// Check saved auth status on splash screen
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    try {
      final isAuth = _authRepository.isAuthenticated();
      final partner = _authRepository.getCachedPartner();

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: isAuth,
        partner: partner,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        partner: null,
      );
    }
  }

  /// Perform live login with mobile number and password
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
      final response = await _authRepository.login(
        mobile: cleanMobile,
        password: cleanPassword,
      );

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        partner: response.deliveryBoy,
        errorMessage: null,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred: ${e.toString()}',
      );
      return false;
    }
  }

  /// Clear session and logout
  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } finally {
      state = const AuthState(
        isLoading: false,
        isAuthenticated: false,
        partner: null,
        errorMessage: null,
      );
    }
  }
}

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthViewModel(authRepository);
});
