import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/notifications/fcm_notification_navigator.dart';

/// Starts FCM notification-tap navigation once per app launch.
class FcmNotificationBootstrap extends ConsumerStatefulWidget {
  const FcmNotificationBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<FcmNotificationBootstrap> createState() =>
      _FcmNotificationBootstrapState();
}

class _FcmNotificationBootstrapState
    extends ConsumerState<FcmNotificationBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fcmNotificationNavigatorProvider).start();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
