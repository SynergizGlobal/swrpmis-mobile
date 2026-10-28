import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/projects/domain/project_form.dart';
import 'package:swr_pmis_mobile/src/features/projects/domain/project_list.dart';
import 'package:swr_pmis_mobile/src/features/projects/domain/project_parse.dart';

final projectRemoteDataSourceProvider = Provider<ProjectRemoteDataSource>((
  ref,
) {
  return ProjectRemoteDataSource(ref.watch(dioProvider));
});

class ProjectRemoteDataSource {
  ProjectRemoteDataSource(this._dio);

  final Dio _dio;

  Future<ProjectListSnapshot> fetchList() async {
    final List<Object?> results = await Future.wait<Object?>(<Future<Object?>>[
      _get(ApiConstants.projectsListPath),
      _safeGet(ApiConstants.projectTypesPath),
    ]);
    return ProjectListSnapshot(
      rows: parseProjectRows(results[0]),
      projectTypes: results[1] == null
          ? const <ProjectOption>[]
          : parseProjectTypes(results[1]),
    );
  }

  Future<ProjectFormMaster> fetchFormMaster() async {
    final List<Object?> results = await Future.wait<Object?>(<Future<Object?>>[
      _get(ApiConstants.projectTypesPath),
      _get(ApiConstants.projectRailwayZonesPath),
      _get(ApiConstants.projectYearListPath),
      _safeGet(ApiConstants.projectDivisionsPath),
      _safeGet(ApiConstants.projectSectionsPath),
    ]);
    return ProjectFormMaster(
      projectTypes: parseProjectTypes(results[0]),
      railwayZones: parseRailwayZones(results[1]),
      years: parseYearList(results[2]),
      divisions: results[3] == null
          ? const <ProjectOption>[]
          : parseDivisions(results[3]),
      sections: results[4] == null
          ? const <ProjectOption>[]
          : parseSections(results[4]),
    );
  }

  Future<List<ProjectOption>> fetchDivisionsForZone(String railwayZone) async {
    final String zone = railwayZone.trim();
    if (zone.isEmpty) {
      return const <ProjectOption>[];
    }
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.projectGetDivisionsPath,
      data: <String, dynamic>{'railwayZone': zone},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        validateStatus: (int? status) => status != null && status < 500,
      ),
    );
    _ensureOk(response);
    return parseDivisions(response.data);
  }

  Future<bool> checkProjectName(String projectName) async {
    final String name = projectName.trim();
    if (name.isEmpty) {
      return false;
    }
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.projectCheckNamePath,
      queryParameters: <String, dynamic>{'project_name': name},
    );
    return parseProjectNameExists(response.data);
  }

  Future<String> addProject(Map<String, dynamic> body) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.projectAddPath,
      data: body,
      options: Options(contentType: Headers.jsonContentType),
    );
    return parseProjectMutationMessage(
      response.data,
      fallback: 'Project added successfully',
    );
  }

  Future<String> updateProject({
    required String projectId,
    required Map<String, dynamic> body,
  }) async {
    final String id = projectId.trim();
    if (id.isEmpty) {
      throw StateError('Missing project id.');
    }
    final Response<dynamic> response = await _dio.put<dynamic>(
      '${ApiConstants.projectUpdatePath}/$id',
      data: body,
      options: Options(contentType: Headers.jsonContentType),
    );
    return parseProjectMutationMessage(
      response.data,
      fallback: 'Project updated successfully',
    );
  }

  Future<String> deleteProject(String projectId) async {
    final String id = projectId.trim();
    if (id.isEmpty) {
      throw StateError('Missing project id.');
    }
    final Response<dynamic> response = await _dio.delete<dynamic>(
      '${ApiConstants.projectDeletePath}/$id',
    );
    return parseProjectMutationMessage(
      response.data,
      fallback: 'Project deleted successfully',
    );
  }

  Future<String> uploadChainages({
    required String projectId,
    required String filePath,
  }) async {
    final String id = projectId.trim();
    if (id.isEmpty) {
      throw StateError('Missing project id for KMZ upload.');
    }
    final String name = p.basename(filePath);
    final FormData form = FormData.fromMap(<String, dynamic>{
      'project_id_fk': id,
      'ProjectChainagesFile': await MultipartFile.fromFile(
        filePath,
        filename: name,
      ),
    });
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.projectUploadChainagesPath,
      data: form,
    );
    return parseProjectMutationMessage(
      response.data,
      fallback: 'Chainages uploaded successfully',
    );
  }

  Future<dynamic> _get(String path) async {
    final Response<dynamic> response = await _dio.get<dynamic>(path);
    return response.data;
  }

  Future<dynamic> _safeGet(String path) async {
    try {
      return await _get(path);
    } on Object {
      return null;
    }
  }

  void _ensureOk(Response<dynamic> response) {
    final int? status = response.statusCode;
    if (status != null && status >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Request failed ($status)',
      );
    }
  }
}
