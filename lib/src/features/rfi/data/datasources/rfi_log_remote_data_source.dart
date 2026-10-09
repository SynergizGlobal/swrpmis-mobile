import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_filter.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_log_report.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_log_row.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_log_links.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_stored_file.dart';

final rfiLogRemoteDataSourceProvider = Provider<RfiLogRemoteDataSource>((ref) {
  return RfiLogRemoteDataSource(ref.watch(dioProvider));
});

class RfiLogUnavailable implements Exception {
  const RfiLogUnavailable();
}

class RfiLogRemoteDataSource {
  RfiLogRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<RfiLogRow>> fetchRows(RfiInspectionFilter filter) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.rfiLogListPath,
      data: filter.toJson(),
    );
    return _unwrap(response.data)
        .whereType<Map>()
        .map((Map item) => RfiLogRow.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<RfiLogReport> fetchReport(int id) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      RfiLogLinks.reportPath(id),
    );
    final Object? data = response.data;
    if (data is Map) {
      return RfiLogReport.fromJson(Map<String, dynamic>.from(data));
    }
    throw const RfiLogUnavailable();
  }

  Future<Uint8List> previewFile(String filepath) async {
    final Response<List<int>> response = await _dio.get<List<int>>(
      ApiConstants.rfiLogPreviewFilesPath,
      queryParameters: <String, dynamic>{'filepath': filepath},
      options: Options(responseType: ResponseType.bytes),
    );
    final List<int>? data = response.data;
    if (response.statusCode != 200 || data == null || data.isEmpty) {
      throw const RfiLogUnavailable();
    }
    return Uint8List.fromList(data);
  }

  Future<Uint8List> downloadPdf({
    required String rfiId,
    required String txnId,
  }) async {
    final Response<List<int>> response = await _dio.get<List<int>>(
      RfiLogLinks.downloadPath(rfiId, txnId),
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (int? code) => code != null && code < 600,
      ),
    );
    final List<int> data = response.data ?? const <int>[];
    final String? contentType = response.headers.value('content-type');
    if (response.statusCode == 200 && _isPdf(data, contentType)) {
      return Uint8List.fromList(data);
    }
    throw const RfiLogUnavailable();
  }

  Future<Uint8List?> loadLogo(String baseUrl) async {
    try {
      final Response<List<int>> response = await _dio.get<List<int>>(
        RfiLogLinks.logoUrl(baseUrl),
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (int? code) => code != null && code < 600,
        ),
      );
      final List<int>? data = response.data;
      if (response.statusCode != 200 || data == null || data.isEmpty) {
        return null;
      }
      final Uint8List bytes = Uint8List.fromList(data);
      if (!RfiStoredFile.looksLikeImage(bytes)) {
        return null;
      }
      return bytes;
    } on Object {
      return null;
    }
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
}

bool _isPdf(List<int> bytes, String? contentType) {
  final String type = (contentType ?? '').toLowerCase();
  if (type.contains('pdf') && bytes.isNotEmpty) {
    return true;
  }
  return RfiStoredFile.looksLikePdf(bytes);
}
