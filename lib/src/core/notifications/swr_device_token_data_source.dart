import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/core/notifications/device_token_payload.dart';

/// Device token APIs on the SWR session client.
class SwrDeviceTokenDataSource {
  const SwrDeviceTokenDataSource(this._dio);

  final Dio _dio;

  Future<void> register(DeviceTokenPayload payload) async {
    await _dio.post<dynamic>(
      ApiConstants.deviceTokenRegisterPath,
      data: payload.toJson(),
    );
  }

  Future<void> deactivate(DeviceTokenPayload payload) async {
    await _dio.post<dynamic>(
      ApiConstants.deviceTokenDeactivatePath,
      data: payload.toJson(),
    );
  }
}

final swrDeviceTokenDataSourceProvider = Provider<SwrDeviceTokenDataSource>((
  ref,
) {
  return SwrDeviceTokenDataSource(ref.watch(dioProvider));
});
