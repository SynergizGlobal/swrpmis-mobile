import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/bg_insurance_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';

final bgInsuranceReportRemoteDataSourceProvider =
    Provider<BgInsuranceReportRemoteDataSource>((Ref ref) {
      return BgInsuranceReportRemoteDataSource(ref.watch(dioProvider));
    });

class BgInsuranceReportRemoteDataSource {
  BgInsuranceReportRemoteDataSource(this._dio);

  final Dio _dio;

  static const Map<String, dynamic> _emptyBody = <String, dynamic>{};

  Future<List<ContractDetailOption>> fetchProjects() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.bgInsuranceProjectListPath,
      queryParameters: <String, dynamic>{
        '_t': DateTime.now().millisecondsSinceEpoch,
      },
    );
    return parseBgInsuranceProjects(response.data);
  }

  Future<List<ContractDetailOption>> fetchContractors() async {
    final dynamic data = await _post(
      ApiConstants.contractDetailContractorsPath,
      _emptyBody,
    );
    return parseBgInsuranceContractors(data);
  }

  Future<List<ContractDetailOption>> fetchContractStatuses() async {
    final dynamic data = await _post(
      ApiConstants.contractDetailContractStatusPath,
      _emptyBody,
    );
    return parseBgInsuranceContractStatuses(data);
  }

  Future<({Uint8List bytes, String fileName})> generate({
    String? projectId,
    String? contractorId,
    String? contractStatus,
    required String fromDate,
    required String toDate,
  }) async {
    final String date = fromDate.trim();
    final String todate = toDate.trim();
    if (date.isEmpty || todate.isEmpty) {
      throw StateError('Validity expiry from and to dates are required.');
    }
    final Response<List<int>> response = await _dio.post<List<int>>(
      ApiConstants.bgInsuranceGeneratePath,
      data: <String, dynamic>{
        'project_id_fk': _nullIfEmpty(projectId),
        'contractor_id_fk': _nullIfEmpty(contractorId),
        'contract_status_fk': _nullIfEmpty(contractStatus),
        'status': null,
        'date': date,
        'todate': todate,
      },
      options: Options(
        responseType: ResponseType.bytes,
        contentType: Headers.jsonContentType,
        receiveTimeout: const Duration(minutes: 3),
      ),
    );
    final List<int>? data = response.data;
    if (response.statusCode != 200 || data == null || data.isEmpty) {
      throw StateError('BG/Insurance report returned an empty file.');
    }
    _throwIfJsonErrorPayload(data);
    return (
      bytes: Uint8List.fromList(data),
      fileName: _fileNameFromResponse(
        response,
        fallback: 'BG_Insurance_Report.pdf',
      ),
    );
  }

  String? _nullIfEmpty(String? value) {
    final String trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      path,
      data: body,
    );
    return response.data;
  }

  void _throwIfJsonErrorPayload(List<int> data) {
    if (data.isEmpty) {
      return;
    }
    // PDF / XLSX / ZIP magic — treat as a file.
    final int b0 = data[0];
    if (b0 == 0x25 /* % PDF */ ||
        b0 == 0x50 /* P ZIP/XLSX */ ||
        b0 == 0xD0 /* OLE */) {
      return;
    }
    String text;
    try {
      final int previewLen = data.length < 2048 ? data.length : 2048;
      text = utf8.decode(data.sublist(0, previewLen), allowMalformed: true);
    } on Object {
      return;
    }
    final String trimmed = text.trimLeft();
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
      return;
    }
    try {
      final Object? decoded = jsonDecode(utf8.decode(data));
      throw StateError(_messageFromJsonError(decoded));
    } on StateError {
      rethrow;
    } on Object {
      throw StateError('BG/Insurance report failed. Please try again.');
    }
  }

  String _messageFromJsonError(Object? decoded) {
    if (decoded is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(decoded);
      for (final String key in const <String>[
        'message',
        'error',
        'errorMessage',
        'msg',
        'detail',
        'statusMessage',
      ]) {
        final Object? value = map[key];
        if (value != null) {
          final String text = '$value'.trim();
          if (text.isNotEmpty) {
            return text;
          }
        }
      }
    }
    if (decoded is String && decoded.trim().isNotEmpty) {
      return decoded.trim();
    }
    return 'BG/Insurance report failed. Please try again.';
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
