import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/material_rfi_form.dart';

final materialRfiRemoteDataSourceProvider =
    Provider<MaterialRfiRemoteDataSource>((ref) {
  return MaterialRfiRemoteDataSource(ref.watch(dioProvider));
});

class MaterialRfiRemoteDataSource {
  MaterialRfiRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<MaterialRfiOption>> fetchProjects() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialRfiProjectsPath,
      queryParameters: <String, dynamic>{'category': 'MATERIAL'},
    );
    return parseMaterialRfiProjects(response.data);
  }

  Future<List<MaterialRfiOption>> fetchContracts(String projectId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialRfiContractsPath,
      queryParameters: <String, dynamic>{
        'category': 'MATERIAL',
        'projectId': projectId,
      },
    );
    return parseMaterialRfiContracts(response.data);
  }

  Future<List<MaterialRfiOption>> fetchInspectionItems() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialRfiInspectionItemsPath,
    );
    return parseMaterialRfiInspectionItems(response.data);
  }

  Future<List<MaterialRfiOption>> fetchInspectionTypes() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialRfiInspectionTypesPath,
    );
    return parseMaterialRfiInspectionTypes(response.data);
  }

  Future<List<MaterialRfiMaterial>> fetchMaterials(int itemId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialRfiMaterialsByItemPath,
      queryParameters: <String, dynamic>{'itemId': itemId},
    );
    return parseMaterialRfiMaterials(response.data);
  }

  Future<List<MaterialRfiOption>> fetchRepresentatives(
    String contractId,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialRfiRepresentativesPath,
      queryParameters: <String, dynamic>{'contractId': contractId},
    );
    return parseMaterialRfiRepresentatives(response.data);
  }

  Future<List<MaterialRfiOption>> fetchDescriptions(int materialId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialRfiDescriptionsPath,
      queryParameters: <String, dynamic>{
        'rfiCategory': 'MATERIAL',
        'materialId': materialId,
      },
    );
    return parseMaterialRfiDescriptions(response.data);
  }

  Future<List<MaterialRfiOption>> fetchEnclosures(
    List<String> rfiDescriptionLabels,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialRfiEnclosuresPath,
      queryParameters: <String, dynamic>{
        'rfiCategory': 'MATERIAL',
        'rfiDescription': rfiDescriptionLabels,
      },
    );
    return parseMaterialRfiEnclosures(response.data);
  }

  Future<MaterialRfiDetail> fetchDetail(int id) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialRfiPath(id),
    );
    final MaterialRfiDetail? detail = parseMaterialRfiDetail(response.data);
    if (detail == null) {
      throw Exception('Material RFI could not be loaded.');
    }
    return detail;
  }

  Future<void> create(Map<String, dynamic> body) async {
    await _dio.post<dynamic>(ApiConstants.materialRfiCreatePath, data: body);
  }
}
