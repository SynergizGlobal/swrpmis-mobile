import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_category_access.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_list_item.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_list_kind.dart';

final rfiRemoteDataSourceProvider = Provider<RfiRemoteDataSource>((ref) {
  return RfiRemoteDataSource(ref.watch(dioProvider));
});

class RfiRemoteDataSource {
  RfiRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<RfiListItem>> fetchList(RfiListKind kind) async {
    final String path = switch (kind) {
      RfiListKind.material => ApiConstants.materialRfiListPath,
      RfiListKind.work => ApiConstants.workRfiListPath,
      RfiListKind.quality => ApiConstants.qualityRfiListPath,
    };
    final Response<dynamic> response = await _dio.get<dynamic>(path);
    return _asList(
      response.data,
    ).map(RfiListItem.fromJson).toList(growable: false);
  }

  /// Both access checks the web list page makes before it renders actions.
  Future<RfiCategoryAccess> fetchCategoryAccess(String rfiCategory) async {
    final Map<String, dynamic> query = <String, dynamic>{
      'rfiCategory': rfiCategory,
    };
    final List<Response<dynamic>> responses =
        await Future.wait(<Future<Response<dynamic>>>[
          _dio.get<dynamic>(
            ApiConstants.rfiCategoryViewOnlyPath,
            queryParameters: query,
          ),
          _dio.get<dynamic>(
            ApiConstants.rfiCanCreatePath,
            queryParameters: query,
          ),
        ]);
    return RfiCategoryAccess(
      viewOnly: parseRfiViewOnly(responses[0].data),
      canCreate: parseRfiCanCreate(responses[1].data),
    );
  }

  /// Marks an RFI as deleted with the user's reason. Returns the server's
  /// message, or a default when it sends none.
  Future<String> deleteRfi({required int id, required String reason}) async {
    final Response<dynamic> response = await _dio.delete<dynamic>(
      ApiConstants.rfiDeletePath,
      data: <String, dynamic>{'id': id, 'description': reason.trim()},
    );
    return rfiDeleteMessage(response.data);
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((Map item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (data is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(data);
      for (final String key in const <String>[
        'data',
        'result',
        'content',
        'list',
        'records',
      ]) {
        final Object? nested = map[key];
        if (nested is List) {
          return _asList(nested);
        }
      }
    }
    return <Map<String, dynamic>>[];
  }
}

const String rfiDeleteDefaultMessage = 'RFI marked as deleted successfully!';

/// The delete endpoint answers with plain text; a JSON `message` is also
/// accepted in case the server wraps it later.
String rfiDeleteMessage(dynamic data) {
  if (data is String && data.trim().isNotEmpty) {
    return data.trim();
  }
  if (data is Map) {
    final Object? message = data['message'] ?? data['msg'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
  }
  return rfiDeleteDefaultMessage;
}
