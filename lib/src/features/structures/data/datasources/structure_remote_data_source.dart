import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/structures/domain/structure_form.dart';
import 'package:swr_pmis_mobile/src/features/structures/domain/structure_list.dart';
import 'package:swr_pmis_mobile/src/features/structures/domain/structure_parse.dart';

final structureRemoteDataSourceProvider = Provider<StructureRemoteDataSource>((
  ref,
) {
  return StructureRemoteDataSource(ref.watch(dioProvider));
});

class StructureRemoteDataSource {
  StructureRemoteDataSource(this._dio);

  final Dio _dio;

  Future<StructureListSnapshot> fetchSummaries() async {
    final List<Object?> results = await Future.wait<Object?>(<Future<Object?>>[
      _get(ApiConstants.structuresAllProjectSummariesPath),
      _safeGet(ApiConstants.projectsGetProjectsPath),
    ]);
    final List<StructureSummaryRow> rows = parseStructureSummaries(results[0]);
    List<StructureProjectOption> projects = results[1] == null
        ? const <StructureProjectOption>[]
        : parseStructureProjects(results[1]);
    if (projects.isEmpty) {
      projects = <StructureProjectOption>[
        for (final StructureSummaryRow row in rows)
          StructureProjectOption(
            projectId: row.projectId,
            projectName: '',
          ),
      ];
    }
    return StructureListSnapshot(
      rows: rows,
      projects: <StructureOption>[
        for (final StructureProjectOption project in projects)
          StructureOption(
            value: project.projectId,
            label: project.projectName.trim().isEmpty
                ? project.projectId
                : project.displayLabel,
          ),
      ],
    );
  }

  Future<StructureFormMaster> fetchFormMaster() async {
    final List<Object?> results = await Future.wait<Object?>(<Future<Object?>>[
      _get(ApiConstants.projectsGetProjectsPath),
      _get(ApiConstants.structuresTypesPath),
    ]);
    return StructureFormMaster(
      projects: parseStructureProjects(results[0]),
      structureTypes: parseStructureTypeNames(results[1]),
    );
  }

  Future<StructureProjectChainage> fetchProjectChainage(String projectId) async {
    final String id = projectId.trim();
    if (id.isEmpty) {
      return StructureProjectChainage.empty;
    }
    try {
      final dynamic data = await _get(
        ApiConstants.structuresProjectChainagePath(id),
      );
      return parseStructureProjectChainage(data);
    } on Object {
      // Chainage is advisory only; keep form usable when boundaries missing.
      return StructureProjectChainage.empty;
    }
  }

  Future<StructureFullDetail> fetchFull(String projectId) async {
    final String id = projectId.trim();
    if (id.isEmpty) {
      throw StateError('Missing project id.');
    }
    final dynamic data = await _get(ApiConstants.structuresFullPath(id));
    return parseStructureFullDetail(data);
  }

  Future<String> saveOrUpdate(Map<String, dynamic> body) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        ApiConstants.structuresSaveOrUpdatePath,
        data: body,
        options: Options(contentType: Headers.jsonContentType),
      );
      return parseStructureSaveMessage(
        response.data,
        fallback: 'Structure saved successfully',
      );
    } on DioException catch (error) {
      final String? message = structureApiMessage(error.response?.data);
      if (message != null && message.isNotEmpty) {
        throw StateError(message);
      }
      rethrow;
    }
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
}
