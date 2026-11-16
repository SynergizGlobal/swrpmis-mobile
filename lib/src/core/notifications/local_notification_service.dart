import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider, Ref;
import 'package:swr_pmis_mobile/firebase_options.dart';

/// Shows a local notification for data-only FCM messages that arrive while the
/// app is in the foreground (FCM does not auto-display these).
class LocalNotificationService {
  LocalNotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _foregroundSub;
  bool _initialized = false;

  static const String _channelId = 'swr_pmis_default';
  static const String _channelName = 'SWR PMIS Notifications';

  /// The payload from the most recent local-notification tap, if any.
  /// Consumed by the navigator on start-up.
  static String? pendingPayload;

  /// Set by the notification navigator so taps while the app is already
  /// running can trigger navigation immediately.
  static void Function(String payload)? onTapCallback;

  Future<void> initialize() async {
    if (kIsWeb || !DefaultFirebaseOptions.isConfigured || _initialized) {
      return;
    }
    _initialized = true;

    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }

    _foregroundSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
  }

  void _onForegroundMessage(RemoteMessage message) {
    final Map<String, dynamic> data = message.data;
    final String? title =
        message.notification?.title ?? data['title']?.toString();
    final String? body =
        message.notification?.body ?? data['body']?.toString();
    if (title == null && body == null) {
      return;
    }
    _show(title ?? '', body ?? '', data);
  }

  Future<void> _show(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    const AndroidNotificationDetails android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails ios = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(
      android: android,
      iOS: ios,
    );
    final int id = DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: jsonEncode(data),
    );
  }

  static void _onTap(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload == null || payload.isEmpty) {
      return;
    }
    final void Function(String)? callback = onTapCallback;
    if (callback != null) {
      callback(payload);
    } else {
      pendingPayload = payload;
    }
  }

  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    _foregroundSub = null;
  }
}

final localNotificationServiceProvider =
    Provider<LocalNotificationService>((Ref ref) {
  final LocalNotificationService service = LocalNotificationService();
  ref.onDispose(service.dispose);
  return service;
});
