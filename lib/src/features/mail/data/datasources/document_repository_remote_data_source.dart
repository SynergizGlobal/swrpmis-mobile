import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/document_repository.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_parse.dart';

final documentRepositoryRemoteDataSourceProvider =
    Provider<DocumentRepositoryRemoteDataSource>((ref) {
      return DocumentRepositoryRemoteDataSource(ref.watch(dioProvider));
    });

class DocumentRepositoryRemoteDataSource {
  DocumentRepositoryRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<RepositoryItem>> fetchRoot() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.documentsRepositoryPath,
    );
    return parseRepositoryItems(response.data);
  }

  Future<List<RepositoryItem>> fetchFolder(int folderId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.documentsRepositoryFolderPath(folderId),
    );
    return parseRepositoryItems(response.data);
  }

  Future<RepositoryItem?> createFolder({
    required String folderName,
    int? parentId,
  }) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.documentsRepositoryCreateFolderPath,
      queryParameters: <String, dynamic>{
        'folderName': folderName.trim(),
        if (parentId != null) 'parentId': parentId,
      },
    );
    return parseRepositoryItem(response.data);
  }

  Future<RepositoryItem?> uploadFile({
    required String fileName,
    required List<int> bytes,
    int? parentId,
  }) async {
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
      if (parentId != null) 'parentId': parentId,
    });
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.documentsRepositoryUploadPath,
      data: formData,
    );
    return parseRepositoryItem(response.data);
  }

  Future<RepositoryItem?> rename({
    required int id,
    required String newName,
  }) async {
    final Response<dynamic> response = await _dio.put<dynamic>(
      ApiConstants.documentsRepositoryRenamePath(id),
      queryParameters: <String, dynamic>{'newName': newName.trim()},
    );
    return parseRepositoryItem(response.data);
  }

  Future<Uint8List> download({required int id}) async {
    final Response<List<int>> response = await _dio.get<List<int>>(
      ApiConstants.documentsRepositoryDownloadPath(id),
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? <int>[]);
  }

  Future<String> delete({required int id}) async {
    final Response<dynamic> response = await _dio.delete<dynamic>(
      ApiConstants.documentsRepositoryDeletePath(id),
    );
    return mailApiMessage(response.data) ??
        (response.data?.toString().trim().isNotEmpty == true
            ? response.data.toString().trim()
            : 'Repository item deleted successfully');
  }
}
