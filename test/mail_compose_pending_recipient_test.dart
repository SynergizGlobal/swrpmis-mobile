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

  @override
  Future<String> generateReference() async => '#MAIL-TEST-1';

  @override
  Future<List<MailRecipient>> searchRecipients(String query) async => const [];

  @override
  Future<List<MailMessage>> fetchDrafts() async => const [];

  @override
  Future<List<MailMessage>> fetchSent() async => const [];

  @override
  Future<List<MailMessage>> fetchInbox() async => const [];

  @override
  Future<List<MailMessage>> fetchTrash() async => const [];

  @override
  Future<List<MailMessage>> fetchStarred() async => const [];

  @override
  Future<List<MailLabel>> fetchLabels() async => const [];

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
        rows: [],
      );

  @override
  Future<String> sendMail({
    required MailComposePayload payload,
    List<MailComposeAttachment> files = const [],
  }) async {
    sendCalled = true;
    lastPayload = payload;
    return 'Mail sent successfully';
  }

  @override
  Future<String> saveDraft({
    required MailComposePayload payload,
    List<MailComposeAttachment> files = const [],
  }) async => 'Draft saved';
}

void main() {
  testWidgets('typed To email is committed on Send without pressing +', (tester) async {
    final fake = _FakeMailDs();
    final GoRouter router = GoRouter(
      initialLocation: MailComposePage.routePath,
      routes: <RouteBase>[
        GoRoute(
          path: MailModulePage.routePath,
          redirect: (_, state) =>
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

    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [mailRemoteDataSourceProvider.overrideWithValue(fake)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Type email into To without committing via + / Enter.
    await tester.enterText(
      find.byWidgetPredicate((w) {
        return w is TextField &&
            (w.decoration?.hintText?.contains('Search users') ?? false);
      }).first,
      'user1@gmail.com',
    );
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextField, 'Enter subject...'),
      'subj',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Type your message here...'),
      'body text',
    );
    await tester.pump();

    // Required response defaults to Yes — switch to No to skip date.
    await tester.ensureVisible(find.widgetWithText(RadioListTile<bool>, 'No'));
    await tester.tap(find.widgetWithText(RadioListTile<bool>, 'No'));
    await tester.pump();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Send'));
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pump(); // start send
    await tester.pump(const Duration(milliseconds: 50));

    expect(fake.sendCalled, isTrue, reason: 'pending typed To must bind before send');
    expect(fake.lastPayload?.to, contains('user1@gmail.com'));

    // Dismiss success dialog
    final ok = find.text('OK');
    if (ok.evaluate().isNotEmpty) {
      await tester.tap(ok);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('SENT_FOLDER'), findsOneWidget);
  });
}
