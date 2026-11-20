import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/list_of_contracts_report.dart';

final listOfContractsReportRemoteDataSourceProvider =
    Provider<ListOfContractsReportRemoteDataSource>((Ref ref) {
      return ListOfContractsReportRemoteDataSource(ref.watch(dioProvider));
    });

class ListOfContractsReportRemoteDataSource {
  ListOfContractsReportRemoteDataSource(this._dio);

  final Dio _dio;

  /// Shared empty filter body used by web for these ajax list endpoints.
  static const Map<String, dynamic> _emptyBody = <String, dynamic>{};

  /// Reuses Contract Detail project loading (shared filter → /projects → ajax).
  Future<List<ContractDetailOption>> fetchProjects() async {
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

  Future<List<ContractDetailOption>> fetchContractStatuses() async {
    final dynamic data = await _post(
      ApiConstants.contractDetailContractStatusPath,
      _emptyBody,
    );
    return parseListOfContractsContractStatuses(data);
  }

  Future<List<ContractDetailOption>> fetchWorkStatuses() async {
    final dynamic data = await _post(
      ApiConstants.contractDetailWorkStatusPath,
      _emptyBody,
    );
    return parseListOfContractsWorkStatuses(data);
  }

  Future<({Uint8List bytes, String fileName})> generate({
    String projectId = '',
    String contractorId = '',
    String contractStatus = '',
    String workStatus = '',
    String hodDesignation = '',
    String contractId = '',
  }) async {
    final FormData form = FormData.fromMap(<String, dynamic>{
      'project_id_fk': projectId.trim(),
      'hod_designations': hodDesignation.trim(),
      'contractor_id_fk': contractorId.trim(),
      'status': workStatus.trim(),
      'contract_status_fk': contractStatus.trim(),
      'contract_id': contractId.trim(),
      'date': '',
      'todate': '',
      'report_no': '7',
    });
    final Response<List<int>> response = await _dio.post<List<int>>(
      ApiConstants.listOfContractsGeneratePath,
      data: form,
      options: Options(
        responseType: ResponseType.bytes,
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(minutes: 3),
      ),
    );
    final List<int>? data = response.data;
    if (response.statusCode != 200 || data == null || data.isEmpty) {
      throw StateError('List of Contracts report returned an empty file.');
    }
    return (
      bytes: Uint8List.fromList(data),
      fileName: _fileNameFromResponse(
        response,
        fallback: 'List_of_Contracts_Report.pdf',
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
