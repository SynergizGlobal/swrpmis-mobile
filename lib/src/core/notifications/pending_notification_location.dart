import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pending FCM navigation payload before auth is ready.
class PendingNotificationNav {
  const PendingNotificationNav({
    this.type,
    this.referenceType,
    this.referenceId,
    this.userId,
  });

  final String? type;
  final String? referenceType;
  final String? referenceId;

  /// Target user from FCM `data.userId` (backend).
  final String? userId;
}

final pendingNotificationNavProvider = StateProvider<PendingNotificationNav?>(
  (ref) => null,
);
