import 'package:intl/intl.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/document_repository.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_compose.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_dashboard.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';

List<MailLabel> parseMailLabels(dynamic data) {
  final List<MailLabel> out = <MailLabel>[];
  for (final Map<String, dynamic> json in _maps(data)) {
    final String name = _display(json['name']);
    if (name.isEmpty) {
      continue;
    }
    out.add(
      MailLabel(
        id: _int(json['id']) ?? 0,
        name: name,
        colorHex: _display(json['color']).isEmpty
            ? '#2563EB'
            : _display(json['color']),
      ),
    );
  }
  return out;
}

List<MailMessage> parseMailInboxList(dynamic data) {
  return _parseMessages(data, _inboxMessage);
}

List<MailMessage> parseMailDraftList(dynamic data) {
  return _parseMessages(data, _draftMessage);
}

List<MailMessage> parseMailSentList(dynamic data) {
  return _parseMessages(data, _sentMessage);
}

List<MailMessage> parseMailTrashList(dynamic data) {
  return _parseMessages(data, _trashMessage);
}

List<MailMessage> parseMailStarredList(dynamic data) {
  return _parseMessages(data, _starredMessage);
}

List<MailMessage> parseMailLabelList(dynamic data) {
  return _parseMessages(data, _inboxMessage);
}

String? mailApiMessage(dynamic data) {
  if (data is Map) {
    final dynamic message = data['message'] ?? data['error'];
    if (message != null) {
      final String text = message.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
  }
  if (data is String && data.trim().isNotEmpty) {
    return data.trim();
  }
  return null;
}

List<MailRecipient> parseMailRecipients(dynamic data) {
  final List<MailRecipient> out = <MailRecipient>[];
  for (final Map<String, dynamic> json in _maps(data)) {
    final String email = _display(json['emailId'] ?? json['email']);
    if (email.isEmpty) {
      continue;
    }
    out.add(
      MailRecipient(
        emailId: email,
        userId: _display(json['userId']),
        username: _display(json['username'] ?? json['name']),
      ),
    );
  }
  return out;
}

String parseMailReference(dynamic data) {
  if (data is String) {
    return data.trim();
  }
  if (data is Map) {
    final String fromKeys = _display(
      data['referenceId'] ?? data['reference'] ?? data['data'] ?? data['message'],
    );
    if (fromKeys.isNotEmpty) {
      return fromKeys;
    }
  }
  return data?.toString().trim() ?? '';
}

DateTime? parseMailDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  if (value is List && value.isNotEmpty) {
    final int year = _int(value[0]) ?? 1970;
    final int month = value.length > 1 ? (_int(value[1]) ?? 1) : 1;
    final int day = value.length > 2 ? (_int(value[2]) ?? 1) : 1;
    final int hour = value.length > 3 ? (_int(value[3]) ?? 0) : 0;
    final int minute = value.length > 4 ? (_int(value[4]) ?? 0) : 0;
    final int second = value.length > 5 ? (_int(value[5]) ?? 0) : 0;
    final int millis = value.length > 6 ? ((_int(value[6]) ?? 0) ~/ 1000000) : 0;
    return DateTime(year, month, day, hour, minute, second, millis);
  }
  return null;
}

String formatMailDate(DateTime? date, {bool includeTime = true}) {
  if (date == null) {
    return '—';
  }
  if (includeTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal());
  }
  return DateFormat('dd MMM yyyy').format(date.toLocal());
}

String formatMailDateShort(DateTime? date) {
  if (date == null) {
    return '—';
  }
  return DateFormat('dd MMM yyyy').format(date.toLocal());
}

String formatMailTime(DateTime? date) {
  if (date == null) {
    return '';
  }
  return DateFormat('hh:mm:ss a').format(date.toLocal());
}

String formatMailDatePicker(DateTime? date) {
  if (date == null) {
    return '';
  }
  return DateFormat('dd/MM/yyyy').format(date.toLocal());
}

List<MailMessage> _parseMessages(
  dynamic data,
  MailMessage? Function(Map<String, dynamic> json) mapper,
) {
  final List<MailMessage> out = <MailMessage>[];
  for (final Map<String, dynamic> json in _maps(data)) {
    final MailMessage? message = mapper(json);
    if (message != null) {
      out.add(message);
    }
  }
  return out;
}

MailMessage? _inboxMessage(Map<String, dynamic> json) {
  final int mailId = _int(json['mailId']) ?? _int(json['id']) ?? 0;
  if (mailId == 0 && _display(json['subject']).isEmpty) {
    return null;
  }
  final int id = _int(json['id']) ?? mailId;
  return MailMessage(
    id: id,
    mailId: mailId,
    subject: _display(json['subject']),
    body: _display(json['body']),
    senderEmail: _display(json['senderEmail'] ?? json['emailId']),
    senderId: _display(json['senderId']),
    recipientEmail: _display(json['emailId']),
    read: _bool(json['read']),
    starred: _bool(json['starred']),
    draft: _bool(json['draft']),
    deleted: _bool(json['deleted']),
    referenceId: _display(json['referenceId']),
    category: _display(json['category']),
    priority: _display(json['priority']).isEmpty
        ? 'NORMAL'
        : _display(json['priority']),
    requiredResponse: _bool(json['requiredResponse']),
    targetResponseDate: parseMailDateTime(
      json['targetResponseDate'] ?? json['responseDate'],
    ),
    tags: _stringList(json['tags']),
    attachments: _attachments(json['attachments'], json['attachment']),
    to: _stringList(json['to']),
    cc: _stringList(json['cc']),
    bcc: _stringList(json['bcc']),
    status: _display(json['status']).isEmpty ? 'Open' : _display(json['status']),
    createdAt: parseMailDateTime(json['createdAt']),
    sentAt: parseMailDateTime(json['sentAt']),
    threadId: _int(json['threadId']),
    threadCount: _int(json['threadCount'] ?? json['mailAction']),
  );
}

MailMessage? _draftMessage(Map<String, dynamic> json) {
  final int mailId = _int(json['id']) ?? _int(json['mailId']) ?? 0;
  if (mailId == 0) {
    return null;
  }
  return MailMessage(
    id: mailId,
    mailId: mailId,
    subject: _display(json['subject']),
    body: _display(json['body']),
    senderEmail: _display(json['senderEmail']),
    senderId: _display(json['senderId']),
    recipientEmail: '',
    read: true,
    starred: _bool(json['starred']),
    draft: true,
    deleted: false,
    referenceId: _display(json['referenceId']),
    category: _display(json['category']),
    priority: _display(json['priority']).isEmpty
        ? 'NORMAL'
        : _display(json['priority']),
    requiredResponse: _bool(json['requiredResponse']),
    targetResponseDate: parseMailDateTime(
      json['targetResponseDate'] ?? json['responseDate'],
    ),
    tags: _stringList(json['tags']),
    attachments: _attachments(json['attachments'], json['attachment']),
    to: _stringList(json['to']),
    cc: _stringList(json['cc']),
    bcc: _stringList(json['bcc']),
    status: _display(json['status']).isEmpty ? 'DRAFT' : _display(json['status']),
    createdAt: parseMailDateTime(json['createdAt']),
    sentAt: parseMailDateTime(json['sentAt']),
    threadId: _int(json['threadId']),
    threadCount: null,
  );
}

MailMessage? _sentMessage(Map<String, dynamic> json) {
  final int mailId = _int(json['id']) ?? _int(json['mailId']) ?? 0;
  if (mailId == 0 && _display(json['subject']).isEmpty) {
    return null;
  }
  return MailMessage(
    id: mailId,
    mailId: mailId,
    subject: _display(json['subject']),
    body: _display(json['body']),
    senderEmail: _display(json['senderEmail']),
    senderId: _display(json['senderId']),
    recipientEmail: '',
    read: true,
    starred: _bool(json['starred']),
    draft: false,
    deleted: false,
    referenceId: _display(json['referenceId']),
    category: _display(json['category']),
    priority: _display(json['priority']).isEmpty
        ? 'NORMAL'
        : _display(json['priority']),
    requiredResponse: _bool(json['requiredResponse']),
    targetResponseDate: parseMailDateTime(
      json['targetResponseDate'] ?? json['responseDate'],
    ),
    tags: _stringList(json['tags']),
    attachments: _attachments(json['attachments'], json['attachment']),
    to: _stringList(json['to']),
    cc: _stringList(json['cc']),
    bcc: _stringList(json['bcc']),
    status: _display(json['status']).isEmpty ? 'SENT' : _display(json['status']),
    createdAt: parseMailDateTime(json['createdAt']),
    sentAt: parseMailDateTime(json['sentAt'] ?? json['createdAt']),
    threadId: _int(json['threadId']),
    threadCount: null,
  );
}

MailMessage? _trashMessage(Map<String, dynamic> json) {
  final MailMessage? base = _sentMessage(json);
  if (base == null) {
    return _inboxMessage(json)?.copyWith();
  }
  return MailMessage(
    id: base.id,
    mailId: base.mailId,
    subject: base.subject,
    body: base.body,
    senderEmail: base.senderEmail,
    senderId: base.senderId,
    recipientEmail: base.recipientEmail,
    read: base.read,
    starred: base.starred,
    draft: base.draft,
    deleted: true,
    referenceId: base.referenceId,
    category: base.category,
    priority: base.priority,
    requiredResponse: base.requiredResponse,
    targetResponseDate: parseMailDateTime(
      json['targetResponseDate'] ?? json['responseDate'],
    ) ?? base.targetResponseDate,
    tags: base.tags,
    attachments: base.attachments,
    to: base.to.isNotEmpty ? base.to : _stringList(json['to']),
    cc: base.cc.isNotEmpty ? base.cc : _stringList(json['cc']),
    bcc: base.bcc.isNotEmpty ? base.bcc : _stringList(json['bcc']),
    status: base.status,
    createdAt: base.createdAt,
    sentAt: base.sentAt,
    threadId: base.threadId,
    threadCount: base.threadCount,
  );
}

MailMessage? _starredMessage(Map<String, dynamic> json) {
  final MailMessage? inbox = _inboxMessage(json);
  if (inbox != null) {
    return inbox.copyWith(starred: true);
  }
  final MailMessage? sent = _sentMessage(json);
  if (sent != null) {
    return sent.copyWith(starred: true);
  }
  return null;
}

List<MailAttachmentRef> _attachments(dynamic listValue, dynamic flag) {
  if (listValue is List && listValue.isNotEmpty) {
    final List<MailAttachmentRef> out = <MailAttachmentRef>[];
    for (final dynamic item in listValue) {
      if (item is Map) {
        final String name = _display(
          item['name'] ?? item['fileName'] ?? item['title'],
        );
        if (name.isNotEmpty) {
          out.add(MailAttachmentRef(name: name));
        }
      } else {
        final String name = item.toString().trim();
        if (name.isNotEmpty) {
          out.add(MailAttachmentRef(name: name));
        }
      }
    }
    if (out.isNotEmpty) {
      return out;
    }
  }
  if (_bool(flag)) {
    return const <MailAttachmentRef>[MailAttachmentRef(name: 'Attachment')];
  }
  return const <MailAttachmentRef>[];
}

List<String> _stringList(dynamic value) {
  if (value == null) {
    return const <String>[];
  }
  if (value is List) {
    return value
        .map((dynamic e) => e.toString().trim())
        .where((String s) => s.isNotEmpty)
        .toList(growable: false);
  }
  final String single = value.toString().trim();
  if (single.isEmpty) {
    return const <String>[];
  }
  return single
      .split(RegExp(r'[,;]'))
      .map((String s) => s.trim())
      .where((String s) => s.isNotEmpty)
      .toList(growable: false);
}

bool _bool(dynamic value) {
  if (value == null) {
    return false;
  }
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final String text = value.toString().trim().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}

Iterable<Map<String, dynamic>> _maps(dynamic data) sync* {
  final dynamic list =
      data is Map ? (data['items'] ?? data['data'] ?? data['mails'] ?? data) : data;
  if (list is! List) {
    return;
  }
  for (final dynamic item in list) {
    if (item is Map<String, dynamic>) {
      yield item;
    } else if (item is Map) {
      yield Map<String, dynamic>.from(item);
    }
  }
}

String _display(dynamic value) {
  return _nullableText(value) ?? '';
}

String? _nullableText(dynamic value) {
  if (value == null) {
    return null;
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return text;
}

int? _int(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString().trim());
}

MailDashboardData parseMailDashboard(dynamic data) {
  final Map<String, dynamic> root = data is Map<String, dynamic>
      ? data
      : data is Map
      ? Map<String, dynamic>.from(data)
      : <String, dynamic>{};
  final Map<String, dynamic> summaryMap = root['summary'] is Map
      ? Map<String, dynamic>.from(root['summary'] as Map)
      : <String, dynamic>{};
  final MailDashboardSummary summary = MailDashboardSummary(
    totalMail: _int(summaryMap['totalMail']) ?? 0,
    replyRequired: _int(summaryMap['replyRequired']) ?? 0,
    replied: _int(summaryMap['replied']) ?? 0,
    pendingToReply: _int(summaryMap['pendingToReply']) ?? 0,
    pendingWithOthers: _int(summaryMap['pendingWithOthers']) ?? 0,
    overdueMails: _int(summaryMap['overdueMails']) ?? 0,
  );
  final List<MailCorrespondenceRow> rows = <MailCorrespondenceRow>[];
  for (final Map<String, dynamic> json in _maps(root['rows'] ?? root)) {
    final int id = _int(json['id']) ?? _int(json['mailId']) ?? 0;
    if (id == 0 && _display(json['mailNo']).isEmpty) {
      continue;
    }
    rows.add(
      MailCorrespondenceRow(
        id: id,
        mailId: _int(json['mailId']) ?? id,
        contract: _display(json['contract']),
        contractor: _display(json['contractor']),
        mailNo: _display(json['mailNo']),
        reference: _display(json['reference']),
        date: _display(json['date']),
        replyRequired: _display(json['replyRequired']),
        dueDate: _dash(_display(json['dueDate'])),
        person: _display(json['person']),
        replied: _dash(_display(json['replied'])),
        replyMailNo: _dash(_display(json['replyMailNo'])),
        subject: _display(json['subject']),
        status: _display(json['status']),
        mailType: _display(json['mailType']),
      ),
    );
  }
  return MailDashboardData(summary: summary, rows: rows);
}

List<RepositoryItem> parseRepositoryItems(dynamic data) {
  final List<RepositoryItem> out = <RepositoryItem>[];
  for (final Map<String, dynamic> json in _maps(data)) {
    final int id = _int(json['id']) ?? 0;
    if (id == 0) {
      continue;
    }
    out.add(
      RepositoryItem(
        id: id,
        documentName: _display(json['documentName']),
        fileName: _nullableText(json['fileName']),
        filePath: _nullableText(json['filePath']),
        category: _display(json['category']),
        parentId: _int(json['parentId']),
        isFolder: _bool(json['isFolder']),
        fileSize: _int(json['fileSize']),
        mimeType: _nullableText(json['mimeType']),
      ),
    );
  }
  return out;
}

RepositoryItem? parseRepositoryItem(dynamic data) {
  if (data is! Map) {
    return null;
  }
  final List<RepositoryItem> items = parseRepositoryItems(<dynamic>[data]);
  return items.isEmpty ? null : items.first;
}

String _dash(String value) {
  if (value.isEmpty || value == '—') {
    return '—';
  }
  return value;
}
