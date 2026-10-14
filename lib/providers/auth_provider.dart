import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/token_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
  });

  UserModel? get partner => user;

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final TokenStorage _tokenStorage;

  AuthNotifier({
    required AuthService authService,
    required TokenStorage tokenStorage,
  })  : _authService = authService,
        _tokenStorage = tokenStorage,
        super(const AuthState());

  /// Check saved login status on app startup
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    final hasToken = _tokenStorage.hasToken();
    final cachedUser = _tokenStorage.getUser();

    state = state.copyWith(
      isLoading: false,
      isAuthenticated: hasToken && cachedUser != null,
      user: cachedUser,
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
      final result = await _authService.login(
        mobile: cleanMobile,
        password: cleanPassword,
      );

      // Save token and user data in local storage
      if (result.token.isNotEmpty) {
        await _tokenStorage.saveToken(result.token);
      }
      await _tokenStorage.saveUser(result.user);
      await _tokenStorage.setLoggedIn(true);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: result.user,
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
    await _authService.logout();
    await _tokenStorage.clear();

    state = const AuthState(
      isLoading: false,
      isAuthenticated: false,
      user: null,
      errorMessage: null,
    );
  }
}

/// Riverpod provider for AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);

  return AuthNotifier(
    authService: authService,
    tokenStorage: tokenStorage,
  );
});
