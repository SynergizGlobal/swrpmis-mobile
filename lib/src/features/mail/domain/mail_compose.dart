import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

@immutable
class MailComposeProject {
  const MailComposeProject({
    required this.projectId,
    required this.projectName,
  });

  final String projectId;
  final String projectName;

  String get label {
    final String name = projectName.trim();
    if (name.isEmpty || name == projectId) {
      return projectId;
    }
    return name;
  }
}

@immutable
class MailComposeContract {
  const MailComposeContract({
    required this.contractId,
    required this.contractShortName,
    required this.contractName,
  });

  final String contractId;
  final String contractShortName;
  final String contractName;

  String get label {
    final String shortName = contractShortName.trim();
    if (shortName.isNotEmpty) {
      return shortName;
    }
    final String name = contractName.trim();
    if (name.isNotEmpty) {
      return name;
    }
    return contractId;
  }
}

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

  String get displayName {
    if (username.trim().isNotEmpty) {
      return username.trim();
    }
    if (emailId.trim().isNotEmpty) {
      return emailId.trim();
    }
    return userId.trim();
  }

  String get chipLabel {
    final String name = displayName;
    if (userId.isEmpty || name == userId) {
      return name;
    }
    return name;
  }

  String get initial {
    final String source = displayName;
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
class MailDraftSaveResult {
  const MailDraftSaveResult({
    required this.message,
    this.draftId,
  });

  final int? draftId;
  final String message;
}

@immutable
class MailComposePayload {
  const MailComposePayload({
    required this.toUserIds,
    required this.ccUserIds,
    required this.bccUserIds,
    required this.subject,
    required this.body,
    required this.projectId,
    required this.contractId,
    required this.contractShortName,
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

  final List<String> toUserIds;
  final List<String> ccUserIds;
  final List<String> bccUserIds;
  final String subject;
  final String body;
  final String projectId;
  final String contractId;
  final String contractShortName;
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
      'toUserIds': toUserIds,
      'ccUserIds': ccUserIds,
      'bccUserIds': bccUserIds,
      'subject': subject,
      'body': body,
      'contractId': contractId,
      'contractShortName': contractShortName,
      'projectId': projectId,
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
