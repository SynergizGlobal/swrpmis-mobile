import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_parse.dart';

final mailRemoteDataSourceProvider = Provider<MailRemoteDataSource>((ref) {
  return MailRemoteDataSource(ref.watch(dioProvider));
});

class MailRemoteDataSource {
  MailRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<MailMessage>> fetchInbox() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.mailInboxPath,
    );
    return parseMailInboxList(response.data);
  }

  Future<List<MailMessage>> fetchDrafts() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.mailDraftsPath,
    );
    return parseMailDraftList(response.data);
  }

  Future<List<MailMessage>> fetchSent() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.mailSentPath,
    );
    return parseMailSentList(response.data);
  }

  Future<List<MailMessage>> fetchTrash() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.mailTrashPath,
    );
    return parseMailTrashList(response.data);
  }

  Future<List<MailMessage>> fetchStarred() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.mailStarredPath,
    );
    return parseMailStarredList(response.data);
  }

  Future<List<MailLabel>> fetchLabels() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.mailLabelsPath,
    );
    return parseMailLabels(response.data);
  }

  Future<List<MailMessage>> fetchLabelMails(String labelName) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.mailLabelMailsPath(labelName),
    );
    return parseMailLabelList(response.data);
  }

  Future<String> setStarred({
    required int mailId,
    required bool starred,
  }) async {
    final Response<dynamic> response = await _dio.put<dynamic>(
      ApiConstants.mailStarPath(mailId),
      data: <String, dynamic>{'starred': starred, 'mailId': mailId},
    );
    return mailApiMessage(response.data) ??
        (starred ? 'Mail starred' : 'Star removed');
  }

  Future<String> moveToTrash({required int mailId}) async {
    final Response<dynamic> response = await _dio.put<dynamic>(
      ApiConstants.mailTrashActionPath(mailId),
    );
    return mailApiMessage(response.data) ?? 'Mail moved to trash successfully';
  }
}
