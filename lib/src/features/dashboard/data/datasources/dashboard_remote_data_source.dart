import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/dashboard/domain/entities/home_dashboard_data.dart';

final dashboardRemoteDataSourceProvider =
    Provider<DashboardRemoteDataSource>((ref) {
  return DashboardRemoteDataSource(ref.watch(dioProvider));
});

class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._dio);

  final Dio _dio;

  Future<HomeDashboardData> fetchHome() async {
    final List<List<Map<String, dynamic>>> results =
        await Future.wait(<Future<List<Map<String, dynamic>>>>[
      _getList(ApiConstants.projectsListPath),
      _getList(ApiConstants.usersByTypePath),
      _getList(ApiConstants.projectTypesPath),
      _getList(ApiConstants.projectListByTypePath),
    ]);
    return HomeDashboardData.fromApiLists(
      projectList: results[0],
      usersByType: results[1],
      projectTypes: results[2],
      projectListByType: results[3],
    );
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final Response<dynamic> response = await _dio.get<dynamic>(path);
    return _asList(response.data);
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
