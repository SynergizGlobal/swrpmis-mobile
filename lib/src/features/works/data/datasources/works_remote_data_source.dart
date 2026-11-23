import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/exception_report.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/exception_report_detail.dart';
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

  Future<List<Map<String, dynamic>>> fetchSitePhotos({
    required String projectId,
  }) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.sitePhotosDisplayPath,
      queryParameters: <String, String>{'projectId': projectId},
    );
    return _asSitePhotoRows(response.data);
  }

  /// Daily Progress Report structure rows.
  ///
  /// Accepts a top-level JSON array or a wrapper map (`data` / `result` / …).
  Future<List<Map<String, dynamic>>> fetchDailyProgress({
    required String projectId,
    required String fromDate,
    required String toDate,
    required String date,
  }) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.dailyProgressPath,
      queryParameters: <String, String>{
        'fromDate': fromDate,
        'toDate': toDate,
        'date': date,
        'projectId': projectId,
      },
    );
    return _asDailyProgressRows(response.data);
  }

  Future<ExceptionReportData> fetchExceptionReport({
    required String projectId,
  }) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.exceptionReportPath,
      queryParameters: <String, String>{'projectId': projectId},
    );
    final dynamic data = response.data;
    if (data is Map) {
      return ExceptionReportData.fromMap(Map<String, dynamic>.from(data));
    }
    return const ExceptionReportData(
      summary: ExceptionReportSummary(
        structuresMonitored: 0,
        criticalExceptions: 0,
        generalDrawingsPending: 0,
        detailedDrawingsPending: 0,
        utilityShiftingImpacted: 0,
      ),
      structures: <ExceptionReportStructure>[],
    );
  }

  Future<ExceptionReportDetail> fetchExceptionReportStructure({
    required int structureId,
  }) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.exceptionReportStructurePath(structureId),
    );
    final dynamic data = response.data;
    if (data is Map) {
      return ExceptionReportDetail.fromMap(Map<String, dynamic>.from(data));
    }
    throw StateError('Empty exception report detail for $structureId');
  }

  /// Loads site / structure photo bytes via `/STRUCTURE_FILES/{fileName}`
  /// (same path used by WCR for site photos). Hard timeout so View Photos
  /// never hangs forever.
  Future<Uint8List> fetchStructurePhotoBytes(String fileName) async {
    final String trimmed = fileName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Photo file name is required.');
    }
    const Duration photoTimeout = Duration(seconds: 20);
    try {
      final Response<List<int>> response = await _dio
          .get<List<int>>(
            ApiConstants.structureFilePath(trimmed),
            options: Options(
              responseType: ResponseType.bytes,
              receiveTimeout: photoTimeout,
              sendTimeout: photoTimeout,
              connectTimeout: photoTimeout,
            ),
          )
          .timeout(photoTimeout);
      final List<int>? bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw StateError('Empty photo response for $trimmed');
      }
      return Uint8List.fromList(bytes);
    } on TimeoutException {
      throw StateError('Timed out loading photo $trimmed');
    }
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final Response<dynamic> response = await _dio.get<dynamic>(path);
    return _asList(response.data);
  }

  List<Map<String, dynamic>> _asSitePhotoRows(dynamic data) {
    final List<Map<String, dynamic>> list = _asList(data);
    if (list.isNotEmpty) {
      return list;
    }
    if (data is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(data);
      if (map.containsKey('photos') ||
          map.containsKey('structure') ||
          map.containsKey('created_date')) {
        return <Map<String, dynamic>>[map];
      }
    }
    return <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _asDailyProgressRows(dynamic data) {
    final List<Map<String, dynamic>> list = _asList(data);
    if (list.isNotEmpty) {
      return list;
    }
    if (data is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(data);
      if (map.containsKey('structure_type') ||
          map.containsKey('structure') ||
          map.containsKey('actual_till_date') ||
          map.containsKey('scope')) {
        return <Map<String, dynamic>>[map];
      }
    }
    return <Map<String, dynamic>>[];
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
        if (nested is Map) {
          return _asList(<dynamic>[nested]);
        }
      }
    }
    return <Map<String, dynamic>>[];
  }
}
