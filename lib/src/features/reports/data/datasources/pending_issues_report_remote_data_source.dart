import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/pending_issues_report.dart';

final pendingIssuesReportRemoteDataSourceProvider =
    Provider<PendingIssuesReportRemoteDataSource>((Ref ref) {
      return PendingIssuesReportRemoteDataSource(ref.watch(dioProvider));
    });

class PendingIssuesReportRemoteDataSource {
  PendingIssuesReportRemoteDataSource(this._dio);

  final Dio _dio;

  static const Map<String, dynamic> _emptyBody = <String, dynamic>{};

  Future<List<PendingIssuesHodOption>> fetchHods() async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.pendingIssuesHodListPath,
      data: _emptyBody,
    );
    return parsePendingIssuesHods(response.data);
  }

  Future<List<ContractDetailOption>> fetchContracts() async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.pendingIssuesContractListPath,
      data: _emptyBody,
    );
    return parsePendingIssuesContracts(response.data);
  }

  /// POST generate; [hodName] is sent as `hod_user_id_fk` (web quirk).
  Future<({Uint8List bytes, String fileName})> generate({
    required String hodName,
    required String contractId,
  }) async {
    final Map<String, dynamic> body = buildPendingIssuesGenerateBody(
      hodName: hodName,
      contractId: contractId,
    );
    final Response<List<int>> response = await _dio.post<List<int>>(
      ApiConstants.pendingIssuesGeneratePath,
      data: body,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 3),
      ),
    );
    final List<int>? data = response.data;
    if (response.statusCode != 200 || data == null || data.isEmpty) {
      throw StateError('Pending Issues Report returned an empty file.');
    }
    return (
      bytes: Uint8List.fromList(data),
      fileName: _fileNameFromResponse(
        response,
        fallback: 'Pending_Issues_Report.pdf',
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
