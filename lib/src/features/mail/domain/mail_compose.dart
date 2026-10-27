import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

@immutable
class MailRecipient {
  const MailRecipient({
    required this.emailId,
    required this.userId,
    required this.username,
  });

  final String emailId;
  final String userId;
  final String username;

  String get initial {
    final String source =
        username.trim().isNotEmpty ? username.trim() : emailId.trim();
    if (source.isEmpty) {
      return '?';
    }
    return source.substring(0, 1).toUpperCase();
  }
}

@immutable
class MailComposeAttachment {
  const MailComposeAttachment({
    required this.name,
    this.path,
    this.bytes,
  });

  final String name;
  final String? path;
  final List<int>? bytes;
}

@immutable
class MailComposePayload {
  const MailComposePayload({
    required this.to,
    required this.cc,
    required this.bcc,
    required this.subject,
    required this.body,
    required this.referenceId,
    required this.category,
    required this.requiredResponse,
    required this.targetResponseDate,
    required this.correspondenceLetterNo,
    required this.priority,
    required this.tags,
    required this.repositoryDocumentIds,
    this.linkedDocumentIds = const <int>[],
    this.parentMailId,
    this.threadId,
  });

  final List<String> to;
  final List<String> cc;
  final List<String> bcc;
  final String subject;
  final String body;
  final String referenceId;
  final String category;
  final bool requiredResponse;
  final DateTime? targetResponseDate;
  final String correspondenceLetterNo;
  final String priority;
  final List<String> tags;
  final List<int> repositoryDocumentIds;
  final List<int> linkedDocumentIds;
  final int? parentMailId;
  final int? threadId;

  Map<String, dynamic> toJson() {
    final String? target = targetResponseDate == null
        ? null
        : DateFormat('yyyy-MM-dd').format(targetResponseDate!);
    return <String, dynamic>{
      'to': to,
      'cc': cc,
      'bcc': bcc,
      'subject': subject,
      'body': body,
      'referenceId': referenceId,
      'category': category,
      'requiredResponse': requiredResponse,
      'targetResponseDate': target,
      'correspondenceLetterNo': correspondenceLetterNo,
      'priority': priority,
      'tags': tags,
      'repositoryDocumentIds': repositoryDocumentIds,
      'linkedDocumentIds': linkedDocumentIds,
      'parentMailId': parentMailId,
      'threadId': threadId,
    };
  }
}
