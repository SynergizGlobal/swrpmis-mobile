import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_parse.dart';

void main() {
  test('parseMailDateTime handles array and ISO', () {
    final DateTime? fromArray = parseMailDateTime(<dynamic>[
      2026,
      10,
      14,
      11,
      18,
      35,
      823180000,
    ]);
    expect(fromArray?.year, 2026);
    expect(fromArray?.month, 10);
    expect(fromArray?.day, 14);
    expect(fromArray?.hour, 11);

    final DateTime? fromIso = parseMailDateTime('2026-10-20T15:06:04.415297');
    expect(fromIso?.year, 2026);
    expect(fromIso?.month, 10);
    expect(fromIso?.day, 20);
  });

  test('parseMailDateTime date-only array', () {
    final DateTime? date = parseMailDateTime(<dynamic>[2026, 10, 23]);
    expect(date?.year, 2026);
    expect(date?.month, 10);
    expect(date?.day, 23);
    expect(date?.hour, 0);
  });

  test('inbox draft sent parsers', () {
    final List<MailMessage> inbox = parseMailInboxList(<dynamic>[
      <String, dynamic>{
        'id': 571,
        'mailId': 326,
        'emailId': 'aman.thakur@synergizglobal.com',
        'read': false,
        'subject': 'test correspondence letterno',
        'body': 'lettter testing',
        'senderEmail': 'aman.thakur@synergizglobal.com',
        'createdAt': <dynamic>[2026, 10, 14, 11, 18, 35, 823180000],
        'referenceId': '#MAIL-2026-00265',
        'category': 'Inspection',
        'priority': 'NORMAL',
        'tags': <String>['FollowUp'],
      },
    ]);
    expect(inbox, hasLength(1));
    expect(inbox.single.mailId, 326);
    expect(inbox.single.read, isFalse);
    expect(inbox.single.tags, <String>['FollowUp']);

    final List<MailMessage> drafts = parseMailDraftList(<dynamic>[
      <String, dynamic>{
        'id': 296,
        'subject': 'Review Required',
        'body': 'Testing Mail',
        'draft': true,
        'createdAt': <dynamic>[2026, 10, 6, 15, 47, 9, 168723000],
        'referenceId': '#MAIL-2026-00240',
        'category': 'Inspection',
        'requiredResponse': true,
        'targetResponseDate': <dynamic>[2026, 10, 15],
        'priority': 'NORMAL',
      },
    ]);
    expect(drafts.single.draft, isTrue);
    expect(drafts.single.mailId, 296);
    expect(drafts.single.targetResponseDate?.day, 15);

    final List<MailMessage> sent = parseMailSentList(<dynamic>[
      <String, dynamic>{
        'id': 328,
        'subject': 'RDSO Drawing',
        'body': 'testing message',
        'status': 'SENT',
        'createdAt': '2026-10-20T15:06:04.415297',
        'sentAt': '2026-10-20T15:06:04.415302',
        'to': <String>['saltaf.h@synergizglobal.com'],
        'attachment': false,
      },
    ]);
    expect(sent.single.status, 'SENT');
    expect(sent.single.to, <String>['saltaf.h@synergizglobal.com']);
    expect(sent.single.sentAt, isNotNull);
  });

  test('labels parse', () {
    final List<MailLabel> labels = parseMailLabels(<dynamic>[
      <String, dynamic>{'id': 1, 'name': 'development', 'color': '#2563EB'},
    ]);
    expect(labels.single.name, 'development');
    expect(labels.single.colorHex, '#2563EB');
  });
}
