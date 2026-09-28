import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swr_pmis_mobile/src/features/auth/data/models/auth_session_model.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';

class AuthLocalSnapshot {
  const AuthLocalSnapshot({
    required this.rememberMe,
    this.userId,
    this.password,
    this.userProfileJson,
  });

  final bool rememberMe;
  final String? userId;
  final String? password;
  final String? userProfileJson;
}

class AuthLocalDataSource {
  static const String _rememberMeKey = 'remember_me';
  static const String _userProfileJsonKey = 'saved_user_profile_json';
  static const String _secureUserIdKey = 'secure_saved_user_id';
  static const String _securePasswordKey = 'secure_saved_password';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<AuthLocalSnapshot> readSnapshot() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userId = await _secureStorage.read(key: _secureUserIdKey);
    final String? password = await _secureStorage.read(key: _securePasswordKey);
    return AuthLocalSnapshot(
      rememberMe: prefs.getBool(_rememberMeKey) ?? false,
      userId: userId,
      password: password,
      userProfileJson: prefs.getString(_userProfileJsonKey),
    );
  }

  Future<void> saveAfterLogin({
    required bool rememberMe,
    required String userId,
    required String password,
    required AuthSession session,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, rememberMe);
    if (rememberMe) {
      await _secureStorage.write(key: _secureUserIdKey, value: userId);
      await _secureStorage.write(key: _securePasswordKey, value: password);
      final AuthSessionModel model = session is AuthSessionModel
          ? session
          : AuthSessionModel(
              token: session.token,
              userId: session.userId,
              userName: session.userName,
              emailId: session.emailId,
              userRoleNameFk: session.userRoleNameFk,
              userTypeFk: session.userTypeFk,
              departmentFk: session.departmentFk,
              designation: session.designation,
            );
      await prefs.setString(_userProfileJsonKey, jsonEncode(model.toJson()));
      return;
    }
    await _secureStorage.delete(key: _secureUserIdKey);
    await _secureStorage.delete(key: _securePasswordKey);
    await prefs.remove(_userProfileJsonKey);
  }

  Future<void> clearAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberMeKey);
    await _secureStorage.delete(key: _secureUserIdKey);
    await _secureStorage.delete(key: _securePasswordKey);
    await prefs.remove(_userProfileJsonKey);
  }
}

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSource();
});
