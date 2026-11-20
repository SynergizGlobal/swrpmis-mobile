import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/activities_export_option.dart';

final activitiesExportRemoteDataSourceProvider =
    Provider<ActivitiesExportRemoteDataSource>((Ref ref) {
      return ActivitiesExportRemoteDataSource(ref.watch(dioProvider));
    });

class ActivitiesExportRemoteDataSource {
  ActivitiesExportRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ActivitiesExportProject>> fetchProjects({
    String? contractId,
  }) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.activitiesExportProjectsPath,
      queryParameters: <String, dynamic>{
        if (contractId != null && contractId.trim().isNotEmpty)
          'contract_id': contractId.trim(),
        '_t': DateTime.now().millisecondsSinceEpoch,
      },
    );
    return parseActivitiesExportProjects(response.data);
  }

  Future<List<ActivitiesExportContract>> fetchContracts({
    String? projectId,
  }) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.activitiesExportContractsPath,
      queryParameters: <String, dynamic>{
        if (projectId != null && projectId.trim().isNotEmpty)
          'project_id': projectId.trim(),
        '_t': DateTime.now().millisecondsSinceEpoch,
      },
    );
    return parseActivitiesExportContracts(response.data);
  }

  Future<({Uint8List bytes, String fileName})> generate({
    String projectId = '',
    String contractId = '',
  }) async {
    final Response<List<int>> response = await _dio.post<List<int>>(
      ApiConstants.activitiesExportGeneratePath,
      data: <String, dynamic>{
        'project_id': projectId.trim(),
        'contract_id_fk': contractId.trim(),
      },
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 3),
      ),
    );
    final List<int>? data = response.data;
    if (response.statusCode != 200 || data == null || data.isEmpty) {
      throw StateError('Activities export returned an empty file.');
    }
    return (
      bytes: Uint8List.fromList(data),
      fileName: _fileNameFromResponse(
        response,
        fallback: 'activities_export.xlsx',
      ),
    );
  }

  String _fileNameFromResponse(
    Response<List<int>> response, {
    required String fallback,
  }) {
    final Object? raw = response.headers.value('content-disposition');
    if (raw is! String || raw.trim().isEmpty) {
      return fallback;
    }
    final RegExpMatch? utf8Match = RegExp(
      "filename\\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(raw);
    if (utf8Match != null) {
      final String encoded = utf8Match.group(1)?.trim() ?? '';
      if (encoded.isNotEmpty) {
        try {
          final String decoded = Uri.decodeComponent(encoded);
          if (decoded.isNotEmpty) {
            return decoded;
          }
        } on Object {
          // Fall through.
        }
      }
    }
    final RegExpMatch? plainMatch = RegExp(
      r'filename="?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(raw);
    final String? plain = plainMatch?.group(1)?.trim();
    if (plain != null && plain.isNotEmpty) {
      return plain;
    }
    return fallback;
  }
}
