import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/features/mail/data/datasources/mail_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_compose.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_dashboard.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/pages/mail_compose_page.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/pages/mail_module_page.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/providers/mail_providers.dart';

class _FakeMailDs extends MailRemoteDataSource {
  _FakeMailDs() : super(Dio());

  MailComposePayload? lastPayload;
  bool sendCalled = false;
  int? lastSendDraftId;

  @override
  Future<String> generateReference() async => '#MAIL-TEST-1';

  @override
  Future<List<MailComposeProject>> fetchComposeProjects() async =>
      const <MailComposeProject>[
        MailComposeProject(projectId: 'P03', projectName: 'Project Three'),
      ];

  @override
  Future<List<MailComposeContract>> fetchComposeContracts(
    String projectId,
  ) async =>
      const <MailComposeContract>[
        MailComposeContract(
          contractId: 'P03CN01',
          contractShortName: 'BGK-KUD New Line: Yadwad–Jamkhandi',
          contractName: 'Contract One',
        ),
      ];

  @override
  Future<List<MailRecipient>> fetchRecipientsByContract(
    String contractShortName,
  ) async =>
      const <MailRecipient>[
        MailRecipient(
          emailId: 'user1@gmail.com',
          userId: 'PMIS_RU_001',
          username: 'User One',
        ),
      ];

  @override
  Future<List<MailRecipient>> searchRecipients(String query) async =>
      const <MailRecipient>[];

  @override
  Future<List<MailMessage>> fetchDrafts() async => const <MailMessage>[];

  @override
  Future<List<MailMessage>> fetchSent() async => const <MailMessage>[];

  @override
  Future<List<MailMessage>> fetchInbox() async => const <MailMessage>[];

  @override
  Future<List<MailMessage>> fetchTrash() async => const <MailMessage>[];

  @override
  Future<List<MailMessage>> fetchStarred() async => const <MailMessage>[];

  @override
  Future<List<MailLabel>> fetchLabels() async => const <MailLabel>[];

  @override
  Future<MailDashboardData> fetchDashboard() async =>
      const MailDashboardData(
        summary: MailDashboardSummary(
          totalMail: 0,
          replyRequired: 0,
          replied: 0,
          pendingToReply: 0,
          pendingWithOthers: 0,
          overdueMails: 0,
        ),
        rows: <MailCorrespondenceRow>[],
      );

  @override
  Future<String> sendMail({
    required MailComposePayload payload,
    List<MailComposeAttachment> files = const <MailComposeAttachment>[],
    int? draftId,
  }) async {
    sendCalled = true;
    lastPayload = payload;
    lastSendDraftId = draftId;
    return 'Mail sent successfully';
  }

  @override
  Future<MailDraftSaveResult> saveDraft({
    required MailComposePayload payload,
    List<MailComposeAttachment> files = const <MailComposeAttachment>[],
  }) async =>
      const MailDraftSaveResult(draftId: 42, message: 'Draft saved');
}

void main() {
  testWidgets('contract recipient user id is sent in toUserIds', (tester) async {
    final _FakeMailDs fake = _FakeMailDs();
    final GoRouter router = GoRouter(
      initialLocation: MailComposePage.routePath,
      routes: <RouteBase>[
        GoRoute(
          path: MailModulePage.routePath,
          redirect: (_, GoRouterState state) =>
              state.uri.path == MailModulePage.routePath
                  ? MailModulePage.folderPath(MailFolder.dashboard)
                  : null,
          routes: <RouteBase>[
            GoRoute(
              path: 'compose',
              builder: (_, __) => const MailComposePage(),
            ),
            GoRoute(
              path: 'sent',
              builder: (_, __) => const Scaffold(body: Text('SENT_FOLDER')),
            ),
            GoRoute(
              path: 'dashboard',
              builder: (_, __) => const Scaffold(body: Text('DASHBOARD')),
            ),
            GoRoute(
              path: 'drafts',
              builder: (_, __) => const Scaffold(body: Text('DRAFTS_FOLDER')),
            ),
          ],
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(420, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          mailRemoteDataSourceProvider.overrideWithValue(fake),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final Finder projectDropdown = find.byType(DropdownButton<String>).at(0);
    await tester.ensureVisible(projectDropdown);
    await tester.tap(projectDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Project Three').last);
    await tester.pumpAndSettle();

    final Finder contractDropdown = find.byType(DropdownButton<String>).at(1);
    await tester.ensureVisible(contractDropdown);
    await tester.tap(contractDropdown);
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('BGK-KUD New Line: Yadwad–Jamkhandi').last,
    );
    await tester.pumpAndSettle();

    final Finder toField = find
        .byWidgetPredicate((Widget w) {
          return w is TextField &&
              (w.decoration?.hintText?.contains('Enter name or email') ??
                  false);
        })
        .first;
    await tester.ensureVisible(toField);
    await tester.tap(toField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('User One'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Enter subject...'),
      'subj',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Type your message here...'),
      'body text',
    );
    await tester.pump();

    await tester.ensureVisible(find.text('No'));
    await tester.tap(find.text('No'));
    await tester.pump();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Send'));
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(fake.sendCalled, isTrue);
    expect(fake.lastPayload?.toUserIds, contains('PMIS_RU_001'));
    expect(fake.lastPayload?.projectId, 'P03');
    expect(fake.lastPayload?.contractId, 'P03CN01');
    expect(
      fake.lastPayload?.contractShortName,
      'BGK-KUD New Line: Yadwad–Jamkhandi',
    );
    expect(fake.lastPayload?.toJson().containsKey('toUserIds'), isTrue);
    expect(fake.lastPayload?.toJson().containsKey('to'), isFalse);

    final Finder ok = find.text('OK');
    if (ok.evaluate().isNotEmpty) {
      await tester.tap(ok);
      await tester.pumpAndSettle();
    }
    expect(find.text('SENT_FOLDER'), findsOneWidget);
  });
}
