import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_menu_access.dart';

final rfiMenuAccessRemoteDataSourceProvider =
    Provider<RfiMenuAccessRemoteDataSource>((ref) {
      return RfiMenuAccessRemoteDataSource(ref.watch(dioProvider));
    });

class RfiMenuAccessRemoteDataSource {
  RfiMenuAccessRemoteDataSource(this._dio);

  final Dio _dio;

  Future<RfiMenuAccess> fetch({
    required String userRole,
    required String userType,
    required String userId,
  }) async {
    final String role = userRole
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '+');
    final String type = Uri.encodeQueryComponent(userType.trim());
    final String id = Uri.encodeQueryComponent(userId.trim());
    final Response<dynamic> response = await _dio.get<dynamic>(
      '${ApiConstants.rfiMenuAccessPath}'
      '?userRole=$role&userType=$type&userId=$id',
    );
    final Map<String, dynamic> map = _asMap(response.data);
    return RfiMenuAccess.fromJson(map);
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(data);
      for (final String key in const <String>['data', 'result', 'content']) {
        final Object? nested = map[key];
        if (nested is Map) {
          return Map<String, dynamic>.from(nested);
        }
      }
      return map;
    }
    return <String, dynamic>{};
  }
}
