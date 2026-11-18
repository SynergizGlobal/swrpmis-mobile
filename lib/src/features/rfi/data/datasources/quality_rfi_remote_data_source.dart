import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/quality_rfi_form.dart';

final qualityRfiRemoteDataSourceProvider =
    Provider<QualityRfiRemoteDataSource>((Ref ref) {
  return QualityRfiRemoteDataSource(ref.watch(dioProvider));
});

class QualityRfiLoadException implements Exception {
  const QualityRfiLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class QualityRfiRemoteDataSource {
  QualityRfiRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<QualityRfiOption>> fetchProjects() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialRfiProjectsPath,
      queryParameters: <String, dynamic>{'category': qualityRfiCategory},
    );
    return parseQualityRfiProjects(response.data);
  }

  Future<List<QualityRfiOption>> fetchContracts(String projectId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialRfiContractsPath,
      queryParameters: <String, dynamic>{
        'category': qualityRfiCategory,
        'projectId': projectId,
      },
    );
    return parseQualityRfiContracts(response.data);
  }

  Future<List<QualityRfiOption>> fetchStructureTypes(String contractId) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.structureTypesInActivitiesPath,
      data: <String, dynamic>{'contract_id_fk': contractId},
    );
    return parseQualityRfiStructureTypes(response.data);
  }

  Future<List<QualityRfiOption>> fetchStructures({
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
    return parseQualityRfiStructures(response.data);
  }

  Future<List<QualityRfiOption>> fetchRepresentatives(String contractId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.qualitySafetyRepresentativesPath,
      queryParameters: <String, dynamic>{'contractId': contractId.trim()},
    );
    return parseQualityRfiRepresentatives(response.data);
  }

  Future<List<QualityRfiOption>> fetchDescriptions() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialRfiDescriptionsPath,
      queryParameters: <String, dynamic>{
        'rfiCategory': qualityRfiCategory,
      },
    );
    return parseQualityRfiDescriptions(response.data);
  }

  Future<List<QualityRfiOption>> fetchEnclosures(
    List<String> rfiDescriptionLabels,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialRfiEnclosuresPath,
      queryParameters: <String, dynamic>{
        'rfiCategory': qualityRfiCategory,
        'rfiDescription': rfiDescriptionLabels,
      },
    );
    return parseQualityRfiEnclosures(response.data);
  }

  Future<QualityRfiDetail> fetchDetail(int id) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.qualityRfiPath(id),
    );
    final QualityRfiDetail? detail = parseQualityRfiDetail(response.data);
    if (detail == null) {
      debugPrint(
        'Quality RFI detail parse failed for id=$id '
        'type=${response.data.runtimeType}',
      );
      throw const QualityRfiLoadException(
        'Quality/Safety RFI could not be loaded.',
      );
    }
    return detail;
  }

  Future<void> create(Map<String, dynamic> body) async {
    await _dio.post<dynamic>(ApiConstants.qualityRfiCreatePath, data: body);
  }

  Future<void> update(int id, Map<String, dynamic> body) async {
    await _dio.put<dynamic>(ApiConstants.qualityRfiPath(id), data: body);
  }
}
