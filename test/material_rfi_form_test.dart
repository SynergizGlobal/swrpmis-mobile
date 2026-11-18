import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/material_rfi_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/material_rfi_form.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/material_rfi_form_page.dart';

class _FakeMaterialRfiRemoteDataSource extends MaterialRfiRemoteDataSource {
  _FakeMaterialRfiRemoteDataSource({
    this.types = const <MaterialRfiOption>[
      MaterialRfiOption(id: 'Spot RFI', label: 'Spot RFI'),
      MaterialRfiOption(id: 'Regular RFI', label: 'Regular RFI'),
    ],
    this.throwOnBootstrap = false,
  }) : super(Dio());

  final List<MaterialRfiOption> types;
  final bool throwOnBootstrap;

  @override
  Future<List<MaterialRfiOption>> fetchProjects() async {
    if (throwOnBootstrap) {
      throw Exception('projects failed');
    }
    return const <MaterialRfiOption>[
      MaterialRfiOption(id: 'P01', label: 'Project One'),
    ];
  }

  @override
  Future<List<MaterialRfiOption>> fetchInspectionItems() async {
    if (throwOnBootstrap) {
      throw Exception('items failed');
    }
    return const <MaterialRfiOption>[
      MaterialRfiOption(id: '12', label: 'Rails'),
    ];
  }

  @override
  Future<List<MaterialRfiOption>> fetchInspectionTypes() async {
    if (throwOnBootstrap) {
      throw Exception('types failed');
    }
    return types;
  }

  @override
  Future<List<MaterialRfiOption>> fetchContracts(String projectId) async =>
      const <MaterialRfiOption>[];

  @override
  Future<List<MaterialRfiMaterial>> fetchMaterials(int itemId) async =>
      const <MaterialRfiMaterial>[];

  @override
  Future<List<MaterialRfiOption>> fetchRepresentatives(
    String contractId,
  ) async =>
      const <MaterialRfiOption>[];

  @override
  Future<List<MaterialRfiOption>> fetchDescriptions(int materialId) async =>
      const <MaterialRfiOption>[];

  @override
  Future<List<MaterialRfiOption>> fetchEnclosures(
    List<String> rfiDescriptionLabels,
  ) async =>
      const <MaterialRfiOption>[];
}

Widget _app(Widget home, {_FakeMaterialRfiRemoteDataSource? source}) {
  return ProviderScope(
    overrides: <Override>[
      materialRfiRemoteDataSourceProvider.overrideWithValue(
        source ?? _FakeMaterialRfiRemoteDataSource(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: home,
    ),
  );
}

void main() {
  group('material RFI parsers', () {
    test('drops empty/duplicate ids and unwraps nested lists', () {
      expect(
        parseMaterialRfiProjects(<String, dynamic>{
          'data': <dynamic>[
            <String, dynamic>{'projectId': '', 'projectName': 'Bad'},
            <String, dynamic>{'projectId': 'P01', 'projectName': 'One'},
            <String, dynamic>{'projectId': 'P01', 'projectName': 'Dup'},
            <String, dynamic>{'projectId': 'P02', 'projectName': 'Two'},
          ],
        }).map((MaterialRfiOption o) => o.id),
        <String>['P01', 'P02'],
      );

      expect(
        parseMaterialRfiInspectionItems(<dynamic>[
          <String, dynamic>{'itemId': null, 'itemName': 'Missing'},
          <String, dynamic>{'itemId': 4, 'itemName': 'Sleepers'},
          <String, dynamic>{'itemId': 4, 'itemName': 'Dup'},
        ]).map((MaterialRfiOption o) => o.id),
        <String>['4'],
      );

      expect(
        parseMaterialRfiInspectionTypes(<dynamic>[
          <String, dynamic>{'type': null},
          <String, dynamic>{'type': ''},
          <String, dynamic>{'type': 'Spot RFI'},
          <String, dynamic>{'type': 'Spot RFI'},
          <String, dynamic>{'type': 'Regular RFI'},
        ]).map((MaterialRfiOption o) => o.id),
        <String>['Spot RFI', 'Regular RFI'],
      );
    });

    test('empty seed values would otherwise crash DropdownButtonFormField', () {
      final List<MaterialRfiOption> types = parseMaterialRfiInspectionTypes(
        <dynamic>[
          <String, dynamic>{'type': null},
          <String, dynamic>{'type': ''},
          <String, dynamic>{'type': null},
        ],
      );
      expect(types, isEmpty);
      const String selected = '';
      final bool hasValue =
          selected.isNotEmpty && types.any((MaterialRfiOption o) => o.id == selected);
      expect(hasValue, isFalse);
    });
  });

  group('MaterialRfiFormPage add', () {
    testWidgets('shows create form after seed load', (WidgetTester tester) async {
      final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        errors.add(details);
        previous?.call(details);
      };
      addTearDown(() => FlutterError.onError = previous);

      await tester.binding.setSurfaceSize(const Size(392, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_app(const MaterialRfiFormPage()));
      await tester.pump(); // post-frame bootstrap scheduled
      await tester.pump(); // bootstrap futures complete

      expect(find.text('Material RFI'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
      expect(find.text('Create'), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        errors.where(
          (FlutterErrorDetails e) =>
              e.exceptionAsString().contains('DropdownButton') ||
              e.exceptionAsString().contains('Duplicate keys'),
        ),
        isEmpty,
      );
    });

    testWidgets('shows retry when seed APIs fail', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(392, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _app(
          const MaterialRfiFormPage(),
          source: _FakeMaterialRfiRemoteDataSource(throwOnBootstrap: true),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Retry'), findsOneWidget);
      expect(find.textContaining('failed'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    });

    testWidgets('survives empty-id seed noise without blanking', (
      WidgetTester tester,
    ) async {
      final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        errors.add(details);
        previous?.call(details);
      };
      addTearDown(() => FlutterError.onError = previous);

      await tester.binding.setSurfaceSize(const Size(392, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Simulate what an unfiltered parser used to feed the dropdowns.
      await tester.pumpWidget(
        _app(
          const MaterialRfiFormPage(),
          source: _FakeMaterialRfiRemoteDataSource(
            types: const <MaterialRfiOption>[
              MaterialRfiOption(id: '', label: 'Bad A'),
              MaterialRfiOption(id: '', label: 'Bad B'),
              MaterialRfiOption(id: 'Spot RFI', label: 'Spot RFI'),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
      expect(find.text('Create'), findsWidgets);
      expect(
        errors.where(
          (FlutterErrorDetails e) =>
              e.exceptionAsString().contains('DropdownButton') ||
              e.exceptionAsString().contains('Duplicate keys'),
        ),
        isEmpty,
      );
    });
  });
}
