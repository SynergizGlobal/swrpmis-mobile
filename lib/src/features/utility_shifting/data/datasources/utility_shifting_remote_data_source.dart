import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/domain/utility_shifting_form.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/domain/utility_shifting_list.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/domain/utility_shifting_parse.dart';

final utilityShiftingRemoteDataSourceProvider =
    Provider<UtilityShiftingRemoteDataSource>((ref) {
      return UtilityShiftingRemoteDataSource(ref.watch(dioProvider));
    });

class UtilityShiftingRemoteDataSource {
  UtilityShiftingRemoteDataSource(this._dio);

  final Dio _dio;

  Future<UtilityShiftingListSnapshot> fetch(
    UtilityShiftingListQuery query, {
    UtilityShiftingFilterField? changed,
    UtilityShiftingListSnapshot previous = UtilityShiftingListSnapshot.empty,
    bool reloadFilters = true,
  }) async {
    final List<UtilityShiftingListCall> calls = reloadFilters
        ? utilityShiftingListCalls(changed: changed)
        : const <UtilityShiftingListCall>[UtilityShiftingListCall.list];
    final Map<String, String> filterBody = query.filterBody();
    List<UtilityShiftingOption> locations = previous.locations;
    List<UtilityShiftingOption> categories = previous.categories;
    List<UtilityShiftingOption> utilityTypes = previous.utilityTypes;
    List<UtilityShiftingOption> statuses = previous.statuses;
    List<UtilityShiftingRow> rows = previous.rows;
    int total = previous.total;
    final List<Future<void>> jobs = <Future<void>>[];

    void addOptions(
      UtilityShiftingListCall call,
      String path,
      List<UtilityShiftingOption> Function(dynamic data) parse,
      void Function(List<UtilityShiftingOption> value) assign,
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
      UtilityShiftingListCall.locations,
      ApiConstants.utilityShiftingLocationFilterPath,
      parseUtilityShiftingLocations,
      (List<UtilityShiftingOption> value) => locations = value,
    );
    addOptions(
      UtilityShiftingListCall.categories,
      ApiConstants.utilityShiftingCategoryFilterPath,
      parseUtilityShiftingCategories,
      (List<UtilityShiftingOption> value) => categories = value,
    );
    addOptions(
      UtilityShiftingListCall.utilityTypes,
      ApiConstants.utilityShiftingTypeFilterPath,
      parseUtilityShiftingTypes,
      (List<UtilityShiftingOption> value) => utilityTypes = value,
    );
    addOptions(
      UtilityShiftingListCall.statuses,
      ApiConstants.utilityShiftingStatusFilterPath,
      parseUtilityShiftingStatuses,
      (List<UtilityShiftingOption> value) => statuses = value,
    );
    if (calls.contains(UtilityShiftingListCall.list)) {
      jobs.add(
        _postList(query).then((
          ({List<UtilityShiftingRow> rows, int total}) result,
        ) {
          rows = result.rows;
          total = result.total;
        }),
      );
    }
    await Future.wait<void>(jobs);
    return UtilityShiftingListSnapshot(
      locations: locations,
      categories: categories,
      utilityTypes: utilityTypes,
      statuses: statuses,
      rows: rows,
      total: total,
    );
  }

  Future<List<UtilityShiftingUploadRow>> fetchUploads() async {
    final dynamic data = await _post(
      ApiConstants.utilityShiftingUploadsListPath,
      const <String, String>{},
    );
    return parseUtilityShiftingUploads(data);
  }

  Future<({Uint8List bytes, String fileName})> downloadTemplate() async {
    final Response<List<int>> response = await _dio.get<List<int>>(
      ApiConstants.utilityShiftingTemplatePath,
      options: Options(responseType: ResponseType.bytes),
    );
    final List<int>? data = response.data;
    if (data == null || data.isEmpty) {
      throw StateError('Empty utility shifting template download.');
    }
    return (
      bytes: Uint8List.fromList(data),
      fileName: _fileNameFromResponse(
        response,
        fallback: 'utility-shifting-template.xlsx',
      ),
    );
  }

  Future<String> uploadUtilityShifting({required String filePath}) async {
    final String name = p.basename(filePath);
    final FormData form = FormData.fromMap(<String, dynamic>{
      'file': await MultipartFile.fromFile(filePath, filename: name),
    });
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.utilityShiftingUploadPath,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return parseUtilityShiftingUploadMessage(response.data);
  }

  Future<UtilityShiftingFormMaster> fetchAddFormMaster() async {
    final dynamic data = await _post(
      ApiConstants.utilityShiftingAddFormPath,
      const <String, String>{},
    );
    return parseUtilityShiftingFormMaster(data);
  }

  Future<List<UtilityShiftingFormOption>> fetchRequirementStagesForForm({
    required String impactedContractId,
  }) async {
    final dynamic data = await _post(
      ApiConstants.utilityShiftingReqStageListPath,
      <String, String>{'impacted_contract_id_fk': impactedContractId.trim()},
    );
    return parseUtilityShiftingRequirementStages(data);
  }

  Future<List<UtilityShiftingFormOption>> fetchImpactedElementsForForm({
    required String impactedContractId,
    required String requirementStage,
  }) async {
    final dynamic data = await _post(
      ApiConstants.utilityShiftingImpactedElementListPath,
      <String, String>{
        'impacted_contract_id_fk': impactedContractId.trim(),
        'requirement_stage_fk': requirementStage.trim(),
      },
    );
    return parseUtilityShiftingImpactedElements(data);
  }

  Future<UtilityShiftingDetail> fetchUtilityShifting({
    required String utilityShiftingId,
  }) async {
    final String id = utilityShiftingId.trim();
    if (id.isEmpty) {
      return UtilityShiftingDetail.empty;
    }
    final dynamic data = await _post(
      ApiConstants.utilityShiftingGetPath,
      <String, String>{'utility_shifting_id': id},
    );
    return parseUtilityShiftingDetail(data);
  }

  Future<String> addUtilityShifting({
    required Map<String, String> fields,
    List<({String path, String fileName})> files =
        const <({String path, String fileName})>[],
    List<String> progressDates = const <String>[],
    List<String> progressOfWorks = const <String>[],
    List<String> attachmentFileTypes = const <String>[],
    List<String> attachmentNames = const <String>[],
    List<String> attachmentFileNames = const <String>[],
  }) {
    return _submitUtilityShiftingMultipart(
      path: ApiConstants.utilityShiftingAddPath,
      fields: fields,
      files: files,
      progressDates: progressDates,
      progressOfWorks: progressOfWorks,
      attachmentFileTypes: attachmentFileTypes,
      attachmentNames: attachmentNames,
      attachmentFileNames: attachmentFileNames,
    );
  }

  Future<String> updateUtilityShifting({
    required Map<String, String> fields,
    List<({String path, String fileName})> files =
        const <({String path, String fileName})>[],
    List<String> progressDates = const <String>[],
    List<String> progressOfWorks = const <String>[],
    List<String> attachmentFileTypes = const <String>[],
    List<String> attachmentNames = const <String>[],
    List<String> attachmentFileNames = const <String>[],
  }) {
    return _submitUtilityShiftingMultipart(
      path: ApiConstants.utilityShiftingUpdatePath,
      fields: fields,
      files: files,
      progressDates: progressDates,
      progressOfWorks: progressOfWorks,
      attachmentFileTypes: attachmentFileTypes,
      attachmentNames: attachmentNames,
      attachmentFileNames: attachmentFileNames,
    );
  }

  Future<String> _submitUtilityShiftingMultipart({
    required String path,
    required Map<String, String> fields,
    List<({String path, String fileName})> files =
        const <({String path, String fileName})>[],
    List<String> progressDates = const <String>[],
    List<String> progressOfWorks = const <String>[],
    List<String> attachmentFileTypes = const <String>[],
    List<String> attachmentNames = const <String>[],
    List<String> attachmentFileNames = const <String>[],
  }) async {
    final FormData form = FormData();
    fields.forEach((String key, String value) {
      form.fields.add(MapEntry<String, String>(key, value));
    });
    void addRepeated(String key, List<String> values) {
      if (values.isEmpty) {
        form.fields.add(MapEntry<String, String>(key, ''));
        return;
      }
      for (final String value in values) {
        form.fields.add(MapEntry<String, String>(key, value));
      }
    }

    addRepeated('progress_dates', progressDates);
    addRepeated('progress_of_works', progressOfWorks);
    addRepeated('attachment_file_types', attachmentFileTypes);
    addRepeated('attachmentNames', attachmentNames);
    addRepeated('attachmentFileNames', attachmentFileNames);

    for (final ({String path, String fileName}) file in files) {
      form.files.add(
        MapEntry<String, MultipartFile>(
          'utilityShiftingFiles',
          await MultipartFile.fromFile(
            file.path,
            filename: file.fileName.trim().isEmpty
                ? p.basename(file.path)
                : file.fileName,
          ),
        ),
      );
    }

    final Response<dynamic> response = await _dio.post<dynamic>(
      path,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    if (!isUtilityShiftingAddSuccess(response.data)) {
      throw StateError(parseUtilityShiftingAddMessage(response.data));
    }
    return parseUtilityShiftingAddMessage(response.data);
  }

  /// Fetches the full filtered set for Excel export (server-side filters).
  Future<List<UtilityShiftingRow>> fetchExportRows(
    UtilityShiftingListQuery query,
  ) async {
    const int pageSize = 1000;
    final List<UtilityShiftingRow> all = <UtilityShiftingRow>[];
    int start = 0;
    int total = 1;
    while (start < total) {
      final UtilityShiftingListQuery pageQuery = query.copyWith(
        page: (start ~/ pageSize) + 1,
        pageSize: pageSize,
      );
      final ({List<UtilityShiftingRow> rows, int total}) page = await _postList(
        pageQuery,
      );
      total = page.total < 1 ? page.rows.length : page.total;
      if (page.rows.isEmpty) {
        break;
      }
      all.addAll(page.rows);
      start += page.rows.length;
      if (page.rows.length < pageSize) {
        break;
      }
    }
    return all;
  }

  Future<({List<UtilityShiftingRow> rows, int total})> _postList(
    UtilityShiftingListQuery query,
  ) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.utilityShiftingListPath,
      queryParameters: query.listQueryParameters(),
      data: query.filterBody(),
    );
    return parseUtilityShiftingList(response.data);
  }

  Future<dynamic> _post(String path, Map<String, String> body) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      path,
      data: body,
    );
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
