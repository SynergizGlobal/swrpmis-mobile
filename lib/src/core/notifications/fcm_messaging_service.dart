import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swr_pmis_mobile/firebase_options.dart';
import 'package:swr_pmis_mobile/src/core/notifications/device_id_store.dart';
import 'package:swr_pmis_mobile/src/core/notifications/device_token_payload.dart';

/// Handles FCM permission, token, and payload used by auth register/logout.
class FcmMessagingService {
  FcmMessagingService({this._deviceIdStore = const DeviceIdStore()});

  static const String _cachedTokenKey = 'cached_fcm_token';

  final DeviceIdStore _deviceIdStore;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription<String>? _tokenRefreshSub;
  bool _initialized = false;

  Future<void> initialize({
    void Function(DeviceTokenPayload payload)? onTokenRefresh,
  }) async {
    if (kIsWeb || !DefaultFirebaseOptions.isConfigured || _initialized) {
      return;
    }
    _initialized = true;

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _requestPermission();

    final String? token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _cacheToken(token);
    }

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((String token) async {
      await _cacheToken(token);
      if (onTokenRefresh == null) {
        return;
      }
      final DeviceTokenPayload? payload = await buildPayload(
        tokenOverride: token,
      );
      if (payload != null) {
        onTokenRefresh(payload);
      }
    });
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (!kIsWeb && Platform.isIOS) {
      await _messaging.getAPNSToken();
    }
  }

  Future<void> _cacheToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedTokenKey, token);
  }

  Future<String?> _readCachedToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cached = prefs.getString(_cachedTokenKey)?.trim();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    return null;
  }

  String? get platformName {
    if (kIsWeb) {
      return null;
    }
    if (Platform.isAndroid) {
      return 'android';
    }
    if (Platform.isIOS) {
      return 'ios';
    }
    return null;
  }

  Future<DeviceTokenPayload?> buildPayload({String? tokenOverride}) async {
    final String? platform = platformName;
    if (platform == null) {
      return null;
    }

    String? token = tokenOverride?.trim();
    if (token == null || token.isEmpty) {
      try {
        token = (await _messaging.getToken())?.trim();
      } catch (_) {
        token = null;
      }
    }
    token ??= await _readCachedToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    final String deviceId = await _deviceIdStore.getOrCreate();
    await _cacheToken(token);
    return DeviceTokenPayload(
      fcmToken: token,
      platform: platform,
      deviceId: deviceId,
    );
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }
}

final fcmMessagingServiceProvider = Provider<FcmMessagingService>((ref) {
  final FcmMessagingService service = FcmMessagingService();
  ref.onDispose(service.dispose);
  return service;
});
