import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_validation_catalog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_validation_filter.dart';

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
      _post(ApiConstants.validationFilterCategoryPath, body),
      _post(ApiConstants.validationFilterProjectPath, body),
      _post(ApiConstants.validationFilterContractPath, body),
      _post(ApiConstants.validationListPath, body),
    ]);
    return RfiValidationCatalog.fromResponses(
      projectList: results[1],
      categories: results[2],
      projects: results[3],
      contracts: results[4],
      validations: results[5],
    );
  }

  Future<void> validate(Map<String, String> fields) async {
    await _dio.post<dynamic>(
      ApiConstants.validationValidatePath,
      data: FormData.fromMap(fields),
    );
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

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      path,
      data: body,
    );
    return response.data;
  }
}
