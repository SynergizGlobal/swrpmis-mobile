import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

enum AppUpdatePromptType { none, optional, force }

class AppUpdateConfig {
  const AppUpdateConfig({
    required this.promptType,
    required this.currentVersion,
    required this.minVersion,
    required this.latestVersion,
    required this.message,
    required this.storeUrl,
    required this.optionalReminderHours,
  });

  final AppUpdatePromptType promptType;
  final String currentVersion;
  final String minVersion;
  final String latestVersion;
  final String message;
  final String storeUrl;
  final int optionalReminderHours;

  bool get shouldPrompt => promptType != AppUpdatePromptType.none;
  bool get isForce => promptType == AppUpdatePromptType.force;
}

class AppUpdateRemoteValues {
  const AppUpdateRemoteValues({
    required this.checkEnabled,
    required this.minVersion,
    required this.latestVersion,
    required this.forceMessage,
    required this.optionalMessage,
    required this.optionalReminderHours,
    required this.androidStoreUrl,
    required this.iosStoreUrl,
    required this.iosAppStoreId,
  });

  static const String androidPackageName = 'com.synergiz.swr.pmis';

  final bool checkEnabled;
  final String minVersion;
  final String latestVersion;
  final String forceMessage;
  final String optionalMessage;
  final int optionalReminderHours;
  final String androidStoreUrl;
  final String iosStoreUrl;
  final String iosAppStoreId;

  String resolveStoreUrl() {
    if (!kIsWeb && Platform.isAndroid) {
      final String override = androidStoreUrl.trim();
      if (override.isNotEmpty) {
        return override;
      }
      return 'https://play.google.com/store/apps/details?id=$androidPackageName';
    }
    if (!kIsWeb && Platform.isIOS) {
      final String override = iosStoreUrl.trim();
      if (override.isNotEmpty) {
        return override;
      }
      final String appStoreId = iosAppStoreId.trim();
      if (appStoreId.isNotEmpty) {
        return 'https://apps.apple.com/app/id$appStoreId';
      }
    }
    return '';
  }
}
