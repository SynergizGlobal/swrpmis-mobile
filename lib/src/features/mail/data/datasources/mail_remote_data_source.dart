import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_compose.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_dashboard.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_parse.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_thread.dart';

final mailRemoteDataSourceProvider = Provider<MailRemoteDataSource>((ref) {
  return MailRemoteDataSource(ref.watch(dioProvider));
});

class MailRemoteDataSource {
  MailRemoteDataSource(this._dio);

  final Dio _dio;

  Future<MailDashboardData> fetchDashboard() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.mailDashboardPath,
    );
    return parseMailDashboard(response.data);
  }

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

  Future<String> markMailRead({
    required int mailId,
    required String userId,
  }) async {
    final String uid = userId.trim();
    if (uid.isEmpty) {
      throw StateError('User id missing; cannot mark mail as read.');
    }
    final Response<dynamic> response = await _dio.put<dynamic>(
      ApiConstants.mailReadPath(mailId, uid),
    );
    return mailApiMessage(response.data) ?? 'Mail marked as read';
  }

  Future<List<MailThreadMessage>> fetchThread(int mailId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.mailThreadPath(mailId),
    );
    return parseMailThread(response.data);
  }

  Future<String> moveToTrash({required int mailId}) async {
    final Response<dynamic> response = await _dio.put<dynamic>(
      ApiConstants.mailTrashActionPath(mailId),
    );
    return mailApiMessage(response.data) ?? 'Mail moved to trash successfully';
  }

  Future<String> restoreMail({required int mailId}) async {
    final Response<dynamic> response = await _dio.put<dynamic>(
      ApiConstants.mailRestorePath(mailId),
    );
    return mailApiMessage(response.data) ?? 'Mail restored successfully';
  }

  Future<String> permanentDelete({required int mailId}) async {
    final Response<dynamic> response = await _dio.delete<dynamic>(
      ApiConstants.mailPermanentDeletePath(mailId),
    );
    return mailApiMessage(response.data) ?? 'Mail deleted permanently';
  }

  Future<List<MailComposeProject>> fetchComposeProjects() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.contractProjectsFilterPath,
    );
    return parseMailComposeProjects(response.data);
  }

  Future<List<MailComposeContract>> fetchComposeContracts(
    String projectId,
  ) async {
    final String id = projectId.trim();
    if (id.isEmpty) {
      return const <MailComposeContract>[];
    }
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.contractListPath,
      data: <String, dynamic>{'project_id_fk': id},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return parseMailComposeContracts(response.data);
  }

  Future<List<MailRecipient>> fetchRecipientsByContract(
    String contractShortName,
  ) async {
    final String shortName = contractShortName.trim();
    if (shortName.isEmpty) {
      return const <MailRecipient>[];
    }
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.mailRecipientsByContractPath,
      queryParameters: <String, dynamic>{'contractShortName': shortName},
    );
    return parseMailRecipients(response.data);
  }

  Future<List<MailRecipient>> searchRecipients(String query) async {
    final String q = query.trim();
    if (q.isEmpty) {
      return const <MailRecipient>[];
    }
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.mailRecipientsSearchPath,
      queryParameters: <String, dynamic>{'q': q},
    );
    return parseMailRecipients(response.data);
  }

  Future<String> generateReference() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.mailGenerateReferencePath,
      options: Options(responseType: ResponseType.plain),
    );
    final String reference = parseMailReference(response.data);
    return reference;
  }

  Future<MailDraftSaveResult> saveDraft({
    required MailComposePayload payload,
    List<MailComposeAttachment> files = const <MailComposeAttachment>[],
  }) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.mailDraftPath,
      data: await _composeFormData(payload: payload, files: files),
      options: Options(contentType: 'multipart/form-data'),
    );
    _throwIfMailError(response.data);
    return MailDraftSaveResult(
      draftId: parseMailDraftId(response.data),
      message: mailApiMessage(response.data) ?? 'Draft saved successfully',
    );
  }

  /// Web flow: save draft (if needed) then `POST /api/mail/draft/{id}/send`.
  Future<String> sendMail({
    required MailComposePayload payload,
    List<MailComposeAttachment> files = const <MailComposeAttachment>[],
    int? draftId,
  }) async {
    int? id = draftId;
    final MailDraftSaveResult saved = await saveDraft(
      payload: payload,
      files: files,
    );
    id = saved.draftId ?? id;
    if (id == null) {
      throw StateError('Draft id missing; cannot send mail.');
    }
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.mailDraftSendPath(id),
      data: await _composeFormData(payload: payload, files: files),
      options: Options(contentType: 'multipart/form-data'),
    );
    _throwIfMailError(response.data);
    return mailApiMessage(response.data) ?? 'Mail sent successfully';
  }

  void _throwIfMailError(dynamic data) {
    if (data is! Map) {
      return;
    }
    final dynamic error = data['error'];
    if (error == null) {
      return;
    }
    final String text = error.toString().trim();
    if (text.isEmpty) {
      return;
    }
    throw StateError(text);
  }

  Future<FormData> _composeFormData({
    required MailComposePayload payload,
    required List<MailComposeAttachment> files,
  }) async {
    final FormData formData = FormData();
    formData.fields.add(
      MapEntry<String, String>('mailData', jsonEncode(payload.toJson())),
    );
    for (final MailComposeAttachment file in files) {
      final List<int>? bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        continue;
      }
      formData.files.add(
        MapEntry<String, MultipartFile>(
          'files',
          MultipartFile.fromBytes(bytes, filename: file.name),
        ),
      );
    }
    return formData;
  }

  Future<MailLabel> createLabel({
    required String name,
    required String color,
  }) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.mailLabelsPath,
      data: <String, dynamic>{'name': name.trim(), 'color': color},
    );
    final List<MailLabel> parsed = parseMailLabels(<dynamic>[response.data]);
    if (parsed.isNotEmpty) {
      return parsed.first;
    }
    return MailLabel(id: 0, name: name.trim(), colorHex: color);
  }
}
