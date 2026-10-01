import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/partner_model.dart';
import '../../../core/constants/app_constants.dart';

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
  AuthViewModel() : super(const AuthState());

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    // Simulate brief splash delay
    await Future.delayed(const Duration(milliseconds: 1500));
    // Default: false so partner sees clean login flow, or already logged in if saved
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: false,
    );
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    await Future.delayed(const Duration(milliseconds: 800));

    if (username.trim().isEmpty || password.trim().isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter Delivery Partner ID and Password',
      );
      return false;
    }

    // Dynamic mock partner
    final partner = PartnerModel(
      id: username.trim().toUpperCase(),
      name: AppConstants.defaultPartnerName,
      username: username.trim(),
      phone: '+91 98765 43210',
      hubName: AppConstants.defaultPartnerZone,
    );

    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      partner: partner,
      errorMessage: null,
    );
    return true;
  }

  void logout() {
    state = const AuthState(
      isLoading: false,
      isAuthenticated: false,
      partner: null,
    );
  }
}

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel();
});
