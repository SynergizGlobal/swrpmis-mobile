import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/constants/app_assets.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_detail.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_list.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_parse.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_log_links.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_stored_file.dart';

final materialReceiptRemoteDataSourceProvider =
    Provider<MaterialReceiptRemoteDataSource>((ref) {
      return MaterialReceiptRemoteDataSource(ref.watch(dioProvider));
    });

class MaterialReceiptRemoteDataSource {
  MaterialReceiptRemoteDataSource(this._dio);

  final Dio _dio;

  Future<MaterialReceiptListSnapshot> fetch(
    MaterialReceiptListQuery query, {
    MaterialReceiptListSnapshot previous = MaterialReceiptListSnapshot.empty,
    bool reloadFilters = true,
  }) async {
    final Future<({List<MaterialReceiptRow> rows, int total})> listFuture =
        _getList(query);
    final Future<MaterialReceiptListSnapshot> filtersFuture = reloadFilters
        ? _getFilters()
        : Future<MaterialReceiptListSnapshot>.value(previous);
    final List<Object> results = await Future.wait<Object>(
      <Future<Object>>[listFuture, filtersFuture],
    );
    final ({List<MaterialReceiptRow> rows, int total}) list =
        results[0] as ({List<MaterialReceiptRow> rows, int total});
    final MaterialReceiptListSnapshot filters =
        results[1] as MaterialReceiptListSnapshot;
    return MaterialReceiptListSnapshot(
      projects: filters.projects,
      sections: filters.sections,
      contracts: filters.contracts,
      materials: filters.materials,
      rows: list.rows,
      total: list.total,
    );
  }

  Future<MaterialReceiptDetail> fetchDetail(String receiptId) async {
    final String id = receiptId.trim();
    if (id.isEmpty) {
      throw StateError('Receipt id is required.');
    }
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialReceiptViewPath(id),
    );
    return parseMaterialReceiptDetail(response.data);
  }

  Future<({Uint8List bytes, String fileName})> downloadDocument(int docId) async {
    final Response<List<int>> response = await _dio.get<List<int>>(
      ApiConstants.materialReceiptDownloadDocumentPath(docId),
      options: Options(responseType: ResponseType.bytes),
    );
    final List<int>? data = response.data;
    if (data == null || data.isEmpty) {
      throw StateError('Empty document download.');
    }
    return (
      bytes: Uint8List.fromList(data),
      fileName: _fileNameFromResponse(
        response,
        fallback: 'document_$docId.bin',
      ),
    );
  }

  Future<Uint8List?> loadLogo(String baseUrl) async {
    try {
      final Response<List<int>> response = await _dio.get<List<int>>(
        RfiLogLinks.logoUrl(baseUrl),
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (int? status) =>
              status != null && status >= 200 && status < 400,
        ),
      );
      final List<int>? data = response.data;
      if (data != null &&
          data.isNotEmpty &&
          RfiStoredFile.looksLikeImage(data)) {
        return Uint8List.fromList(data);
      }
    } on Object {
      // Fall through to bundled railway logo.
    }
    try {
      final ByteData asset = await rootBundle.load(AppAssets.railwayLogo);
      return asset.buffer.asUint8List();
    } on Object {
      return null;
    }
  }

  Future<({List<MaterialReceiptRow> rows, int total})> _getList(
    MaterialReceiptListQuery query,
  ) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialReceiptListPath,
      queryParameters: query.listQueryParameters(),
    );
    return parseMaterialReceiptList(response.data);
  }

  Future<MaterialReceiptListSnapshot> _getFilters() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialReceiptFilterOptionsPath,
    );
    return parseMaterialReceiptFilterOptions(response.data);
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
