import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

class TokenStorage {
  final SharedPreferences _prefs;

  TokenStorage(this._prefs);

  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';
  static const String _keyIsLoggedIn = 'is_logged_in';

  // --- Auth Token ---
  Future<bool> saveToken(String token) async {
    return await _prefs.setString(_keyToken, token);
  }

  String? getToken() {
    return _prefs.getString(_keyToken);
  }

  bool hasToken() {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }

  // --- User Profile ---
  Future<bool> saveUser(UserModel user) async {
    final jsonStr = jsonEncode(user.toJson());
    return await _prefs.setString(_keyUser, jsonStr);
  }

  UserModel? getUser() {
    final jsonStr = _prefs.getString(_keyUser);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // --- Login State ---
  Future<bool> setLoggedIn(bool isLoggedIn) async {
    return await _prefs.setBool(_keyIsLoggedIn, isLoggedIn);
  }

  bool isLoggedIn() {
    return _prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // --- Clear on Logout ---
  Future<void> clear() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyUser);
    await _prefs.setBool(_keyIsLoggedIn, false);
  }
}

/// Riverpod provider for TokenStorage
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  throw UnimplementedError('tokenStorageProvider must be overridden in ProviderScope in main.dart');
});
