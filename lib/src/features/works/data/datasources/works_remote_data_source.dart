import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/execution_progress_segment.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/works_tree.dart';

final worksRemoteDataSourceProvider = Provider<WorksRemoteDataSource>((ref) {
  return WorksRemoteDataSource(ref.watch(dioProvider));
});

class WorksRemoteDataSource {
  WorksRemoteDataSource(this._dio);

  final Dio _dio;

  Future<WorksTree> fetchWorksTree() async {
    final List<List<Map<String, dynamic>>> results =
        await Future.wait(<Future<List<Map<String, dynamic>>>>[
          _getList(ApiConstants.projectTypesPath),
          _getList(ApiConstants.projectsListPath),
        ]);
    return WorksTree.fromApi(projectTypes: results[0], projects: results[1]);
  }

  Future<List<ExecutionProgressSegment>> fetchExecutionProgress(
    String projectId,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.executionProgressPath,
      queryParameters: <String, String>{'project_id': projectId},
    );
    return _asList(response.data)
        .map(ExecutionProgressSegment.tryParse)
        .whereType<ExecutionProgressSegment>()
        .toList(growable: false);
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
