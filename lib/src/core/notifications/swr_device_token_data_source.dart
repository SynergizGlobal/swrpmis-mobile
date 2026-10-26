import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/core/notifications/device_token_payload.dart';

/// Device token APIs on SWR (`/swr/device-tokens`), session cookie auth.
class SwrDeviceTokenDataSource {
  const SwrDeviceTokenDataSource(this._dio);

  final Dio _dio;

  /// POST `/swr/device-tokens/register` — body: fcmToken, platform, deviceId.
  Future<void> register(DeviceTokenPayload payload) async {
    await _dio.post<dynamic>(
      ApiConstants.deviceTokenRegisterPath,
      data: payload.toJson(),
    );
  }

  /// POST `/swr/device-tokens/deactivate` — body: deviceId (required).
  Future<void> deactivate({required String deviceId}) async {
    await _dio.post<dynamic>(
      ApiConstants.deviceTokenDeactivatePath,
      data: <String, dynamic>{'deviceId': deviceId},
    );
  }
}

final swrDeviceTokenDataSourceProvider = Provider<SwrDeviceTokenDataSource>((
  ref,
) {
  return SwrDeviceTokenDataSource(ref.watch(dioProvider));
});
