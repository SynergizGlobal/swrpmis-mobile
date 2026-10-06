import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/reports_tree.dart';

final reportsRemoteDataSourceProvider = Provider<ReportsRemoteDataSource>((
  ref,
) {
  return ReportsRemoteDataSource(ref.watch(dioProvider));
});

class ReportsRemoteDataSource {
  ReportsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<ReportsTree> fetchReportForms() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.reportFormsPath,
    );
    return ReportsTree.fromApi(_asList(response.data));
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
