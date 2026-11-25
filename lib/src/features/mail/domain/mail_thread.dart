import 'package:flutter/foundation.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';

@immutable
class MailThreadAttachment {
  const MailThreadAttachment({required this.name});

  final String name;
}

@immutable
class MailThreadMessage {
  const MailThreadMessage({
    required this.id,
    required this.mailId,
    required this.threadId,
    required this.parentMessageId,
    required this.senderId,
    required this.senderName,
    required this.subject,
    required this.body,
    required this.action,
    required this.sentAt,
    required this.toUserIds,
    required this.ccUserIds,
    required this.bccUserIds,
    required this.attachments,
  });

  final int id;
  final int mailId;
  final int? threadId;
  final int? parentMessageId;
  final String senderId;
  final String senderName;
  final String subject;
  final String body;
  final String action;
  final DateTime? sentAt;
  final List<String> toUserIds;
  final List<String> ccUserIds;
  final List<String> bccUserIds;
  final List<MailThreadAttachment> attachments;

  String get displaySender {
    final String name = senderName.trim();
    final String id = senderId.trim();
    if (name.isNotEmpty && id.isNotEmpty && name != id) {
      return '$name ($id)';
    }
    if (name.isNotEmpty) {
      return name;
    }
    if (id.isNotEmpty) {
      return id;
    }
    return 'Unknown';
  }

  String get displaySubject =>
      subject.trim().isEmpty ? '(No Subject)' : subject.trim();

  String get actionLabel {
    final String raw = action.trim().toUpperCase();
    if (raw.isEmpty) {
      return 'MESSAGE';
    }
    return raw;
  }

  String get avatarLetter {
    final String source =
        senderName.trim().isNotEmpty ? senderName.trim() : senderId.trim();
    if (source.isEmpty) {
      return '?';
    }
    return source.substring(0, 1).toUpperCase();
  }
}

/// Header metadata for the thread view (from list item / compose fields).
@immutable
class MailThreadHeaderMeta {
  const MailThreadHeaderMeta({
    required this.subject,
    required this.referenceId,
    required this.category,
    required this.priority,
    required this.requiredResponse,
    required this.targetResponseDate,
    required this.status,
    required this.senderName,
    required this.senderId,
    required this.to,
    required this.cc,
  });

  final String subject;
  final String referenceId;
  final String category;
  final String priority;
  final bool requiredResponse;
  final DateTime? targetResponseDate;
  final String status;
  final String senderName;
  final String senderId;
  final List<String> to;
  final List<String> cc;

  factory MailThreadHeaderMeta.fromMessage(MailMessage message) {
    return MailThreadHeaderMeta(
      subject: message.displaySubject,
      referenceId: message.referenceId,
      category: message.category,
      priority: message.priority,
      requiredResponse: message.requiredResponse,
      targetResponseDate: message.targetResponseDate,
      status: message.status,
      senderName: message.senderEmail.isNotEmpty
          ? message.senderEmail
          : message.displaySender,
      senderId: message.senderId,
      to: message.to.isNotEmpty
          ? message.to
          : (message.recipientEmail.isEmpty
              ? const <String>[]
              : <String>[message.recipientEmail]),
      cc: message.cc,
    );
  }

  String get displaySubject =>
      subject.trim().isEmpty ? '(No Subject)' : subject.trim();

  String get displaySender {
    final String name = senderName.trim();
    final String id = senderId.trim();
    if (name.isNotEmpty && id.isNotEmpty && name != id) {
      return '$name ($id)';
    }
    if (name.isNotEmpty) {
      return name;
    }
    return id;
  }

  String get avatarLetter {
    final String source =
        senderName.trim().isNotEmpty ? senderName.trim() : senderId.trim();
    if (source.isEmpty) {
      return '?';
    }
    return source.substring(0, 1).toUpperCase();
  }
}
