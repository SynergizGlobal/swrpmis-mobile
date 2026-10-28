import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/structure_form/domain/structure_form_detail.dart';
import 'package:swr_pmis_mobile/src/features/structure_form/domain/structure_form_list.dart';
import 'package:swr_pmis_mobile/src/features/structure_form/domain/structure_form_parse.dart';

final structureFormRemoteDataSourceProvider =
    Provider<StructureFormRemoteDataSource>((ref) {
      return StructureFormRemoteDataSource(ref.watch(dioProvider));
    });

class StructureFormRemoteDataSource {
  StructureFormRemoteDataSource(this._dio);

  final Dio _dio;

  Future<StructureFormListSnapshot> fetch(
    StructureFormListQuery query, {
    StructureFormFilterField? changed,
    StructureFormListSnapshot previous = StructureFormListSnapshot.empty,
    bool reloadFilters = true,
  }) async {
    final List<StructureFormListCall> calls = reloadFilters
        ? structureFormListCalls(changed: changed)
        : const <StructureFormListCall>[StructureFormListCall.list];
    List<StructureFormOption> contracts = previous.contracts;
    List<StructureFormOption> structureTypes = previous.structureTypes;
    List<StructureFormOption> workStatuses = previous.workStatuses;
    List<StructureFormRow> rows = previous.rows;
    int total = previous.total;
    final List<Future<void>> jobs = <Future<void>>[];

    if (calls.contains(StructureFormListCall.contracts)) {
      jobs.add(
        _get(
          ApiConstants.structureFormContractsFilterPath,
          query.filterQueryParameters(includeContract: false),
        ).then((dynamic data) {
          contracts = parseStructureFormContracts(data);
        }),
      );
    }
    if (calls.contains(StructureFormListCall.structureTypes)) {
      jobs.add(
        _get(
          ApiConstants.structureFormStructureTypeFilterPath,
          query.filterQueryParameters(includeStructureType: false),
        ).then((dynamic data) {
          structureTypes = parseStructureFormStructureTypes(data);
        }),
      );
    }
    if (calls.contains(StructureFormListCall.workStatuses)) {
      jobs.add(
        _get(
          ApiConstants.structureFormWorkStatusFilterPath,
          query.filterQueryParameters(includeWorkStatus: false),
        ).then((dynamic data) {
          workStatuses = parseStructureFormWorkStatuses(data);
        }),
      );
    }
    if (calls.contains(StructureFormListCall.list)) {
      jobs.add(
        _getList(query).then((
          ({List<StructureFormRow> rows, int total}) result,
        ) {
          rows = result.rows;
          total = result.total;
        }),
      );
    }
    await Future.wait<void>(jobs);
    return StructureFormListSnapshot(
      contracts: contracts,
      structureTypes: structureTypes,
      workStatuses: workStatuses,
      rows: rows,
      total: total,
    );
  }

  Future<StructureFormMaster> fetchStructureForm({
    required String structureId,
  }) async {
    final String id = structureId.trim();
    if (id.isEmpty) {
      return StructureFormMaster.empty;
    }
    final dynamic data = await _get(
      ApiConstants.structureFormGetPath,
      <String, dynamic>{'structure_id': id},
    );
    return parseStructureFormMaster(data);
  }

  Future<List<StructureFormFormOption>> fetchContractsForProject({
    required String projectIdFk,
  }) async {
    final String projectId = projectIdFk.trim();
    if (projectId.isEmpty) {
      return const <StructureFormFormOption>[];
    }
    final dynamic data = await _get(
      ApiConstants.structureFormContractsForProjectPath,
      <String, dynamic>{'project_id_fk': projectId},
    );
    return parseStructureFormContractsForProject(data);
  }

  Future<String> updateStructureForm({
    required Map<String, String> fields,
    required List<String> contractsIdFk,
    required List<String> responsiblePeopleIdFks,
    required List<String> structureDetails,
    required List<String> structureValues,
    required List<String> structureFileTypes,
    required List<String> structureDocumentNames,
    required List<String> structureFileNames,
    required List<({String? path, String fileName})> structureFiles,
  }) async {
    final FormData form = FormData();
    fields.forEach((String key, String value) {
      form.fields.add(MapEntry<String, String>(key, value));
    });

    void addRepeated(String key, List<String> values) {
      if (values.isEmpty) {
        form.fields.add(MapEntry<String, String>(key, ''));
        return;
      }
      for (final String value in values) {
        form.fields.add(MapEntry<String, String>(key, value));
      }
    }

    addRepeated('contracts_id_fk', contractsIdFk);
    // Sample payloads also include contract_id_fk alongside contracts_id_fk.
    addRepeated('contract_id_fk', contractsIdFk);
    addRepeated('responsible_people_id_fks', responsiblePeopleIdFks);
    addRepeated('structure_details', structureDetails);
    addRepeated('structure_values', structureValues);
    addRepeated('structure_file_types', structureFileTypes);
    addRepeated('structureDocumentNames', structureDocumentNames);
    addRepeated('structureFileNames', structureFileNames);

    for (final ({String? path, String fileName}) file in structureFiles) {
      final String? path = file.path?.trim();
      if (path != null && path.isNotEmpty) {
        form.files.add(
          MapEntry<String, MultipartFile>(
            'structureFiles',
            await MultipartFile.fromFile(
              path,
              filename: file.fileName.trim().isEmpty
                  ? p.basename(path)
                  : file.fileName,
            ),
          ),
        );
      } else {
        // Keep existing attachment: empty blob with existing file name.
        form.files.add(
          MapEntry<String, MultipartFile>(
            'structureFiles',
            MultipartFile.fromBytes(
              Uint8List(0),
              filename: file.fileName.trim().isEmpty ? '' : file.fileName,
            ),
          ),
        );
      }
    }

    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.structureFormUpdatePath,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    if (!isStructureFormUpdateSuccess(response.data)) {
      throw StateError(parseStructureFormUpdateMessage(response.data));
    }
    return parseStructureFormUpdateMessage(response.data);
  }

  Future<({List<StructureFormRow> rows, int total})> _getList(
    StructureFormListQuery query,
  ) async {
    final dynamic data = await _get(
      ApiConstants.structureFormListPath,
      query.listQueryParameters(),
    );
    return parseStructureFormList(data);
  }

  Future<dynamic> _get(String path, Map<String, dynamic> queryParameters) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
    );
    return response.data;
  }
}
