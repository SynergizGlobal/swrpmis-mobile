import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_validation_catalog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_validation_filter.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_validation_report.dart';

final rfiValidationRemoteDataSourceProvider =
    Provider<RfiValidationRemoteDataSource>((ref) {
      return RfiValidationRemoteDataSource(ref.watch(dioProvider));
    });

class RfiValidationRemoteDataSource {
  RfiValidationRemoteDataSource(this._dio);

  final Dio _dio;

  Future<RfiValidationCatalog> fetch(RfiValidationFilter filter) async {
    final Map<String, dynamic> body = filter.toJson();
    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      _projectTypes(),
      _projectList(),
      _validationAccess(),
      _post(ApiConstants.validationFilterCategoryPath, body),
      _post(ApiConstants.validationFilterProjectPath, body),
      _post(ApiConstants.validationFilterContractPath, body),
      _post(ApiConstants.validationListPath, body),
    ]);
    return RfiValidationCatalog.fromResponses(
      projectList: results[1],
      access: results[2],
      categories: results[3],
      projects: results[4],
      contracts: results[5],
      validations: results[6],
    );
  }

  Future<void> validate(Map<String, String> fields) async {
    await _dio.post<dynamic>(
      ApiConstants.validationValidatePath,
      data: FormData.fromMap(fields),
    );
  }

  Future<RfiValidationReport> fetchReportDetail(String longRfiId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.getRfiReportDetailPath(longRfiId),
    );
    final Object? data = response.data;
    if (data is Map) {
      return RfiValidationReport.fromJson(Map<String, dynamic>.from(data));
    }
    throw StateError('No inspection details found.');
  }

  /// Selfies, site images, and enclosure PDFs (absolute server paths).
  Future<Uint8List> previewStoredFile(String filepath) async {
    final Response<List<int>> response = await _dio.get<List<int>>(
      ApiConstants.validationPreviewFilesPath,
      queryParameters: <String, dynamic>{'filepath': filepath},
      options: Options(responseType: ResponseType.bytes),
    );
    final List<int>? data = response.data;
    if (data == null || data.isEmpty) {
      throw StateError('File is empty.');
    }
    return Uint8List.fromList(data);
  }

  /// Attached documents: `dir=attachment` (and support docs when needed).
  Future<Uint8List> previewNamedFile({
    required String fileName,
    String dir = 'attachment',
  }) async {
    final Response<List<int>> response = await _dio.get<List<int>>(
      ApiConstants.rfiLogAttachmentFilePath,
      queryParameters: <String, dynamic>{
        'fileName': fileName,
        'dir': dir,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    final List<int>? data = response.data;
    if (data == null || data.isEmpty) {
      throw StateError('File is empty.');
    }
    return Uint8List.fromList(data);
  }

  Future<dynamic> _projectTypes() async {
    try {
      await _dio.get<dynamic>(ApiConstants.projectTypesPath);
    } on Object {
      return null;
    }
    return null;
  }

  Future<dynamic> _projectList() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        ApiConstants.projectsListPath,
      );
      return response.data;
    } on Object {
      return const <dynamic>[];
    }
  }

  Future<dynamic> _validationAccess() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        ApiConstants.validationAccessPath,
      );
      return response.data;
    } on Object {
      return const <String, dynamic>{'validator': false};
    }
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      path,
      data: body,
    );
    return response.data;
  }
}
