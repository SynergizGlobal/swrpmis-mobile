import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_completion_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';

final contractCompletionReportRemoteDataSourceProvider =
    Provider<ContractCompletionReportRemoteDataSource>((Ref ref) {
      return ContractCompletionReportRemoteDataSource(ref.watch(dioProvider));
    });

class ContractCompletionReportRemoteDataSource {
  ContractCompletionReportRemoteDataSource(this._dio);

  final Dio _dio;

  static const Map<String, dynamic> _emptyBody = <String, dynamic>{};

  Future<List<ContractDetailOption>> fetchProjects() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.bgInsuranceProjectListPath,
      queryParameters: <String, dynamic>{
        '_t': DateTime.now().millisecondsSinceEpoch,
      },
    );
    return parseContractCompletionProjects(response.data);
  }

  Future<List<ContractDetailOption>> fetchContractors() async {
    final dynamic data = await _post(
      ApiConstants.contractDetailContractorsPath,
      _emptyBody,
    );
    return parseContractCompletionContractors(data);
  }

  Future<List<ContractDetailOption>> fetchHods() async {
    final dynamic data = await _post(
      ApiConstants.contractDetailHodsPath,
      _emptyBody,
    );
    return parseContractCompletionHods(data);
  }

  Future<List<ContractDetailOption>> fetchContractStatuses() async {
    final dynamic data = await _post(
      ApiConstants.contractDetailContractStatusPath,
      _emptyBody,
    );
    return parseContractCompletionContractStatuses(data);
  }

  Future<({Uint8List bytes, String fileName})> generate({
    required String projectId,
    required String contractorId,
    required String contractStatus,
    required String hodDesignation,
  }) async {
    final FormData form = FormData.fromMap(<String, dynamic>{
      'project_id_fk': projectId.trim(),
      'hod_designations': hodDesignation.trim(),
      'contractor_id_fk': contractorId.trim(),
      'status': '',
      'contract_status_fk': contractStatus.trim(),
      'contract_id': '',
      'date': '',
      'todate': '',
      'report_no': '9',
    });
    final Response<List<int>> response = await _dio.post<List<int>>(
      ApiConstants.contractCompletionGeneratePath,
      data: form,
      options: Options(
        responseType: ResponseType.bytes,
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(minutes: 3),
      ),
    );
    final List<int>? data = response.data;
    if (response.statusCode != 200 || data == null || data.isEmpty) {
      throw StateError('Contract Completion report returned an empty file.');
    }
    return (
      bytes: Uint8List.fromList(data),
      fileName: _fileNameFromResponse(
        response,
        fallback: 'Contract_Completion_Report.pdf',
      ),
    );
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
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
