import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/design/domain/design_form.dart';
import 'package:swr_pmis_mobile/src/features/design/domain/design_list.dart';
import 'package:swr_pmis_mobile/src/features/design/domain/design_parse.dart';

final designRemoteDataSourceProvider = Provider<DesignRemoteDataSource>((ref) {
  return DesignRemoteDataSource(ref.watch(dioProvider));
});

class DesignRemoteDataSource {
  DesignRemoteDataSource(this._dio);

  final Dio _dio;

  Future<DesignListSnapshot> fetch(
    DesignListQuery query, {
    DesignFilterField? changed,
    DesignListSnapshot previous = DesignListSnapshot.empty,
    bool reloadFilters = true,
  }) async {
    final List<DesignListCall> calls = reloadFilters
        ? designListCalls(changed: changed)
        : const <DesignListCall>[DesignListCall.designs];
    final Map<String, String> filterBody = query.filterBody();
    List<DesignOption> contracts = previous.contracts;
    List<DesignOption> structureTypes = previous.structureTypes;
    List<DesignOption> drawingTypes = previous.drawingTypes;
    List<DesignRow> rows = previous.rows;
    int total = previous.total;
    final List<Future<void>> jobs = <Future<void>>[];

    void addOptions(
      DesignListCall call,
      String path,
      List<DesignOption> Function(dynamic data) parse,
      void Function(List<DesignOption> value) assign,
    ) {
      if (!calls.contains(call)) {
        return;
      }
      jobs.add(
        _post(path, filterBody).then((dynamic data) {
          assign(parse(data));
        }),
      );
    }

    addOptions(
      DesignListCall.contracts,
      ApiConstants.designContractFilterPath,
      parseDesignContracts,
      (List<DesignOption> value) => contracts = value,
    );
    addOptions(
      DesignListCall.structureTypes,
      ApiConstants.designStructureFilterPath,
      parseDesignStructureTypes,
      (List<DesignOption> value) => structureTypes = value,
    );
    addOptions(
      DesignListCall.drawingTypes,
      ApiConstants.designDrawingTypeFilterPath,
      parseDesignDrawingTypes,
      (List<DesignOption> value) => drawingTypes = value,
    );
    if (calls.contains(DesignListCall.designs)) {
      jobs.add(
        _postDesigns(query).then((({List<DesignRow> rows, int total}) result) {
          rows = result.rows;
          total = result.total;
        }),
      );
    }
    await Future.wait<void>(jobs);
    return DesignListSnapshot(
      contracts: contracts,
      structureTypes: structureTypes,
      drawingTypes: drawingTypes,
      rows: rows,
      total: total,
    );
  }

  Future<List<DesignUploadRow>> fetchUploads() async {
    final dynamic data = await _post(
      ApiConstants.designUploadsListPath,
      const <String, String>{},
    );
    return parseDesignUploads(data);
  }

  /// Loads dropdown catalogs for Add/Edit Design form (read-only; no save).
  Future<DesignFormMaster> fetchFormMaster() async {
    final Map<String, String> emptyFilters = const DesignListQuery()
        .filterBody();
    final List<Object?> results = await Future.wait<Object?>(
      <Future<Object?>>[
        _get(ApiConstants.projectsListPath),
        _post(ApiConstants.designContractFilterPath, emptyFilters),
        _post(ApiConstants.designStructureFilterPath, emptyFilters),
        _post(ApiConstants.designDrawingTypeFilterPath, emptyFilters),
      ],
    );
    return DesignFormMaster(
      projects: parseDesignFormProjects(results[0]),
      contracts: designFormOptionsFromDesign(parseDesignContracts(results[1])),
      structureTypes: designFormOptionsFromDesign(
        parseDesignStructureTypes(results[2]),
      ),
      drawingTypes: designFormOptionsFromDesign(
        parseDesignDrawingTypes(results[3]),
      ),
    );
  }

  Future<({Uint8List bytes, String fileName})> downloadDesignTemplate() async {
    final Response<List<int>> response = await _dio.get<List<int>>(
      ApiConstants.designDownloadTemplatePath,
      options: Options(responseType: ResponseType.bytes),
    );
    final List<int>? data = response.data;
    if (data == null || data.isEmpty) {
      throw StateError('Empty design template download.');
    }
    return (
      bytes: Uint8List.fromList(data),
      fileName: _fileNameFromResponse(
        response,
        fallback: 'design-template.xlsx',
      ),
    );
  }

  /// Multipart field name matches utility-shifting / RFI file uploads: `file`.
  Future<String> uploadDesigns({required String filePath}) async {
    final String name = p.basename(filePath);
    final FormData form = FormData.fromMap(<String, dynamic>{
      'file': await MultipartFile.fromFile(filePath, filename: name),
    });
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.designUploadDesignsPath,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return parseDesignUploadMessage(response.data);
  }

  Future<Uint8List> downloadUploadFile({
    required String fileName,
    String? designDataId,
  }) async {
    final String trimmedName = fileName.trim();
    final String trimmedId = designDataId?.trim() ?? '';
    final List<String> paths = <String>[
      if (trimmedId.isNotEmpty)
        '${ApiConstants.designUploadDownloadPath}'
            '?design_data_id=${Uri.encodeComponent(trimmedId)}',
      if (trimmedName.isNotEmpty)
        '/DESIGN_DATA_FILES/${Uri.encodeComponent(trimmedName)}',
      if (trimmedName.isNotEmpty)
        '/DESIGN_UPLOAD_FILES/${Uri.encodeComponent(trimmedName)}',
    ];
    Object? lastError;
    for (final String path in paths) {
      try {
        final Response<List<int>> response = await _dio.get<List<int>>(
          path,
          options: Options(responseType: ResponseType.bytes),
        );
        final List<int>? bytes = response.data;
        if (bytes != null && bytes.isNotEmpty) {
          return Uint8List.fromList(bytes);
        }
      } on Object catch (error) {
        lastError = error;
      }
    }
    if (trimmedId.isNotEmpty) {
      try {
        final Response<List<int>> response = await _dio.post<List<int>>(
          ApiConstants.designUploadDownloadPath,
          data: <String, dynamic>{'design_data_id': trimmedId},
          options: Options(responseType: ResponseType.bytes),
        );
        final List<int>? bytes = response.data;
        if (bytes != null && bytes.isNotEmpty) {
          return Uint8List.fromList(bytes);
        }
      } on Object catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? StateError('Unable to download design upload file.');
  }

  Future<({List<DesignRow> rows, int total})> _postDesigns(
    DesignListQuery query,
  ) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.designListPath,
      queryParameters: query.listQueryParameters(),
      data: const <String, dynamic>{},
    );
    return parseDesignsList(response.data);
  }

  Future<dynamic> _post(String path, Map<String, String> body) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      path,
      data: body,
    );
    return response.data;
  }

  Future<dynamic> _get(String path) async {
    final Response<dynamic> response = await _dio.get<dynamic>(path);
    return response.data;
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
          // Fall through to plain filename / default.
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
