import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/ncr_observations/domain/ncr_observation_detail.dart';
import 'package:swr_pmis_mobile/src/features/ncr_observations/domain/ncr_observation_list.dart';
import 'package:swr_pmis_mobile/src/features/ncr_observations/domain/ncr_observation_parse.dart';

final ncrObservationRemoteDataSourceProvider =
    Provider<NcrObservationRemoteDataSource>((ref) {
      return NcrObservationRemoteDataSource(ref.watch(dioProvider));
    });

class NcrObservationRemoteDataSource {
  NcrObservationRemoteDataSource(this._dio);

  final Dio _dio;

  Future<NcrObservationSnapshot> fetch(
    NcrObservationListQuery query, {
    NcrObservationSnapshot previous = NcrObservationSnapshot.empty,
    bool reloadFilters = true,
  }) async {
    final Future<({List<NcrObservationRow> rows, int total})> listFuture =
        _getList(query);
    final Future<NcrObservationSnapshot> filtersFuture = reloadFilters
        ? _getFilters(query.projectId)
        : Future<NcrObservationSnapshot>.value(previous);
    final List<Object> results = await Future.wait<Object>(
      <Future<Object>>[listFuture, filtersFuture],
    );
    final ({List<NcrObservationRow> rows, int total}) list =
        results[0] as ({List<NcrObservationRow> rows, int total});
    final NcrObservationSnapshot filters =
        results[1] as NcrObservationSnapshot;
    final List<NcrObservationRow> rows = enrichNcrRows(
      rows: list.rows,
      projects: filters.projects,
      contracts: filters.contracts,
    );
    return NcrObservationSnapshot(
      projects: filters.projects,
      sections: filters.sections,
      contracts: filters.contracts,
      rows: rows,
      total: list.total,
    );
  }

  Future<NcrObservationDetail> fetchDetail(int id) async {
    if (id < 1) {
      throw StateError('NCR observation id is required.');
    }
    final Response<dynamic> ncrResponse = await _dio.get<dynamic>(
      ApiConstants.ncrObservationDetailPath(id),
    );
    final NcrObservationDetail base = parseNcrObservationDetail(
      ncrResponse.data,
    );

    final int? obligationId = base.testObligationId;
    final List<Object?> extras = await Future.wait<Object?>(
      <Future<Object?>>[
        obligationId == null || obligationId < 1
            ? Future<NcrObligationReference>.value(
                NcrObligationReference.empty,
              )
            : _safeObligation(obligationId),
        _safeAttachments(id, 'ISSUE'),
        _safeAttachments(id, 'CORRECTIVE_ACTION'),
      ],
    );

    return parseNcrObservationDetail(
      ncrResponse.data,
      obligation: extras[0] as NcrObligationReference,
      issueAttachments: extras[1] as List<NcrAttachment>,
      correctiveAttachments: extras[2] as List<NcrAttachment>,
    );
  }

  Future<NcrObservationDetail> verify({
    required int id,
    required bool approved,
    required String verificationRemarks,
    required String verifiedBy,
    NcrObservationDetail? current,
  }) async {
    if (id < 1) {
      throw StateError('NCR observation id is required.');
    }
    final String verifier = verifiedBy.trim();
    if (verifier.isEmpty) {
      throw StateError('Verified-by user id is required.');
    }
    final Response<dynamic> response = await _dio.put<dynamic>(
      ApiConstants.ncrObservationVerifyPath(id),
      data: <String, dynamic>{
        'approved': approved,
        'verificationRemarks': verificationRemarks.trim(),
        'verifiedBy': verifier,
      },
    );
    final NcrObservationDetail? prior = current;
    try {
      return parseNcrObservationDetail(
        response.data,
        obligation: prior?.obligation ?? NcrObligationReference.empty,
        issueAttachments: prior?.issueAttachments ?? const <NcrAttachment>[],
        correctiveAttachments:
            prior?.correctiveAttachments ?? const <NcrAttachment>[],
      );
    } on Object {
      return fetchDetail(id);
    }
  }

  Future<({List<NcrObservationRow> rows, int total})> _getList(
    NcrObservationListQuery query,
  ) async {
    final int apiPage = query.page < 1 ? 0 : query.page - 1;
    final int size = query.pageSize < 1 ? 10 : query.pageSize;
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.ncrObservationsPath,
      queryParameters: query.listQueryParameters(),
    );
    final int? headerTotal = _headerTotal(response.headers);
    return parseNcrObservationList(
      response.data,
      apiPage: apiPage,
      pageSize: size,
      headerTotal: headerTotal,
    );
  }

  Future<NcrObservationSnapshot> _getFilters(String projectId) async {
    final String id = projectId.trim();
    final List<List<NcrOption>> results = await Future.wait<List<NcrOption>>(
      <Future<List<NcrOption>>>[
        _safeOptions(_fetchDropdownProjects),
        id.isEmpty
            ? Future<List<NcrOption>>.value(const <NcrOption>[])
            : _safeOptions(() => _fetchDropdownSections(id)),
        id.isEmpty
            ? Future<List<NcrOption>>.value(const <NcrOption>[])
            : _safeOptions(() => _fetchDropdownContracts(id)),
      ],
    );
    return NcrObservationSnapshot(
      projects: results[0],
      sections: results[1],
      contracts: results[2],
    );
  }

  Future<NcrObligationReference> _safeObligation(int obligationId) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        ApiConstants.qualityTestObligationDetailViewPath(obligationId),
      );
      return parseNcrObligationReference(response.data);
    } on Object {
      return NcrObligationReference.empty;
    }
  }

  Future<List<NcrAttachment>> _safeAttachments(
    int ncrId,
    String stage,
  ) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        ApiConstants.ncrObservationAttachmentsPath(ncrId),
        queryParameters: <String, dynamic>{'attachmentStage': stage},
      );
      return parseNcrAttachments(response.data);
    } on Object {
      return const <NcrAttachment>[];
    }
  }

  Future<List<NcrOption>> _safeOptions(
    Future<List<NcrOption>> Function() load,
  ) async {
    try {
      return await load();
    } on Object {
      return const <NcrOption>[];
    }
  }

  Future<List<NcrOption>> _fetchDropdownProjects() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialReceiptDropdownProjectsPath,
    );
    return parseNcrDropdownProjects(response.data);
  }

  Future<List<NcrOption>> _fetchDropdownSections(String projectId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialReceiptDropdownSectionsPath,
      queryParameters: <String, dynamic>{'projectIdFk': projectId},
    );
    return parseNcrDropdownSections(response.data);
  }

  Future<List<NcrOption>> _fetchDropdownContracts(String projectId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialReceiptDropdownContractsPath,
      queryParameters: <String, dynamic>{'projectIdFk': projectId},
    );
    return parseNcrDropdownContracts(response.data);
  }

  int? _headerTotal(Headers headers) {
    for (final String key in <String>[
      'x-total-count',
      'X-Total-Count',
      'total-count',
    ]) {
      final String? raw = headers.value(key);
      if (raw == null || raw.trim().isEmpty) {
        continue;
      }
      final int? value = int.tryParse(raw.trim());
      if (value != null) {
        return value;
      }
    }
    return null;
  }
}
