import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/mail/data/datasources/mail_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_compose.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_dashboard.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/pages/mail_compose_page.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/providers/mail_providers.dart';

class _FakeMailDs extends MailRemoteDataSource {
  _FakeMailDs() : super(Dio());

  bool sendCalled = false;
  MailComposePayload? lastPayload;

  @override
  Future<String> generateReference() async => '#MAIL-TEST-1';

  @override
  Future<List<MailRecipient>> searchRecipients(String query) async {
    if (query.contains('altaf')) {
      return const [
        MailRecipient(
          emailId: 'saltaf.h@synergizglobal.com',
          userId: 'PMIS_CO_036',
          username: 'altaf con',
        ),
      ];
    }
    return const [];
  }

  @override
  Future<List<MailMessage>> fetchDrafts() async => const [];

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
  }) async => 'Draft saved successfully';

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
  Future<List<MailMessage>> fetchInbox() async => const [];
  @override
  Future<List<MailMessage>> fetchSent() async => const [];
  @override
  Future<List<MailMessage>> fetchTrash() async => const [];
  @override
  Future<List<MailMessage>> fetchStarred() async => const [];
  @override
  Future<List<MailLabel>> fetchLabels() async => const [];
}

void main() {
  testWidgets('reference reflects after generateReference', (tester) async {
    final fake = _FakeMailDs();
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [mailRemoteDataSourceProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: MailComposePage()),
      ),
    );
    await tester.pump(); // post-frame scheduled
    await tester.pump(const Duration(milliseconds: 50)); // reference future

    expect(find.text('Compose Mail'), findsOneWidget);
    expect(find.text('#MAIL-TEST-1'), findsOneWidget);
  });

  testWidgets('selecting search result reflects as chip', (tester) async {
    final fake = _FakeMailDs();
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [mailRemoteDataSourceProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: MailComposePage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final toFields = find.byType(TextField);
    // First TextField inside first recipient (To) - find by hint via ancestor InputDecorator label To *
    // Enter into the To query field: it's the TextField with hint Search users...
    await tester.enterText(find.byWidgetPredicate((w) {
      return w is TextField && (w.decoration?.hintText?.contains('Search users') ?? false);
    }).first, 'altaf');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // debounce
    await tester.pump(const Duration(milliseconds: 50)); // search future

    expect(find.text('altaf con'), findsOneWidget);
    await tester.tap(find.text('altaf con'));
    await tester.pump();

    expect(find.widgetWithText(InputChip, 'saltaf.h@synergizglobal.com'), findsOneWidget);
  });
}
