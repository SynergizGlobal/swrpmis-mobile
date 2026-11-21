import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';

final contractorsListReportRemoteDataSourceProvider =
    Provider<ContractorsListReportRemoteDataSource>((Ref ref) {
      return ContractorsListReportRemoteDataSource(ref.watch(dioProvider));
    });

/// Reports → Contracts → List of Contractors download.
class ContractorsListReportRemoteDataSource {
  ContractorsListReportRemoteDataSource(this._dio);

  final Dio _dio;

  /// POST `/contract-report/contractorslist` with `{}` → file bytes.
  Future<({Uint8List bytes, String fileName})> download() async {
    final Response<List<int>> response = await _dio.post<List<int>>(
      ApiConstants.contractorsListReportPath,
      data: const <String, dynamic>{},
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 3),
      ),
    );
    final List<int>? data = response.data;
    if (response.statusCode != 200 || data == null || data.isEmpty) {
      throw StateError('List of Contractors report returned an empty file.');
    }
    return (
      bytes: Uint8List.fromList(data),
      fileName: _fileNameFromResponse(
        response,
        fallback: 'List_of_Contractors.pdf',
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
