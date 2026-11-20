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

  Future<List<WorkRfiOption>> fetchProjects() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialRfiProjectsPath,
      queryParameters: <String, dynamic>{'category': 'WORK'},
    );
    return parseWorkRfiProjectNames(response.data);
  }

  /// Legacy create bootstrap used by older builds / tests.
  Future<List<WorkRfiOption>> fetchProjectNames() => fetchProjects();

  Future<List<WorkRfiContractOption>> fetchContracts(String projectId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialRfiContractsPath,
      queryParameters: <String, dynamic>{
        'category': 'WORK',
        'projectId': projectId,
      },
    );
    return parseWorkRfiContracts(response.data, projectId: projectId);
  }

  /// Legacy create bootstrap used by older builds / tests.
  Future<List<WorkRfiContractOption>> fetchContractNames(String projectId) {
    return fetchContracts(projectId);
  }

  Future<WorkRfiLayerRange?> fetchLayerRange(String structureType) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rfiLayerRangePath,
      queryParameters: <String, dynamic>{'structure_type': structureType},
    );
    return parseWorkRfiLayerRange(response.data);
  }

  Future<WorkRfiProjectCatalog> fetchProjectCatalog() async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.newActivitiesUpdatePath,
      data: <String, dynamic>{},
    );
    return parseWorkRfiProjectCatalog(response.data);
  }

  Future<List<WorkRfiContractOption>> fetchContractsLegacy(
    String projectId,
  ) async {
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
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.workRfiComponentsListPath,
      queryParameters: <String, dynamic>{
        'contractId': contractId,
        'structureTypeId': structureType,
        'structureId': structureId,
      },
    );
    return parseWorkRfiComponents(response.data);
  }

  /// Elements adapter (option B).
  ///
  /// TODO(work-rfi): replace temporary ComponentIdsList calls with the
  /// confirmed web Elements list URL when the user provides it.
  Future<List<WorkRfiElementOption>> fetchElements({
    required String contractId,
    required String structureId,
    required String structureType,
    required List<WorkRfiOption> components,
  }) async {
    if (components.isEmpty) {
      return const <WorkRfiElementOption>[];
    }
    final List<List<WorkRfiElementOption>> batches = await Future.wait(
      <Future<List<WorkRfiElementOption>>>[
        for (final WorkRfiOption component in components)
          _fetchElementsForComponent(
            contractId: contractId,
            structureId: structureId,
            structureType: structureType,
            component: component,
          ),
      ],
    );
    final List<WorkRfiElementOption> merged = <WorkRfiElementOption>[];
    final Set<String> seen = <String>{};
    for (final List<WorkRfiElementOption> batch in batches) {
      for (final WorkRfiElementOption option in batch) {
        final String key = '${option.componentName}::${option.id}';
        if (option.id.isEmpty || !seen.add(key)) {
          continue;
        }
        merged.add(option);
      }
    }
    return merged;
  }

  Future<List<WorkRfiElementOption>> _fetchElementsForComponent({
    required String contractId,
    required String structureId,
    required String structureType,
    required WorkRfiOption component,
  }) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.activitiesUpdateComponentIdsPath,
      data: <String, dynamic>{
        'contract_id_fk': contractId,
        'strip_chart_structure_id_fk': structureId,
        'strip_chart_component': component.label,
        'structure_type_fk': structureType,
      },
    );
    return parseWorkRfiElements(
      response.data,
      componentName: component.label,
      componentId: component.id,
    );
  }

  Future<List<WorkRfiActivityOption>> fetchActivities({
    required String contractId,
    required String structureId,
    required String structureType,
    required List<WorkRfiComponentElementSelection> selections,
  }) async {
    final int? structureIdNum = int.tryParse(structureId.trim());
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.workRfiActivitiesListsPath,
      data: <String, dynamic>{
        'contractId': contractId,
        'structureId': structureIdNum ?? structureId,
        'structureTypeId': structureType,
        'componentElementSelections': <Map<String, dynamic>>[
          for (final WorkRfiComponentElementSelection row in selections)
            row.toJson(),
        ],
      },
    );
    return parseWorkRfiActivityOptions(response.data);
  }

  Future<List<WorkRfiOption>> fetchDescriptions(
    List<String> activityNames,
  ) async {
    final List<String> names = <String>[
      for (final String name in activityNames)
        if (name.trim().isNotEmpty) name.trim(),
    ];
    if (names.isEmpty) {
      return const <WorkRfiOption>[];
    }
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rfiTypeDescriptionsPath,
      queryParameters: <String, dynamic>{
        'activity': names,
        'rfitype': 'WORK',
      },
    );
    return parseWorkRfiDescriptions(response.data);
  }

  Future<List<WorkRfiOption>> fetchEnclosures(
    List<String> rfiDescriptionLabels,
  ) async {
    final List<String> labels = <String>[
      for (final String label in rfiDescriptionLabels)
        if (label.trim().isNotEmpty) label.trim(),
    ];
    if (labels.isEmpty) {
      return const <WorkRfiOption>[];
    }
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.workRfiEnclosuresPath,
      queryParameters: <String, dynamic>{
        'rfiCategory': 'WORK',
        'rfiDescription': labels,
      },
    );
    return parseWorkRfiEnclosures(response.data);
  }

  Future<List<WorkRfiOption>> fetchRepresentatives(String contractId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.workRepresentativesPath,
      queryParameters: <String, dynamic>{'contractId': contractId.trim()},
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
