import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/land_acquisition_report.dart';

final landAcquisitionReportRemoteDataSourceProvider =
    Provider<LandAcquisitionReportRemoteDataSource>((Ref ref) {
      return LandAcquisitionReportRemoteDataSource(ref.watch(dioProvider));
    });

class LandAcquisitionReportRemoteDataSource {
  LandAcquisitionReportRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ContractDetailOption>> fetchProjects({
    String categoryFk = '',
  }) async {
    final Map<String, dynamic> query = buildLandAcquisitionProjectListQuery(
      categoryFk: categoryFk,
    );
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.landReportProjectListPath,
      queryParameters: query.isEmpty ? null : query,
    );
    return parseLandAcquisitionProjects(response.data);
  }

  Future<List<ContractDetailOption>> fetchTypes({
    String projectId = '',
  }) async {
    final Map<String, dynamic> query = buildLandAcquisitionTypeListQuery(
      projectId: projectId,
    );
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.landReportTypeListPath,
      queryParameters: query.isEmpty ? null : query,
    );
    return parseLandAcquisitionTypes(response.data);
  }

  Future<List<ContractDetailOption>> fetchSubCategories({
    String projectId = '',
    String categoryFk = '',
  }) async {
    final Map<String, dynamic> query =
        buildLandAcquisitionSubCategoryListQuery(
          projectId: projectId,
          categoryFk: categoryFk,
        );
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.landReportSubCategoryListPath,
      queryParameters: query.isEmpty ? null : query,
    );
    return parseLandAcquisitionSubCategories(response.data);
  }

  Future<({Uint8List bytes, String fileName})> generate({
    required String projectId,
    required String categoryFk,
    required String subCategoryFk,
  }) async {
    final Map<String, dynamic> body = buildLandAcquisitionGenerateBody(
      projectId: projectId,
      categoryFk: categoryFk,
      subCategoryFk: subCategoryFk,
    );
    final Response<List<int>> response = await _dio.post<List<int>>(
      ApiConstants.landReportGeneratePath,
      data: body,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 3),
      ),
    );
    final List<int>? data = response.data;
    if (response.statusCode != 200 || data == null || data.isEmpty) {
      throw StateError('Land Acquisition Report returned an empty file.');
    }
    return (
      bytes: Uint8List.fromList(data),
      fileName: _fileNameFromResponse(
        response,
        fallback: 'Land_Acquisition_Report.pdf',
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
