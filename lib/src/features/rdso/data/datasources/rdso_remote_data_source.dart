import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_list.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_parse.dart';

final rdsoRemoteDataSourceProvider = Provider<RdsoRemoteDataSource>((ref) {
  return RdsoRemoteDataSource(ref.watch(dioProvider));
});

class RdsoCrawlConflictException implements Exception {
  RdsoCrawlConflictException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RdsoRemoteDataSource {
  RdsoRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<RdsoCategory>> fetchCategories() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rdsoCategoriesPath,
    );
    return parseRdsoCategories(response.data);
  }

  Future<List<RdsoSubhead>> fetchSubheads(String categoryId) async {
    final String trimmed = categoryId.trim();
    if (trimmed.isEmpty) {
      return const <RdsoSubhead>[];
    }
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rdsoCategorySubheadsPath(trimmed),
    );
    return parseRdsoSubheads(response.data, categoryId: trimmed);
  }

  Future<List<RdsoDrawingRow>> fetchSubheadDrawings(String subheadId) async {
    final String trimmed = subheadId.trim();
    if (trimmed.isEmpty) {
      return const <RdsoDrawingRow>[];
    }
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rdsoSubheadDrawingsPath(trimmed),
    );
    return parseRdsoDrawingList(response.data);
  }

  Future<RdsoRevisionSnapshot> fetchRegister(RdsoRevisionQuery query) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rdsoDrawingsRegisterPath,
      queryParameters: query.queryParameters(),
    );
    return parseRdsoRegister(response.data);
  }

  Future<RdsoRevisionSnapshot> fetchLibraryRegister(
    RdsoLibraryQuery query,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rdsoDrawingsRegisterPath,
      queryParameters: query.queryParameters(),
    );
    return parseRdsoRegister(response.data);
  }

  Future<List<RdsoDrawingFile>> fetchDrawingFiles(String drawingId) async {
    final String trimmed = drawingId.trim();
    if (trimmed.isEmpty) {
      return const <RdsoDrawingFile>[];
    }
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rdsoDrawingFilesPath(trimmed),
    );
    return parseRdsoDrawingFiles(response.data);
  }

  Future<List<RdsoPost>> fetchDrawingPosts(String drawingId) async {
    final String trimmed = drawingId.trim();
    if (trimmed.isEmpty) {
      return const <RdsoPost>[];
    }
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rdsoDrawingPostsPath(trimmed),
    );
    return parseRdsoPosts(response.data);
  }

  Future<void> createPost({
    required String drawingId,
    required String postType,
    required String content,
  }) async {
    await _dio.post<dynamic>(
      ApiConstants.rdsoPostsPath,
      data: <String, dynamic>{
        'drawingId': drawingId.trim(),
        'postType': postType.trim(),
        'content': content.trim(),
        'parentId': null,
      },
    );
  }

  Future<void> sendFileMail({
    required String fileId,
    required String recipient,
    String message = '',
  }) async {
    await _dio.post<dynamic>(
      ApiConstants.rdsoFileSendMailPath(fileId.trim()),
      data: <String, dynamic>{
        'recipient': recipient.trim(),
        'message': message.trim(),
      },
    );
  }

  Future<List<RdsoCrawlRun>> fetchCrawlRuns() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rdsoCrawlRunsPath,
    );
    return parseRdsoCrawlRuns(response.data);
  }

  Future<String> fetchCrawlRunLogs(String runId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rdsoCrawlRunLogsPath(runId.trim()),
    );
    return parseRdsoCrawlLogs(response.data);
  }

  Future<void> startCrawl() async {
    try {
      await _dio.post<dynamic>(ApiConstants.rdsoCrawlStartPath);
    } on DioException catch (error) {
      if (error.response?.statusCode == 409) {
        final String? message = rdsoApiMessage(error.response?.data);
        throw RdsoCrawlConflictException(
          message ?? 'An RDSO crawler run is already active',
        );
      }
      rethrow;
    }
  }

  Future<({Uint8List bytes, String fileName})> downloadFile({
    required String fileId,
    required bool preview,
    String fallbackName = 'rdso-drawing.pdf',
  }) async {
    final String trimmed = fileId.trim();
    if (trimmed.isEmpty) {
      throw StateError('File is not available.');
    }
    final String path = preview
        ? ApiConstants.rdsoFileViewPath(trimmed)
        : ApiConstants.rdsoFileDownloadPath(trimmed);
    final Response<List<int>> response = await _dio.get<List<int>>(
      path,
      options: Options(responseType: ResponseType.bytes),
    );
    final List<int>? data = response.data;
    if (data == null || data.isEmpty) {
      throw StateError(
        preview ? 'Unable to preview this file.' : 'Unable to download this file.',
      );
    }
    return (
      bytes: Uint8List.fromList(data),
      fileName: _fileNameFromResponse(response, fallback: fallbackName),
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
