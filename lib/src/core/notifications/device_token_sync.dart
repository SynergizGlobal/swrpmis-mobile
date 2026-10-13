import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/notifications/device_token_payload.dart';
import 'package:swr_pmis_mobile/src/core/notifications/fcm_messaging_service.dart';
import 'package:swr_pmis_mobile/src/core/notifications/swr_device_token_data_source.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/providers/auth_token_provider.dart';

/// Registers / deactivates FCM tokens on SWR when the session is ready.
///
/// Must not read [authControllerProvider] — that provider depends on this one.
class DeviceTokenSync {
  DeviceTokenSync(this._ref);

  final Ref _ref;
  Future<void>? _fcmReadyFuture;

  FcmMessagingService get _fcm => _ref.read(fcmMessagingServiceProvider);

  SwrDeviceTokenDataSource get _remote =>
      _ref.read(swrDeviceTokenDataSourceProvider);

  /// All callers share one in-flight init so nobody skips ahead of register.
  Future<void> ensureFcmReady() async {
    final Future<void>? inFlight = _fcmReadyFuture;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final Completer<void> completer = Completer<void>();
    _fcmReadyFuture = completer.future;
    try {
      await _fcm.initialize(
        onTokenRefresh: (DeviceTokenPayload payload) {
          unawaited(register(payloadOverride: payload));
        },
      );
      completer.complete();
    } catch (error, stack) {
      _fcmReadyFuture = null;
      completer.completeError(error, stack);
      rethrow;
    }
  }

  /// After SWR login: initialize FCM, then register the device token.
  Future<void> ensureSessionAndRegister() async {
    if (kDebugMode) {
      debugPrint('FCM ensureSessionAndRegister start');
    }
    try {
      await ensureFcmReady();
      await register(force: true);
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('FCM device register sync failed: $error\n$stack');
      }
    }
  }

  Future<void> register({
    DeviceTokenPayload? payloadOverride,
    bool force = false,
  }) async {
    try {
      await ensureFcmReady();
      final bool sessionActive = _ref.read(swrSessionActiveProvider);
      if (!force && !sessionActive) {
        if (kDebugMode) {
          debugPrint('FCM register skipped: SWR session inactive');
        }
        return;
      }
      final DeviceTokenPayload? payload =
          payloadOverride ?? await _fcm.buildPayload();
      if (payload == null) {
        if (kDebugMode) {
          debugPrint('FCM register skipped: no token/platform');
        }
        return;
      }
      if (kDebugMode) {
        debugPrint(
          'FCM register calling API → '
          '${payload.platform} deviceId=${payload.deviceId}',
        );
      }
      await _remote.register(payload);
      if (kDebugMode) {
        debugPrint('FCM device registered on SWR (${payload.platform})');
      }
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('FCM register failed: $error\n$stack');
      }
    }
  }

  Future<void> deactivate() async {
    await ensureFcmReady();
    final DeviceTokenPayload? payload = await _fcm.buildPayload();
    if (payload == null) {
      return;
    }
    try {
      await _remote.deactivate(payload);
      if (kDebugMode) {
        debugPrint('FCM device deactivated on SWR');
      }
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('FCM deactivate failed: $error\n$stack');
      }
    }
  }
}

final deviceTokenSyncProvider = Provider<DeviceTokenSync>((ref) {
  return DeviceTokenSync(ref);
});
