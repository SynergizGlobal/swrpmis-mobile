import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/quality_test_register/domain/quality_test_register_detail.dart';
import 'package:swr_pmis_mobile/src/features/quality_test_register/domain/quality_test_register_list.dart';
import 'package:swr_pmis_mobile/src/features/quality_test_register/domain/quality_test_register_parse.dart';

final qualityTestRegisterRemoteDataSourceProvider =
    Provider<QualityTestRegisterRemoteDataSource>((ref) {
      return QualityTestRegisterRemoteDataSource(ref.watch(dioProvider));
    });

class QualityTestRegisterRemoteDataSource {
  QualityTestRegisterRemoteDataSource(this._dio);

  final Dio _dio;

  Future<QualityTestRegisterSnapshot> fetch(
    QualityTestRegisterListQuery query, {
    QualityTestRegisterSnapshot previous = QualityTestRegisterSnapshot.empty,
    bool reloadFilters = true,
  }) async {
    final Future<({List<QualityTestObligationRow> rows, int total})> listFuture =
        _getList(query);
    final Future<QualityTestRegisterSnapshot> filtersFuture = reloadFilters
        ? _getFilters(query.projectId)
        : Future<QualityTestRegisterSnapshot>.value(previous);
    final List<Object> results = await Future.wait<Object>(
      <Future<Object>>[listFuture, filtersFuture],
    );
    final ({List<QualityTestObligationRow> rows, int total}) list =
        results[0] as ({List<QualityTestObligationRow> rows, int total});
    final QualityTestRegisterSnapshot filters =
        results[1] as QualityTestRegisterSnapshot;
    final List<QualityTestObligationRow> rows = enrichQualityTestRows(
      rows: list.rows,
      projects: filters.projects,
      contracts: filters.contracts,
    );
    return QualityTestRegisterSnapshot(
      projects: filters.projects,
      sections: filters.sections,
      contracts: filters.contracts,
      materials: filters.materials,
      rows: rows,
      total: list.total,
    );
  }

  Future<QualityTestObligationDetail> fetchDetail(int id) async {
    if (id < 1) {
      throw StateError('Obligation id is required.');
    }
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.qualityTestObligationDetailPath(id),
    );
    return parseQualityTestObligationDetail(response.data);
  }

  Future<({List<QualityTestObligationRow> rows, int total})> _getList(
    QualityTestRegisterListQuery query,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.qualityTestObligationsPath,
      queryParameters: query.listQueryParameters(),
    );
    return parseQualityTestObligationList(response.data);
  }

  Future<QualityTestRegisterSnapshot> _getFilters(String projectId) async {
    final String id = projectId.trim();
    final List<List<QualityTestOption>> results =
        await Future.wait<List<QualityTestOption>>(
          <Future<List<QualityTestOption>>>[
            _safeOptions(_fetchDropdownProjects),
            _safeOptions(_fetchDropdownMaterials),
            id.isEmpty
                ? Future<List<QualityTestOption>>.value(
                    const <QualityTestOption>[],
                  )
                : _safeOptions(() => _fetchDropdownSections(id)),
            id.isEmpty
                ? Future<List<QualityTestOption>>.value(
                    const <QualityTestOption>[],
                  )
                : _safeOptions(() => _fetchDropdownContracts(id)),
          ],
        );
    return QualityTestRegisterSnapshot(
      projects: results[0],
      materials: results[1],
      sections: results[2],
      contracts: results[3],
    );
  }

  Future<List<QualityTestOption>> _safeOptions(
    Future<List<QualityTestOption>> Function() load,
  ) async {
    try {
      return await load();
    } on Object {
      return const <QualityTestOption>[];
    }
  }

  Future<List<QualityTestOption>> _fetchDropdownProjects() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialReceiptDropdownProjectsPath,
    );
    return parseQualityTestDropdownProjects(response.data);
  }

  Future<List<QualityTestOption>> _fetchDropdownMaterials() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialReceiptDropdownMaterialsPath,
    );
    return parseQualityTestDropdownMaterials(response.data);
  }

  Future<List<QualityTestOption>> _fetchDropdownSections(
    String projectId,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialReceiptDropdownSectionsPath,
      queryParameters: <String, dynamic>{'projectIdFk': projectId},
    );
    return parseQualityTestDropdownSections(response.data);
  }

  Future<List<QualityTestOption>> _fetchDropdownContracts(
    String projectId,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialReceiptDropdownContractsPath,
      queryParameters: <String, dynamic>{'projectIdFk': projectId},
    );
    return parseQualityTestDropdownContracts(response.data);
  }
}
