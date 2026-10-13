class DeviceTokenPayload {
  const DeviceTokenPayload({
    required this.fcmToken,
    required this.platform,
    required this.deviceId,
  });

  final String fcmToken;
  final String platform;
  final String deviceId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'fcmToken': fcmToken,
    'platform': platform,
    'deviceId': deviceId,
  };
}
