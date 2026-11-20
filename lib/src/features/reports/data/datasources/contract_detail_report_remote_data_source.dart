import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';

final contractDetailReportRemoteDataSourceProvider =
    Provider<ContractDetailReportRemoteDataSource>((Ref ref) {
      return ContractDetailReportRemoteDataSource(ref.watch(dioProvider));
    });

class ContractDetailReportRemoteDataSource {
  ContractDetailReportRemoteDataSource(this._dio);

  final Dio _dio;

  /// Shared empty filter body used by web for these ajax list endpoints.
  static const Map<String, dynamic> _emptyBody = <String, dynamic>{};

  Future<List<ContractDetailOption>> fetchProjects() async {
    // Web contract-detail report loads projects from the shared filter list.
    // Prefer that proven endpoint, then fall back to /projects and the
    // contract-report ajax path (path name varies by environment).
    final List<Future<List<ContractDetailOption>> Function()> loaders =
        <Future<List<ContractDetailOption>> Function()>[
          () async {
            final Response<dynamic> response = await _dio.get<dynamic>(
              ApiConstants.contractProjectsFilterPath,
            );
            return parseContractDetailProjects(response.data);
          },
          () async {
            final Response<dynamic> response = await _dio.get<dynamic>(
              ApiConstants.projectsGetProjectsPath,
              queryParameters: <String, dynamic>{
                '_t': DateTime.now().millisecondsSinceEpoch,
              },
            );
            return parseContractDetailProjects(response.data);
          },
          () async {
            final dynamic data = await _post(
              ApiConstants.contractDetailProjectsPath,
              _emptyBody,
            );
            return parseContractDetailProjects(data);
          },
        ];
    Object? lastError;
    for (final Future<List<ContractDetailOption>> Function() load in loaders) {
      try {
        final List<ContractDetailOption> items = await load();
        if (items.isNotEmpty) {
          return items;
        }
      } on Object catch (error) {
        lastError = error;
      }
    }
    if (lastError != null) {
      throw lastError;
    }
    return const <ContractDetailOption>[];
  }

  Future<List<ContractDetailOption>> fetchContracts() async {
    final dynamic data = await _post(
      ApiConstants.contractDetailContractsPath,
      _emptyBody,
    );
    return parseContractDetailContracts(data);
  }

  Future<List<ContractDetailOption>> fetchContractors() async {
    final dynamic data = await _post(
      ApiConstants.contractDetailContractorsPath,
      _emptyBody,
    );
    return parseContractDetailContractors(data);
  }

  Future<List<ContractDetailOption>> fetchHods() async {
    final dynamic data = await _post(
      ApiConstants.contractDetailHodsPath,
      _emptyBody,
    );
    return parseContractDetailHods(data);
  }

  Future<List<ContractDetailOption>> fetchStatuses() async {
    final dynamic data = await _post(
      ApiConstants.contractDetailContractStatusPath,
      _emptyBody,
    );
    return parseContractDetailStatuses(data);
  }

  Future<({Uint8List bytes, String fileName})> generate({
    required String contractId,
    String projectId = '',
    String contractorId = '',
    String status = '',
    String hodDesignation = '',
  }) async {
    final String id = contractId.trim();
    if (id.isEmpty) {
      throw StateError('Contract is required.');
    }
    final FormData form = FormData.fromMap(<String, dynamic>{
      'project_id_fk': projectId.trim(),
      'hod_designations': hodDesignation.trim(),
      'contractor_id_fk': contractorId.trim(),
      'status': '',
      'contract_status_fk': status.trim(),
      'contract_id': id,
      'date': '',
      'todate': '',
      'report_no': '2',
    });
    final Response<List<int>> response = await _dio.post<List<int>>(
      ApiConstants.contractDetailGeneratePath(id),
      data: form,
      options: Options(
        responseType: ResponseType.bytes,
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(minutes: 3),
      ),
    );
    final List<int>? data = response.data;
    if (response.statusCode != 200 || data == null || data.isEmpty) {
      throw StateError('Contract detail report returned an empty file.');
    }
    return (
      bytes: Uint8List.fromList(data),
      fileName: _fileNameFromResponse(
        response,
        fallback: 'Contract_Detail_Report_$id.pdf',
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
