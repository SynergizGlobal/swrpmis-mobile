import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Clears delivered notifications from the system tray/notification center.
abstract final class NotificationTrayClearer {
  static const MethodChannel _channel = MethodChannel(
    'swr_pmis_mobile/notifications',
  );

  static Future<void> clearAll() async {
    if (kIsWeb) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('clearAll');
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Failed to clear notification tray: $error\n$stack');
      }
    }
  }
}
