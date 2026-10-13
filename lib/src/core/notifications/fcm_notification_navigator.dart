import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/firebase_options.dart';
import 'package:swr_pmis_mobile/src/app/router/app_router.dart';
import 'package:swr_pmis_mobile/src/core/notifications/notification_route_resolver.dart';
import 'package:swr_pmis_mobile/src/core/notifications/pending_notification_location.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_user_role.dart';

/// Listens for notification taps and navigates to the matching screen.
class FcmNotificationNavigator {
  FcmNotificationNavigator(this._ref);

  final Ref _ref;
  StreamSubscription<RemoteMessage>? _openedSub;
  bool _started = false;

  Future<void> start() async {
    if (_started || kIsWeb || !DefaultFirebaseOptions.isConfigured) {
      return;
    }
    _started = true;

    final RemoteMessage? initial = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initial != null) {
      _handleMessage(initial);
    }

    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
    final String? type = NotificationRouteResolver.typeFromData(data);
    final String? referenceType =
        NotificationRouteResolver.referenceTypeFromData(data);
    final String? referenceId = NotificationRouteResolver.referenceIdFromData(
      data,
    );
    final String? notificationUserId = NotificationRouteResolver.userIdFromData(
      data,
    );
    final AuthSession? session = _ref.read(authControllerProvider).valueOrNull;

    if (kDebugMode) {
      debugPrint(
        'FCM tap → type=$type referenceType=$referenceType '
        'referenceId=$referenceId userId=$notificationUserId '
        'loggedIn=${session != null}',
      );
    }

    if (session != null &&
        !NotificationRouteResolver.isIntendedForUser(
          notificationUserId: notificationUserId,
          sessionUserId: session.userId,
        )) {
      if (kDebugMode) {
        debugPrint(
          'FCM tap ignored: notification userId=$notificationUserId '
          '!= session=${session.userId}',
        );
      }
      return;
    }

    _ref
        .read(pendingNotificationNavProvider.notifier)
        .state = PendingNotificationNav(
      type: type,
      referenceType: referenceType,
      referenceId: referenceId,
      userId: notificationUserId,
    );

    if (session == null) {
      return;
    }

    final String location = NotificationRouteResolver.resolve(
      type: type,
      role: RfiUserRoleResolver.fromSession(session),
      referenceType: referenceType,
      referenceId: referenceId,
    );
    scheduleMicrotask(() {
      try {
        _ref.read(appRouterProvider).go(location);
        _ref.read(pendingNotificationNavProvider.notifier).state = null;
      } catch (error, stack) {
        if (kDebugMode) {
          debugPrint('FCM navigation failed: $error\n$stack');
        }
      }
    });
  }

  void dispose() {
    _openedSub?.cancel();
    _openedSub = null;
  }
}

final fcmNotificationNavigatorProvider = Provider<FcmNotificationNavigator>((
  ref,
) {
  final FcmNotificationNavigator navigator = FcmNotificationNavigator(ref);
  ref.onDispose(navigator.dispose);
  return navigator;
});
