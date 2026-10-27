import 'package:flutter/foundation.dart';

@immutable
class MailDashboardSummary {
  const MailDashboardSummary({
    required this.totalMail,
    required this.replyRequired,
    required this.replied,
    required this.pendingToReply,
    required this.pendingWithOthers,
    required this.overdueMails,
  });

  final int totalMail;
  final int replyRequired;
  final int replied;
  final int pendingToReply;
  final int pendingWithOthers;
  final int overdueMails;
}

@immutable
class MailCorrespondenceRow {
  const MailCorrespondenceRow({
    required this.id,
    required this.mailId,
    required this.contract,
    required this.contractor,
    required this.mailNo,
    required this.reference,
    required this.date,
    required this.replyRequired,
    required this.dueDate,
    required this.person,
    required this.replied,
    required this.replyMailNo,
    required this.subject,
    required this.status,
    required this.mailType,
  });

  final int id;
  final int mailId;
  final String contract;
  final String contractor;
  final String mailNo;
  final String reference;
  final String date;
  final String replyRequired;
  final String dueDate;
  final String person;
  final String replied;
  final String replyMailNo;
  final String subject;
  final String status;
  final String mailType;
}

@immutable
class MailDashboardData {
  const MailDashboardData({
    required this.summary,
    required this.rows,
  });

  final MailDashboardSummary summary;
  final List<MailCorrespondenceRow> rows;
}
