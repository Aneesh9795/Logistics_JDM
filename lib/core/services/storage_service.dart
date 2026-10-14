import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/models/partner_model.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _keyToken = 'auth_token';
  static const String _keyPartner = 'partner_profile';
  static const String _keyIsLoggedIn = 'is_logged_in';

  // --- Auth Token ---
  Future<bool> saveAuthToken(String token) async {
    return await _prefs.setString(_keyToken, token);
  }

  String? getAuthToken() {
    return _prefs.getString(_keyToken);
  }

  bool hasAuthToken() {
    final token = getAuthToken();
    return token != null && token.isNotEmpty;
  }

  // --- Partner Data ---
  Future<bool> savePartner(PartnerModel partner) async {
    final jsonStr = jsonEncode(partner.toJson());
    return await _prefs.setString(_keyPartner, jsonStr);
  }

  PartnerModel? getPartner() {
    final jsonStr = _prefs.getString(_keyPartner);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return PartnerModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // --- Login Status ---
  Future<bool> setLoggedIn(bool isLoggedIn) async {
    return await _prefs.setBool(_keyIsLoggedIn, isLoggedIn);
  }

  bool isLoggedIn() {
    return _prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // --- Clear on Logout ---
  Future<void> clearAll() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyPartner);
    await _prefs.setBool(_keyIsLoggedIn, false);
  }
}

/// Provider for StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider must be overridden in ProviderScope in main.dart');
});
