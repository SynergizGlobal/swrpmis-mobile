import 'package:flutter/foundation.dart';

enum MailFolder {
  inbox,
  sent,
  drafts,
  trash,
  starred,
  important,
  label,
  compose,
}

@immutable
class MailLabel {
  const MailLabel({
    required this.id,
    required this.name,
    required this.colorHex,
  });

  final int id;
  final String name;
  final String colorHex;
}

@immutable
class MailAttachmentRef {
  const MailAttachmentRef({required this.name});

  final String name;
}

@immutable
class MailMessage {
  const MailMessage({
    required this.id,
    required this.mailId,
    required this.subject,
    required this.body,
    required this.senderEmail,
    required this.senderId,
    required this.recipientEmail,
    required this.read,
    required this.starred,
    required this.draft,
    required this.deleted,
    required this.referenceId,
    required this.category,
    required this.priority,
    required this.requiredResponse,
    required this.targetResponseDate,
    required this.tags,
    required this.attachments,
    required this.to,
    required this.cc,
    required this.bcc,
    required this.status,
    required this.createdAt,
    required this.sentAt,
    required this.threadId,
    required this.threadCount,
  });

  final int id;
  final int mailId;
  final String subject;
  final String body;
  final String senderEmail;
  final String senderId;
  final String recipientEmail;
  final bool read;
  final bool starred;
  final bool draft;
  final bool deleted;
  final String referenceId;
  final String category;
  final String priority;
  final bool requiredResponse;
  final DateTime? targetResponseDate;
  final List<String> tags;
  final List<MailAttachmentRef> attachments;
  final List<String> to;
  final List<String> cc;
  final List<String> bcc;
  final String status;
  final DateTime? createdAt;
  final DateTime? sentAt;
  final int? threadId;
  final int? threadCount;

  bool get hasAttachments => attachments.isNotEmpty;

  String get displaySender {
    if (senderEmail.isNotEmpty) {
      return senderEmail;
    }
    if (senderId.isNotEmpty) {
      return senderId;
    }
    return recipientEmail;
  }

  String get displaySubject =>
      subject.trim().isEmpty ? '(No Subject)' : subject.trim();

  String get snippet {
    final String text = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length <= 120) {
      return text;
    }
    return '${text.substring(0, 117)}...';
  }

  DateTime? get lastModified => sentAt ?? createdAt;

  String get toDisplay {
    if (to.isEmpty) {
      return recipientEmail;
    }
    return to.join(', ');
  }

  MailMessage copyWith({bool? starred, bool? read}) {
    return MailMessage(
      id: id,
      mailId: mailId,
      subject: subject,
      body: body,
      senderEmail: senderEmail,
      senderId: senderId,
      recipientEmail: recipientEmail,
      read: read ?? this.read,
      starred: starred ?? this.starred,
      draft: draft,
      deleted: deleted,
      referenceId: referenceId,
      category: category,
      priority: priority,
      requiredResponse: requiredResponse,
      targetResponseDate: targetResponseDate,
      tags: tags,
      attachments: attachments,
      to: to,
      cc: cc,
      bcc: bcc,
      status: status,
      createdAt: createdAt,
      sentAt: sentAt,
      threadId: threadId,
      threadCount: threadCount,
    );
  }
}
