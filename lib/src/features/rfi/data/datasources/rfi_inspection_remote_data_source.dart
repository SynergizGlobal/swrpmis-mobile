import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_catalog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_filter.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_row.dart';

final rfiInspectionRemoteDataSourceProvider =
    Provider<RfiInspectionRemoteDataSource>((ref) {
      return RfiInspectionRemoteDataSource(ref.watch(dioProvider));
    });

class RfiInspectionRemoteDataSource {
  RfiInspectionRemoteDataSource(this._dio);

  final Dio _dio;

  Future<RfiInspectionCatalog> fetch(RfiInspectionFilter filter) async {
    final Map<String, dynamic> body = filter.toJson();
    final List<dynamic> responses =
        await Future.wait<dynamic>(<Future<dynamic>>[
          _post(ApiConstants.rfiFilterCategoryPath, body),
          _post(ApiConstants.rfiFilterProjectPath, body),
          _post(ApiConstants.rfiFilterContractPath, body),
          _post(ApiConstants.rfiFilterStructureTypePath, body),
          _post(ApiConstants.rfiFilterStructurePath, body),
          _post(ApiConstants.rfiFilterItemPath, body),
          _post(ApiConstants.rfiFilterMaterialPath, body),
          _post(ApiConstants.rfiFilterQualitySafetyPath, body),
          _post(ApiConstants.rfiDetailsPath, body),
        ]);
    return RfiInspectionCatalog(
      categories: _textOptions(responses[0], const <String>[
        'rfiCategory',
        'category',
        'name',
        'label',
      ]),
      projects: _namedOptions(
        responses[1],
        idKeys: const <String>['projectId', 'id'],
        labelKeys: const <String>['projectName', 'name', 'label'],
        numeric: false,
      ),
      contracts: _namedOptions(
        responses[2],
        idKeys: const <String>['contractId', 'id'],
        labelKeys: const <String>['contractName', 'name', 'label'],
        numeric: false,
      ),
      structureTypes: _textOptions(responses[3], const <String>[
        'structureType',
        'name',
        'label',
      ]),
      structures: _namedOptions(
        responses[4],
        idKeys: const <String>['structureId', 'id'],
        labelKeys: const <String>[
          'structure',
          'structureName',
          'name',
          'label',
        ],
        numeric: true,
      ),
      items: _namedOptions(
        responses[5],
        idKeys: const <String>['itemId', 'id'],
        labelKeys: const <String>['item', 'itemName', 'name', 'label'],
        numeric: true,
      ),
      materials: _namedOptions(
        responses[6],
        idKeys: const <String>['materialId', 'id'],
        labelKeys: const <String>['material', 'materialName', 'name', 'label'],
        numeric: true,
      ),
      qualitySafety: _namedOptions(
        responses[7],
        idKeys: const <String>['qualityOrSafetyId', 'qualitySafetyId', 'id'],
        labelKeys: const <String>[
          'qualityOrSafety',
          'qualitySafety',
          'name',
          'label',
        ],
        numeric: true,
      ),
      rows: _rows(responses[8]),
    );
  }

  Future<List<RfiInspectionRow>> fetchDetails(
    RfiInspectionFilter filter,
  ) async {
    final dynamic data = await _post(
      ApiConstants.rfiDetailsPath,
      filter.toJson(),
    );
    return _rows(data);
  }

  Future<RfiBulkSubmitResult> bulkSubmit() async {
    final dynamic data = await _post(
      ApiConstants.rfiBulkSubmitNoRfiRequiredPath,
      const <String, dynamic>{},
    );
    if (data is Map) {
      return RfiBulkSubmitResult.fromJson(Map<String, dynamic>.from(data));
    }
    return const RfiBulkSubmitResult(
      task: '',
      totalFound: 0,
      successCount: 0,
      skippedNoMeasurement: 0,
      failed: 0,
      submittedRfiNumbers: <String>[],
      failedRfiNumbers: <String>[],
    );
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      path,
      data: body,
    );
    return response.data;
  }

  List<RfiInspectionRow> _rows(dynamic data) {
    return _unwrap(data)
        .whereType<Map>()
        .map(
          (Map item) =>
              RfiInspectionRow.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  List<RfiFilterOption> _textOptions(dynamic data, List<String> labelKeys) {
    final List<RfiFilterOption> options = <RfiFilterOption>[];
    for (final dynamic item in _unwrap(data)) {
      final String? label = item is String
          ? _clean(item)
          : item is Map
          ? _firstText(Map<String, dynamic>.from(item), labelKeys)
          : _clean(item);
      if (label == null) {
        continue;
      }
      options.add(RfiFilterOption(id: label, label: label));
    }
    return options;
  }

  List<RfiFilterOption> _namedOptions(
    dynamic data, {
    required List<String> idKeys,
    required List<String> labelKeys,
    required bool numeric,
  }) {
    final List<RfiFilterOption> options = <RfiFilterOption>[];
    for (final dynamic item in _unwrap(data)) {
      if (item is! Map) {
        continue;
      }
      final Map<String, dynamic> json = Map<String, dynamic>.from(item);
      final String? label = _firstText(json, labelKeys);
      if (numeric) {
        final int? numberId = _firstInt(json, idKeys);
        if (numberId == null) {
          continue;
        }
        options.add(
          RfiFilterOption(
            id: numberId.toString(),
            label: label ?? numberId.toString(),
            numberId: numberId,
          ),
        );
        continue;
      }
      final String? id = _firstText(json, idKeys);
      if (id == null) {
        continue;
      }
      options.add(RfiFilterOption(id: id, label: label ?? id));
    }
    return options;
  }

  List<dynamic> _unwrap(dynamic data) {
    if (data is List) {
      return data;
    }
    if (data is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(data);
      for (final String key in const <String>[
        'data',
        'result',
        'content',
        'list',
        'records',
      ]) {
        final Object? nested = map[key];
        if (nested is List) {
          return nested;
        }
      }
    }
    return const <dynamic>[];
  }

  String? _firstText(Map<String, dynamic> json, List<String> keys) {
    for (final String key in keys) {
      final String? text = _clean(json[key]);
      if (text != null) {
        return text;
      }
    }
    return null;
  }

  int? _firstInt(Map<String, dynamic> json, List<String> keys) {
    for (final String key in keys) {
      final Object? value = json[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final int? parsed = int.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  String? _clean(Object? value) {
    if (value == null) {
      return null;
    }
    final String text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return text;
  }
}
