import 'dart:io' show Platform;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swr_pmis_mobile/src/core/app_update/app_update_config.dart';
import 'package:swr_pmis_mobile/src/core/app_update/app_version_utils.dart';
import 'package:swr_pmis_mobile/src/core/firebase/remote_config_initializer.dart';

class AppUpdateService {
  AppUpdateService({required this._prefs});

  static const String _optionalDismissedAtKey =
      'app_update_optional_dismissed_at_ms';

  final SharedPreferences _prefs;

  Future<AppUpdateConfig> evaluate() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    final String currentVersion = info.version.trim();

    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return _none(currentVersion);
    }

    if (!RemoteConfigInitializer.isAvailable) {
      return _none(currentVersion);
    }

    final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
    final AppUpdateRemoteValues values = _readRemoteValues(remoteConfig);

    if (!values.checkEnabled) {
      return _none(currentVersion);
    }

    final String minVersion = values.minVersion.trim();
    final String latestVersion = values.latestVersion.trim();
    final String storeUrl = values.resolveStoreUrl();

    if (minVersion.isNotEmpty &&
        AppVersionUtils.isOlderThan(currentVersion, minVersion)) {
      return AppUpdateConfig(
        promptType: AppUpdatePromptType.force,
        currentVersion: currentVersion,
        minVersion: minVersion,
        latestVersion: latestVersion.isEmpty ? minVersion : latestVersion,
        message: values.forceMessage,
        storeUrl: storeUrl,
        optionalReminderHours: values.optionalReminderHours,
      );
    }

    if (latestVersion.isEmpty ||
        !AppVersionUtils.isOlderThan(currentVersion, latestVersion)) {
      return _none(currentVersion);
    }

    if (!_shouldShowOptionalReminder(values.optionalReminderHours)) {
      return _none(currentVersion);
    }

    return AppUpdateConfig(
      promptType: AppUpdatePromptType.optional,
      currentVersion: currentVersion,
      minVersion: minVersion,
      latestVersion: latestVersion,
      message: values.optionalMessage,
      storeUrl: storeUrl,
      optionalReminderHours: values.optionalReminderHours,
    );
  }

  Future<void> recordOptionalDismissal() async {
    await _prefs.setInt(
      _optionalDismissedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  AppUpdateConfig _none(String currentVersion) {
    return AppUpdateConfig(
      promptType: AppUpdatePromptType.none,
      currentVersion: currentVersion,
      minVersion: currentVersion,
      latestVersion: currentVersion,
      message: '',
      storeUrl: '',
      optionalReminderHours: 24,
    );
  }

  bool _shouldShowOptionalReminder(int intervalHours) {
    final int? dismissedAtMs = _prefs.getInt(_optionalDismissedAtKey);
    if (dismissedAtMs == null) {
      return true;
    }
    final int hours = intervalHours <= 0 ? 24 : intervalHours;
    final DateTime dismissedAt = DateTime.fromMillisecondsSinceEpoch(
      dismissedAtMs,
    );
    return DateTime.now().difference(dismissedAt) >= Duration(hours: hours);
  }

  int _readReminderHours(int raw) {
    if (raw <= 0) {
      return 24;
    }
    return raw.clamp(1, 168);
  }

  AppUpdateRemoteValues _readRemoteValues(FirebaseRemoteConfig remoteConfig) {
    final bool isAndroid = !kIsWeb && Platform.isAndroid;
    final bool isIos = !kIsWeb && Platform.isIOS;

    String platformOrFallback(String platformKey, String fallbackKey) {
      final String platformValue = remoteConfig.getString(platformKey).trim();
      if (platformValue.isNotEmpty) {
        return platformValue;
      }
      return remoteConfig.getString(fallbackKey).trim();
    }

    return AppUpdateRemoteValues(
      checkEnabled: remoteConfig.getBool('update_check_enabled'),
      minVersion: isAndroid
          ? platformOrFallback('min_version_android', 'min_version')
          : isIos
          ? platformOrFallback('min_version_ios', 'min_version')
          : remoteConfig.getString('min_version').trim(),
      latestVersion: isAndroid
          ? platformOrFallback('latest_version_android', 'latest_version')
          : isIos
          ? platformOrFallback('latest_version_ios', 'latest_version')
          : remoteConfig.getString('latest_version').trim(),
      forceMessage:
          remoteConfig.getString('force_update_message').trim().isEmpty
          ? 'A required update is available. Please update SWR-PMIS from the store to continue.'
          : remoteConfig.getString('force_update_message').trim(),
      optionalMessage:
          remoteConfig.getString('optional_update_message').trim().isEmpty
          ? 'A new version of SWR-PMIS is available.'
          : remoteConfig.getString('optional_update_message').trim(),
      optionalReminderHours: _readReminderHours(
        remoteConfig.getInt('optional_update_interval_hours'),
      ),
      androidStoreUrl: remoteConfig.getString('android_store_url').trim(),
      iosStoreUrl: remoteConfig.getString('ios_store_url').trim(),
      iosAppStoreId: remoteConfig.getString('ios_app_store_id').trim(),
    );
  }
}
