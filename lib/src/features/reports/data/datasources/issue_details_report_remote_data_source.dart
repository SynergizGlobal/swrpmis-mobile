import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/issue_details_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/pending_issues_report.dart';

final issueDetailsReportRemoteDataSourceProvider =
    Provider<IssueDetailsReportRemoteDataSource>((Ref ref) {
      return IssueDetailsReportRemoteDataSource(ref.watch(dioProvider));
    });

class IssueDetailsReportRemoteDataSource {
  IssueDetailsReportRemoteDataSource(this._dio);

  final Dio _dio;

  static const Map<String, dynamic> _emptyBody = <String, dynamic>{};

  Future<List<PendingIssuesHodOption>> fetchHods() async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.pendingIssuesHodListPath,
      data: _emptyBody,
    );
    return parseIssueDetailsHods(response.data);
  }

  Future<List<ContractDetailOption>> fetchContracts() async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.pendingIssuesContractListPath,
      data: _emptyBody,
    );
    return parseIssueDetailsContracts(response.data);
  }

  Future<List<ContractDetailOption>> fetchStatuses() async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.issueDetailsStatusListPath,
      data: _emptyBody,
    );
    return parseIssueDetailsStatuses(response.data);
  }

  Future<List<ContractDetailOption>> fetchLocations() async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.issueDetailsLocationListPath,
      data: _emptyBody,
    );
    return parseIssueDetailsLocations(response.data);
  }

  Future<List<ContractDetailOption>> fetchCategories() async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.issueDetailsCategoryListPath,
      data: _emptyBody,
    );
    return parseIssueDetailsCategories(response.data);
  }

  Future<List<IssueDetailsTitleOption>> fetchTitles() async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.issueDetailsTitleListPath,
      data: _emptyBody,
    );
    return parseIssueDetailsTitles(response.data);
  }

  /// POST generate; [hodUserId] is sent as `hod_user_id_fk` (user id, not name).
  Future<({Uint8List bytes, String fileName})> generate({
    required String hodUserId,
    required String contractId,
    required String status,
    required String location,
    required String category,
    required String issueId,
  }) async {
    final Map<String, dynamic> body = buildIssueDetailsGenerateBody(
      hodUserId: hodUserId,
      contractId: contractId,
      status: status,
      location: location,
      category: category,
      issueId: issueId,
    );
    final Response<List<int>> response = await _dio.post<List<int>>(
      ApiConstants.issueDetailsGeneratePath,
      data: body,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 3),
      ),
    );
    final List<int>? data = response.data;
    if (response.statusCode != 200 || data == null || data.isEmpty) {
      throw StateError('Issues Details Report returned an empty file.');
    }
    return (
      bytes: Uint8List.fromList(data),
      fileName: _fileNameFromResponse(
        response,
        fallback: 'Issues_Details_Report.pdf',
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
