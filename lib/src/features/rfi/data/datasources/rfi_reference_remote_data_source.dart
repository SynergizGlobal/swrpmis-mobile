import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_reference.dart';

final rfiReferenceRemoteDataSourceProvider =
    Provider<RfiReferenceRemoteDataSource>((ref) {
      return RfiReferenceRemoteDataSource(ref.watch(dioProvider));
    });

class RfiReferenceRemoteDataSource {
  RfiReferenceRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> warmProjectLookups() async {
    await Future.wait<void>(<Future<void>>[
      _getIgnored(ApiConstants.projectTypesPath),
      _getIgnored(ApiConstants.projectsListPath),
    ]);
  }

  Future<List<RfiEnclosureNameOption>> fetchEnclosureNames(
    String rfiCategory,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rfiEnclosureNamesPath,
      queryParameters: <String, String>{'rfiCategory': rfiCategory},
    );
    return parseRfiEnclosureNames(response.data);
  }

  Future<List<RfiEnclosure>> fetchEnclosureList() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rfiEnclosureListPath,
    );
    return parseRfiEnclosures(response.data);
  }

  Future<List<RfiEnclosure>> fetchEnclosuresByAction() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rfiEnclosureByActionPath,
    );
    return parseRfiEnclosures(response.data);
  }

  Future<List<RfiChecklistDescription>> fetchChecklist(int id) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rfiEnclosureChecklistPath(id),
    );
    return parseRfiChecklistDescriptions(response.data);
  }

  Future<List<RfiReferenceDescription>> fetchDescriptions() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rfiDescriptionsPath,
    );
    return parseRfiDescriptions(response.data);
  }

  Future<void> submitEnclosure({
    required String encloserName,
    required String action,
    required String rfiCategory,
  }) async {
    await _dio.post<dynamic>(
      ApiConstants.rfiEnclosureSubmitPath,
      data: <String, String>{
        'encloserName': encloserName,
        'action': action,
        'rfiCategory': rfiCategory,
      },
    );
  }

  Future<void> updateEnclosure({
    required int id,
    required String encloserName,
    required String action,
    required String rfiCategory,
  }) async {
    await _dio.put<dynamic>(
      ApiConstants.rfiEnclosureUpdatePath(id),
      data: <String, String>{
        'encloserName': encloserName,
        'action': action,
        'rfiCategory': rfiCategory,
      },
    );
  }

  Future<void> deleteEnclosure(int id) async {
    await _dio.delete<dynamic>(ApiConstants.rfiEnclosureDeletePath(id));
  }

  Future<RfiChecklistSaveResult> addChecklistDescriptions({
    required int enclosureId,
    required List<String> checklistDescriptions,
  }) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.rfiChecklistDescriptionsPath(enclosureId),
      data: <String, dynamic>{'checklistDescriptions': checklistDescriptions},
    );
    return parseRfiChecklistSave(response.data);
  }

  Future<void> updateChecklistDescription({
    required int id,
    required String description,
  }) async {
    await _dio.put<dynamic>(
      ApiConstants.rfiChecklistUpdatePath(id),
      data: <String, String>{'checkListDescription': description},
    );
  }

  Future<void> deleteChecklistDescription(int id) async {
    await _dio.delete<dynamic>(ApiConstants.rfiChecklistDeletePath(id));
  }

  Future<void> submitDescription({
    required String rfiCategory,
    required String activity,
    required String rfiDescription,
    required String enclosures,
  }) async {
    await _dio.post<dynamic>(
      ApiConstants.rfiDescriptionSavePath,
      data: rfiReferenceDescriptionPayload(
        rfiCategory: rfiCategory,
        activity: activity,
        rfiDescription: rfiDescription,
        enclosures: enclosures,
      ),
    );
  }

  Future<void> updateDescription({
    required int id,
    required String rfiCategory,
    required String activity,
    required String rfiDescription,
    required String enclosures,
  }) async {
    await _dio.put<dynamic>(
      ApiConstants.rfiDescriptionUpdatePath(id),
      data: rfiReferenceDescriptionPayload(
        rfiCategory: rfiCategory,
        activity: activity,
        rfiDescription: rfiDescription,
        enclosures: enclosures,
      ),
    );
  }

  Future<RfiDescriptionDeleteResult> deleteDescription(int id) async {
    final Response<dynamic> response = await _dio.delete<dynamic>(
      ApiConstants.rfiDescriptionDeletePath(id),
    );
    return parseRfiDescriptionDelete(response.data);
  }

  Future<void> _getIgnored(String path) async {
    try {
      await _dio.get<dynamic>(path);
    } on Object {
      return;
    }
  }
}
