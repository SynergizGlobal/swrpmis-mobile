import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/features/mail/data/datasources/mail_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_compose.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_dashboard.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/pages/mail_compose_page.dart';

class _FakeMailDs extends MailRemoteDataSource {
  _FakeMailDs() : super(Dio());

  bool sendCalled = false;
  MailComposePayload? lastPayload;

  @override
  Future<String> generateReference() async => '#MAIL-TEST-1';

  @override
  Future<List<MailComposeProject>> fetchComposeProjects() async =>
      const <MailComposeProject>[
        MailComposeProject(
          projectId: 'P03',
          projectName: 'Bagalkot—Kudachi New Railway Line',
        ),
      ];

  @override
  Future<List<MailComposeContract>> fetchComposeContracts(
    String projectId,
  ) async =>
      const <MailComposeContract>[
        MailComposeContract(
          contractId: 'P03CN01',
          contractShortName: 'BGK-KUD New Line: Yadwad–Jamkhandi',
          contractName: 'Construction of New Broad Gauge Railway Line',
        ),
      ];

  @override
  Future<List<MailRecipient>> fetchRecipientsByContract(
    String contractShortName,
  ) async =>
      const <MailRecipient>[
        MailRecipient(
          emailId: 'saltaf.h@synergizglobal.com',
          userId: 'PMIS_CO_036',
          username: 'altaf con',
        ),
      ];

  @override
  Future<List<MailRecipient>> searchRecipients(String query) async {
    if (query.contains('altaf')) {
      return const <MailRecipient>[
        MailRecipient(
          emailId: 'saltaf.h@synergizglobal.com',
          userId: 'PMIS_CO_036',
          username: 'altaf con',
        ),
      ];
    }
    return const <MailRecipient>[];
  }

  @override
  Future<List<MailMessage>> fetchDrafts() async => const <MailMessage>[];

  @override
  Future<String> sendMail({
    required MailComposePayload payload,
    List<MailComposeAttachment> files = const <MailComposeAttachment>[],
    int? draftId,
  }) async {
    sendCalled = true;
    lastPayload = payload;
    return 'Mail sent successfully';
  }

  @override
  Future<MailDraftSaveResult> saveDraft({
    required MailComposePayload payload,
    List<MailComposeAttachment> files = const <MailComposeAttachment>[],
  }) async =>
      const MailDraftSaveResult(
        draftId: 99,
        message: 'Draft saved successfully',
      );

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
  Future<List<MailMessage>> fetchInbox() async => const <MailMessage>[];
  @override
  Future<List<MailMessage>> fetchSent() async => const <MailMessage>[];
  @override
  Future<List<MailMessage>> fetchTrash() async => const <MailMessage>[];
  @override
  Future<List<MailMessage>> fetchStarred() async => const <MailMessage>[];
  @override
  Future<List<MailLabel>> fetchLabels() async => const <MailLabel>[];
}

Widget _composeApp(Widget home) {
  return ProviderScope(
    overrides: <Override>[
      mailRemoteDataSourceProvider.overrideWithValue(_FakeMailDs()),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: home,
    ),
  );
}

void main() {
  testWidgets('compose body paints fields under AppTheme (no layout crash)', (
    tester,
  ) async {
    final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
    final void Function(FlutterErrorDetails)? old = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      errors.add(details);
      old?.call(details);
    };
    addTearDown(() => FlutterError.onError = old);

    await tester.binding.setSurfaceSize(const Size(392, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_composeApp(const MailComposePage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      errors.where(
        (FlutterErrorDetails e) => e.exceptionAsString().contains(
              'BoxConstraints forces an infinite width',
            ),
      ),
      isEmpty,
      reason: 'FilledButton in Row must hug width under AppTheme',
    );
    expect(find.text('Compose Mail'), findsOneWidget);
    expect(find.text('Project *'), findsOneWidget);
    expect(find.text('Contract *'), findsOneWidget);
    expect(find.text('To *'), findsOneWidget);
    expect(find.text('Subject *'), findsOneWidget);
    expect(find.text('Attach File'), findsOneWidget);
    expect(find.text('Add tag'), findsOneWidget);
    expect(find.text('#Urgent'), findsNothing);
    expect(find.text('Save Draft'), findsWidgets);
    expect(find.text('Send'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Send'), findsOneWidget);

    final Finder send = find.widgetWithText(FilledButton, 'Send');
    expect(tester.getRect(send).bottom, lessThanOrEqualTo(800));
  });

  testWidgets('Add tag sheet toggles selected chip onto form', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_composeApp(const MailComposePage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('#Urgent'), findsNothing);
    await tester.ensureVisible(find.text('Add tag'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add tag'));
    await tester.pumpAndSettle();

    expect(find.text('Add tags'), findsOneWidget);
    expect(find.text('#Urgent'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, '#Urgent'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(InputChip, '#Urgent'));
    expect(find.widgetWithText(InputChip, '#Urgent'), findsOneWidget);
    final InputChip chip = tester.widget<InputChip>(
      find.widgetWithText(InputChip, '#Urgent'),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('reference reflects after generateReference', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_composeApp(const MailComposePage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Compose Mail'), findsOneWidget);
    expect(find.text('#MAIL-TEST-1'), findsOneWidget);
  });

  testWidgets('selecting contract recipient reflects as chip', (tester) async {
    final _FakeMailDs fake = _FakeMailDs();
    await tester.binding.setSurfaceSize(const Size(420, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          mailRemoteDataSourceProvider.overrideWithValue(fake),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: const MailComposePage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final Finder projectDropdown = find.byType(DropdownButton<String>).at(0);
    await tester.ensureVisible(projectDropdown);
    await tester.tap(projectDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bagalkot—Kudachi New Railway Line').last);
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

    expect(find.text('altaf con'), findsOneWidget);
    await tester.tap(find.text('altaf con'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(InputChip, 'altaf con'), findsOneWidget);
  });
}
