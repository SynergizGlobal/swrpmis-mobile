import 'dart:async' show Completer;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/quality_rfi_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/quality_rfi_form.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/quality_rfi_form_page.dart';

class _FakeSource extends QualityRfiRemoteDataSource {
  _FakeSource({
    this.throwOnBootstrap = false,
    this.projects = const <QualityRfiOption>[
      QualityRfiOption(id: 'P04', label: 'Project 4'),
    ],
    Completer<void>? projectsGate,
  })  : projectsGate = projectsGate ?? (Completer<void>()..complete()),
        super(Dio());

  final bool throwOnBootstrap;
  final List<QualityRfiOption> projects;
  final Completer<void> projectsGate;

  @override
  Future<List<QualityRfiOption>> fetchProjects() async {
    await projectsGate.future;
    if (throwOnBootstrap) {
      throw Exception('projects failed');
    }
    return projects;
  }

  @override
  Future<List<QualityRfiOption>> fetchDescriptions() async {
    if (throwOnBootstrap) {
      throw Exception('descriptions failed');
    }
    return const <QualityRfiOption>[
      QualityRfiOption(id: '21', label: 'Blanketing'),
    ];
  }

  @override
  Future<List<QualityRfiOption>> fetchContracts(String projectId) async =>
      const <QualityRfiOption>[
        QualityRfiOption(id: 'C1', label: 'Contract 1'),
      ];

  @override
  Future<List<QualityRfiOption>> fetchStructureTypes(String contractId) async =>
      const <QualityRfiOption>[
        QualityRfiOption(id: 'Minor Bridge', label: 'Minor Bridge'),
      ];

  @override
  Future<List<QualityRfiOption>> fetchStructures({
    required String contractId,
    required String structureType,
  }) async =>
      const <QualityRfiOption>[
        QualityRfiOption(id: '7370', label: '22 DN'),
      ];

  @override
  Future<List<QualityRfiOption>> fetchRepresentatives(String contractId) async =>
      const <QualityRfiOption>[
        QualityRfiOption(id: 'U1', label: 'Rep'),
      ];

  @override
  Future<List<QualityRfiOption>> fetchEnclosures(
    List<String> rfiDescriptionLabels,
  ) async =>
      const <QualityRfiOption>[];

  @override
  Future<QualityRfiDetail> fetchDetail(int id) async {
    if (throwOnBootstrap) {
      throw Exception('detail failed');
    }
    return const QualityRfiDetail(
      id: 1,
      rfiId: 'RFI_1',
      project: 'P04',
      contract: 'C1',
      structureType: 'Minor Bridge',
      structure: '7370',
      structureId: '7370',
      action: 'Create',
      typeOfRfi: 'Spot RFI',
      userIdOfRepresentative: 'U1',
      nameOfRepresentative: 'Rep',
      dateOfSubmission: '2026-11-18',
      dateOfInspection: '2026-11-18',
      timeOfInspection: '13:30',
      rfiDescriptionList: <String>['21'],
      enclosuresList: <String>[],
      description: 'x',
      status: 'CREATED',
    );
  }
}

Widget _app(Widget home, {_FakeSource? source}) {
  return ProviderScope(
    overrides: <Override>[
      qualityRfiRemoteDataSourceProvider.overrideWithValue(
        source ?? _FakeSource(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: home,
    ),
  );
}

List<FlutterErrorDetails> _captureDropdownAsserts() {
  final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
  final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    errors.add(details);
    previous?.call(details);
  };
  addTearDown(() => FlutterError.onError = previous);
  return errors;
}

bool _hasDropdownAssert(List<FlutterErrorDetails> errors) {
  return errors.any(
    (FlutterErrorDetails e) => e.exceptionAsString().contains(
          'There should be exactly one item with [DropdownButton]',
        ),
  );
}

void main() {
  testWidgets('create mode shows form fields after seed load', (
    WidgetTester tester,
  ) async {
    final List<FlutterErrorDetails> errors = _captureDropdownAsserts();
    await tester.pumpWidget(_app(const QualityRfiFormPage()));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Quality/Safety RFI'), findsOneWidget);
    expect(find.textContaining('Project'), findsWidgets);
    expect(find.text('Create'), findsWidgets);
    expect(_hasDropdownAssert(errors), isFalse);
  });

  testWidgets('create mode shows loader while seed pending', (
    WidgetTester tester,
  ) async {
    final Completer<void> gate = Completer<void>();
    await tester.pumpWidget(
      _app(
        const QualityRfiFormPage(),
        source: _FakeSource(projectsGate: gate),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('Project'), findsNothing);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('Project'), findsWidgets);
  });

  testWidgets('create mode shows retry when seed APIs fail', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const QualityRfiFormPage(),
        source: _FakeSource(throwOnBootstrap: true),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('failed'), findsOneWidget);
    expect(find.textContaining('Project'), findsNothing);
  });

  testWidgets('create survives empty-id seed noise without blanking', (
    WidgetTester tester,
  ) async {
    final List<FlutterErrorDetails> errors = _captureDropdownAsserts();
    await tester.pumpWidget(
      _app(
        const QualityRfiFormPage(),
        source: _FakeSource(
          projects: const <QualityRfiOption>[
            QualityRfiOption(id: '', label: 'Bad A'),
            QualityRfiOption(id: '', label: 'Bad B'),
            QualityRfiOption(id: 'P04', label: 'Project 4'),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.textContaining('Project'), findsWidgets);
    expect(find.text('Create'), findsWidgets);
    expect(_hasDropdownAssert(errors), isFalse);
  });

  testWidgets('edit mode shows form after detail load', (
    WidgetTester tester,
  ) async {
    final List<FlutterErrorDetails> errors = _captureDropdownAsserts();
    await tester.pumpWidget(
      _app(const QualityRfiFormPage(rfiId: 1, rfiCode: 'RFI_1')),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.textContaining('Edit Quality/Safety RFI'), findsOneWidget);
    expect(find.textContaining('Project'), findsWidgets);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(_hasDropdownAssert(errors), isFalse);
  });

  testWidgets('edit mode shows retry when detail load fails', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const QualityRfiFormPage(rfiId: 1, rfiCode: 'RFI_1'),
        source: _FakeSource(throwOnBootstrap: true),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('failed'), findsOneWidget);
  });
}
