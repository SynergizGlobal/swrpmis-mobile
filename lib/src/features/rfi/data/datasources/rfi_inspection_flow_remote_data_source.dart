import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_checklist_item.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_access.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_details.dart';

final rfiInspectionFlowRemoteDataSourceProvider =
    Provider<RfiInspectionFlowRemoteDataSource>((ref) {
      return RfiInspectionFlowRemoteDataSource(ref.watch(dioProvider));
    });

class RfiInspectionFlowRemoteDataSource {
  RfiInspectionFlowRemoteDataSource(this._dio);

  final Dio _dio;

  Future<RfiInspectionAccess> fetchAccess(String rfiCategory) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rfiInspectionAccessPath,
      queryParameters: <String, String>{'rfiCategory': rfiCategory},
    );
    return RfiInspectionAccess.fromJson(_asMap(response.data));
  }

  Future<RfiUserSignature> checkUserSignature(String userId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.checkUserSignaturePath,
      queryParameters: <String, String>{'userId': userId},
    );
    return RfiUserSignature.fromJson(_asMap(response.data));
  }

  Future<RfiInspectionDetails> fetchDetails(int rfiId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rfiDetailsByIdPath(rfiId),
    );
    return RfiInspectionDetails.fromJson(_asMap(response.data));
  }

  Future<int> saveDraft({
    required Map<String, dynamic> data,
    required String selfiePath,
  }) async {
    final FormData form = FormData.fromMap(<String, dynamic>{
      'data': jsonEncode(data),
      'selfie': await MultipartFile.fromFile(
        selfiePath,
        filename: p.basename(selfiePath),
      ),
    });
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.rfiSaveDraftPath,
      data: form,
    );
    return _parseInspectionId(response.data);
  }

  Future<void> uploadSiteImage({
    required int rfiId,
    required String imagePath,
    required String uploadedBy,
  }) async {
    final FormData form = FormData.fromMap(<String, dynamic>{
      'RfiId': rfiId,
      'uploadedBy': uploadedBy,
      'siteImage': await MultipartFile.fromFile(
        imagePath,
        filename: p.basename(imagePath),
      ),
    });
    await _dio.post<dynamic>(ApiConstants.rfiUploadSiteImagePath, data: form);
  }

  Future<void> uploadEnclosure({
    required int rfiId,
    required String filePath,
    required String enclosureName,
    required String rfiDescription,
    required String uploadedBy,
  }) async {
    final FormData form = FormData.fromMap(<String, dynamic>{
      'rfiId': rfiId,
      'enclosureName': enclosureName,
      'rfiDescription': rfiDescription,
      'uploadedBy': uploadedBy,
      'file': await MultipartFile.fromFile(
        filePath,
        filename: p.basename(filePath),
      ),
    });
    await _dio.post<dynamic>(ApiConstants.rfiUploadEnclosurePath, data: form);
  }

  Future<List<RfiChecklistItem>> fetchChecklistItems({
    required String enclosureName,
    required String rfiDescription,
    required int rfiId,
  }) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rfiChecklistItemsPath,
      queryParameters: <String, dynamic>{
        'enclosureName': enclosureName,
        'rfiDescription': rfiDescription,
        'rfiId': rfiId,
      },
    );
    return parseRfiChecklistItems(response.data);
  }

  Future<String> saveChecklist(Map<String, dynamic> payload) async {
    final FormData form = FormData.fromMap(<String, dynamic>{
      'data': jsonEncode(payload),
    });
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.rfiSaveChecklistPath,
      data: form,
    );
    return _message(response.data, fallback: 'Checklist saved successfully.');
  }

  Future<String> finalSubmit({
    required Map<String, dynamic> data,
    String? selfiePath,
    List<({String path, String description})> supportingFiles =
        const <({String path, String description})>[],
    String? testReportPath,
  }) async {
    final FormData form = FormData();
    form.fields.add(MapEntry<String, String>('data', jsonEncode(data)));
    if (selfiePath != null && selfiePath.trim().isNotEmpty) {
      form.files.add(
        MapEntry<String, MultipartFile>(
          'selfie',
          await MultipartFile.fromFile(
            selfiePath,
            filename: p.basename(selfiePath),
          ),
        ),
      );
    }
    for (final ({String path, String description}) doc in supportingFiles) {
      if (doc.path.trim().isEmpty) {
        continue;
      }
      form.files.add(
        MapEntry<String, MultipartFile>(
          'supportingFiles',
          await MultipartFile.fromFile(
            doc.path,
            filename: p.basename(doc.path),
          ),
        ),
      );
    }
    if (testReportPath != null && testReportPath.trim().isNotEmpty) {
      form.files.add(
        MapEntry<String, MultipartFile>(
          'testReport',
          await MultipartFile.fromFile(
            testReportPath,
            filename: p.basename(testReportPath),
          ),
        ),
      );
    }
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.rfiFinalSubmitPath,
      data: form,
    );
    return _message(
      response.data,
      fallback: 'Inspection submitted successfully.',
    );
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw StateError('Unexpected response shape');
  }

  int _parseInspectionId(Object? data) {
    if (data is int) {
      return data;
    }
    if (data is num) {
      return data.toInt();
    }
    if (data is String) {
      final int? parsed = int.tryParse(data.trim());
      if (parsed != null) {
        return parsed;
      }
    }
    if (data is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(data);
      for (final String key in <String>[
        'conInspectionId',
        'inspectionId',
        'id',
        'data',
      ]) {
        final int? parsed = _asInt(map[key]);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    throw StateError('Could not parse inspection draft id from response');
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  String _message(Object? data, {required String fallback}) {
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    if (data is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(data);
      final Object? message = map['message'] ?? map['status'] ?? map['error'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString().trim();
      }
    }
    return fallback;
  }
}
