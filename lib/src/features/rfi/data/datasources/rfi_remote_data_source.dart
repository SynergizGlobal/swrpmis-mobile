import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_list_item.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_list_kind.dart';

final rfiRemoteDataSourceProvider = Provider<RfiRemoteDataSource>((ref) {
  return RfiRemoteDataSource(ref.watch(dioProvider));
});

class RfiRemoteDataSource {
  RfiRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<RfiListItem>> fetchList(RfiListKind kind) async {
    final String path = switch (kind) {
      RfiListKind.material => ApiConstants.materialRfiListPath,
      RfiListKind.work => ApiConstants.workRfiListPath,
      RfiListKind.quality => ApiConstants.qualityRfiListPath,
    };
    final Response<dynamic> response = await _dio.get<dynamic>(path);
    return _asList(
      response.data,
    ).map(RfiListItem.fromJson).toList(growable: false);
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((Map item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (data is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(data);
      for (final String key in const <String>[
        'data',
        'result',
        'content',
        'list',
        'records',
      ]) {
        final Object? nested = map[key];
        if (nested is List) {
          return _asList(nested);
        }
      }
    }
    return <Map<String, dynamic>>[];
  }
}
