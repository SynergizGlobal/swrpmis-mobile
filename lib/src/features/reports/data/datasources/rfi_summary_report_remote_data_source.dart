import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/rfi_summary_report.dart';

final rfiSummaryReportRemoteDataSourceProvider =
    Provider<RfiSummaryReportRemoteDataSource>((Ref ref) {
      return RfiSummaryReportRemoteDataSource(ref.watch(dioProvider));
    });

class RfiSummaryReportRemoteDataSource {
  RfiSummaryReportRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ContractDetailOption>> fetchProjects() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rfiSummaryProjectsPath,
      queryParameters: <String, dynamic>{
        '_t': DateTime.now().millisecondsSinceEpoch,
      },
    );
    return parseRfiSummaryOptions(response.data);
  }

  Future<List<ContractDetailOption>> fetchContracts(String projectId) async {
    final String id = projectId.trim();
    if (id.isEmpty) {
      return const <ContractDetailOption>[];
    }
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rfiSummaryContractsPath,
      queryParameters: <String, dynamic>{
        'projectId': id,
        '_t': DateTime.now().millisecondsSinceEpoch,
      },
    );
    return parseRfiSummaryOptions(response.data);
  }

  Future<List<ContractDetailOption>> fetchCategories({
    required String projectId,
    required String contractId,
  }) async {
    final String project = projectId.trim();
    final String contract = contractId.trim();
    if (project.isEmpty || contract.isEmpty) {
      return const <ContractDetailOption>[];
    }
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rfiSummaryCategoriesPath,
      queryParameters: <String, dynamic>{
        'projectId': project,
        'contractId': contract,
        '_t': DateTime.now().millisecondsSinceEpoch,
      },
    );
    return parseRfiSummaryOptions(response.data);
  }

  Future<RfiSummaryDateRange> fetchDateRange({
    required String projectId,
    required String contractId,
    required String rfiCategory,
  }) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rfiSummaryDateRangePath,
      queryParameters: <String, dynamic>{
        'projectId': projectId.trim(),
        'contractId': contractId.trim(),
        'rfiCategory': rfiCategory.trim(),
        '_t': DateTime.now().millisecondsSinceEpoch,
      },
    );
    return RfiSummaryDateRange.fromJson(response.data);
  }

  /// GET Excel bytes. Optional dates use `from` / `to` as `yyyy-MM-dd`.
  Future<({Uint8List bytes, String fileName})> downloadExcel({
    required String projectId,
    required String contractId,
    required String rfiCategory,
    String? from,
    String? to,
  }) async {
    final String? fromYmd = _optionalYmd(from);
    final String? toYmd = _optionalYmd(to);
    final Response<List<int>> response = await _dio.get<List<int>>(
      ApiConstants.rfiSummaryReportExcelPath,
      queryParameters: <String, dynamic>{
        'projectId': projectId.trim(),
        'contractId': contractId.trim(),
        'rfiCategory': rfiCategory.trim(),
        'from': ?fromYmd,
        'to': ?toYmd,
        '_t': DateTime.now().millisecondsSinceEpoch,
      },
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 3),
      ),
    );
    final List<int>? data = response.data;
    if (response.statusCode != 200 || data == null || data.isEmpty) {
      throw StateError('RFI Summary Report returned an empty file.');
    }
    return (
      bytes: Uint8List.fromList(data),
      fileName: _fileNameFromResponse(
        response,
        fallback: 'rfi_summary_report.xlsx',
      ),
    );
  }

  String? _optionalYmd(String? raw) {
    final String text = raw?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    return text;
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
