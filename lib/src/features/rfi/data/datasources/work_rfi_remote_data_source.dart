import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/work_rfi_form.dart';

final workRfiRemoteDataSourceProvider = Provider<WorkRfiRemoteDataSource>((
  ref,
) {
  return WorkRfiRemoteDataSource(ref.watch(dioProvider));
});

class WorkRfiLoadException implements Exception {
  const WorkRfiLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WorkRfiRemoteDataSource {
  WorkRfiRemoteDataSource(this._dio);

  final Dio _dio;

  Future<WorkRfiProjectCatalog> fetchProjectCatalog() async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.newActivitiesUpdatePath,
      data: <String, dynamic>{},
    );
    return parseWorkRfiProjectCatalog(response.data);
  }

  Future<List<WorkRfiContractOption>> fetchContracts(String projectId) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.contractListForProjectPath,
      data: <String, dynamic>{'project_id_fk': projectId},
    );
    return parseWorkRfiContracts(response.data, projectId: projectId);
  }

  Future<List<WorkRfiOption>> fetchStructureTypes(String contractId) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.structureTypesInActivitiesPath,
      data: <String, dynamic>{'contract_id_fk': contractId},
    );
    return parseWorkRfiStructureTypes(response.data);
  }

  Future<List<WorkRfiOption>> fetchStructures({
    required String contractId,
    required String structureType,
  }) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.activitiesUpdateStructuresPath,
      data: <String, dynamic>{
        'contract_id_fk': contractId,
        'structure_type_fk': structureType,
      },
    );
    return parseWorkRfiStructures(response.data);
  }

  Future<List<WorkRfiOption>> fetchComponents({
    required String contractId,
    required String structureId,
    required String structureType,
  }) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.activitiesUpdateComponentsPath,
      data: <String, dynamic>{
        'contract_id_fk': contractId,
        'strip_chart_structure_id_fk': structureId,
        'structure_type_fk': structureType,
      },
    );
    return parseWorkRfiComponents(response.data);
  }

  Future<List<WorkRfiOption>> fetchElements({
    required String contractId,
    required String structureId,
    required String component,
    required String structureType,
  }) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.activitiesUpdateComponentIdsPath,
      data: <String, dynamic>{
        'contract_id_fk': contractId,
        'strip_chart_structure_id_fk': structureId,
        'strip_chart_component': component,
        'structure_type_fk': structureType,
      },
    );
    return parseWorkRfiElements(response.data);
  }

  Future<List<WorkRfiOption>> fetchActivities({
    required String contractId,
    required String structureId,
    required String structureType,
    required String component,
    required String element,
  }) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.activitiesUpdateActivitiesPath,
      data: <String, dynamic>{
        'contract_id_fk': contractId,
        'strip_chart_structure_id_fk': structureId,
        'structure_type_fk': structureType,
        'strip_chart_component': component,
        'strip_chart_component_id': element,
      },
    );
    return parseWorkRfiActivities(response.data);
  }

  Future<List<WorkRfiOption>> fetchDescriptions(String activityName) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rfiTypeDescriptionsPath,
      queryParameters: <String, dynamic>{
        'activity': activityName,
        'rfitype': 'WORK',
      },
    );
    return parseWorkRfiDescriptions(response.data);
  }

  Future<List<WorkRfiOption>> fetchEnclosures(String description) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.workRfiEnclosuresPath,
      queryParameters: <String, dynamic>{
        'rfiCategory': 'WORK',
        'rfiDescription': description,
      },
    );
    return parseWorkRfiEnclosures(response.data);
  }

  Future<List<WorkRfiOption>> fetchRepresentatives() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.workRepresentativesPath,
    );
    return parseWorkRfiRepresentatives(response.data);
  }

  Future<WorkRfiDetail> fetchDetail(int id) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.workRfiPath(id),
    );
    final WorkRfiDetail? detail = parseWorkRfiDetail(response.data);
    if (detail == null) {
      throw const WorkRfiLoadException('Work RFI could not be loaded.');
    }
    return detail;
  }

  Future<void> create(Map<String, dynamic> body) async {
    await _dio.post<dynamic>(ApiConstants.workRfiCreatePath, data: body);
  }

  Future<void> update(int id, Map<String, dynamic> body) async {
    await _dio.put<dynamic>(ApiConstants.workRfiPath(id), data: body);
  }
}
