import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/p6_updates/domain/p6_list.dart';
import 'package:swr_pmis_mobile/src/features/p6_updates/domain/p6_parse.dart';

final p6RemoteDataSourceProvider = Provider<P6RemoteDataSource>((ref) {
  return P6RemoteDataSource(ref.watch(dioProvider));
});

class P6RemoteDataSource {
  P6RemoteDataSource(this._dio);

  final Dio _dio;

  Future<P6FormMaster> fetchFormMaster() async {
    final dynamic data = await _post(
      ApiConstants.p6NewDataMasterPath,
      const <String, dynamic>{},
    );
    return parseP6FormMaster(data);
  }

  Future<List<P6Option>> fetchContractsForProject(String projectId) async {
    final String id = projectId.trim();
    if (id.isEmpty) {
      return const <P6Option>[];
    }
    final dynamic data = await _postForm(
      ApiConstants.p6ContractsForProjectPath,
      <String, String>{'project_id_fk': id},
    );
    return parseP6Contracts(data);
  }

  Future<P6HistorySnapshot> fetchHistory(
    P6HistoryQuery query, {
    P6HistoryFilterField? changed,
    P6HistorySnapshot previous = P6HistorySnapshot.empty,
  }) async {
    final List<P6HistoryListCall> calls = p6HistoryListCalls(changed: changed);
    final Map<String, String> body = query.toJson();
    List<P6Option> contracts = previous.contracts;
    List<P6Option> uploadTypes = previous.uploadTypes;
    List<P6Option> statuses = previous.statuses;
    List<P6HistoryRow> rows = previous.rows;
    final List<Future<void>> jobs = <Future<void>>[];

    void addOptions(
      P6HistoryListCall call,
      String path,
      List<P6Option> Function(dynamic data) parse,
      void Function(List<P6Option> value) assign,
    ) {
      if (!calls.contains(call)) {
        return;
      }
      jobs.add(
        _post(path, body).then((dynamic data) {
          assign(parse(data));
        }),
      );
    }

    addOptions(
      P6HistoryListCall.contracts,
      ApiConstants.p6HistoryContractsFilterPath,
      parseP6HistoryContracts,
      (List<P6Option> value) => contracts = value,
    );
    addOptions(
      P6HistoryListCall.uploadTypes,
      ApiConstants.p6HistoryUploadTypesFilterPath,
      parseP6UploadTypes,
      (List<P6Option> value) => uploadTypes = value,
    );
    addOptions(
      P6HistoryListCall.statuses,
      ApiConstants.p6HistoryStatusFilterPath,
      parseP6Statuses,
      (List<P6Option> value) => statuses = value,
    );
    if (calls.contains(P6HistoryListCall.rows)) {
      jobs.add(
        _post(ApiConstants.p6HistoryListPath, body).then((dynamic data) {
          rows = parseP6HistoryRows(data);
        }),
      );
    }
    await Future.wait<void>(jobs);
    return P6HistorySnapshot(
      contracts: contracts,
      uploadTypes: uploadTypes,
      statuses: statuses,
      rows: rows,
    );
  }

  /// Uploads a P6 export file.
  ///
  /// Documented Baseline fields: project_id_fk, contract_id_fk, data_date
  /// (YYYY-MM-DD), p6dataFile. Distinct Revised Baseline / Update endpoints
  /// were not found on QA; those panels reuse this path and also send
  /// `upload_type` so the backend can discriminate if supported.
  Future<String> uploadP6NewData({
    required String projectId,
    required String contractId,
    required String dataDateIso,
    required String filePath,
    required String uploadType,
  }) async {
    final String name = p.basename(filePath);
    final FormData form = FormData.fromMap(<String, dynamic>{
      'project_id_fk': projectId.trim(),
      'contract_id_fk': contractId.trim(),
      'data_date': dataDateIso.trim(),
      'upload_type': uploadType.trim(),
      'p6dataFile': await MultipartFile.fromFile(filePath, filename: name),
    });
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.p6UploadNewDataPath,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return parseP6UploadMessage(response.data);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      path,
      data: body,
    );
    return response.data;
  }

  Future<dynamic> _postForm(String path, Map<String, String> fields) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      path,
      data: fields,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    return response.data;
  }
}

