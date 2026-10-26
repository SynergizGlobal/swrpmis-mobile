import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/work_rfi_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/work_rfi_form.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/work_rfi_form_page.dart';

void main() {
  test('create structure selection builds the components payload', () async {
    final List<RequestOptions> calls = <RequestOptions>[];
    final WorkRfiRemoteDataSource source = WorkRfiRemoteDataSource(
      _scriptedDio(
        calls: calls,
        body: (RequestOptions options) {
          expect(options.path, ApiConstants.activitiesUpdateComponentsPath);
          return <Map<String, dynamic>>[
            <String, dynamic>{'strip_chart_component': 'Blanketing'},
          ];
        },
      ),
    );

    final List<WorkRfiOption> options = await source.fetchComponents(
      contractId: 'C01',
      structureId: '170',
      structureType: 'Minor Bridge',
    );

    expect(calls.single.method, 'POST');
    expect(calls.single.path, ApiConstants.activitiesUpdateComponentsPath);
    expect(_payload(calls.single), <String, dynamic>{
      'contract_id_fk': 'C01',
      'strip_chart_structure_id_fk': '170',
      'structure_type_fk': 'Minor Bridge',
    });
    expect(options.single.id, 'Blanketing');
    expect(options.single.label, 'Blanketing');
    _expectReadOnlyLookups(calls);
  });

  test('component selection builds the component-ids payload', () async {
    final List<RequestOptions> calls = <RequestOptions>[];
    final WorkRfiRemoteDataSource source = WorkRfiRemoteDataSource(
      _scriptedDio(
        calls: calls,
        body: (RequestOptions options) {
          expect(options.path, ApiConstants.activitiesUpdateComponentIdsPath);
          return <Map<String, dynamic>>[
            <String, dynamic>{
              'strip_chart_component_id': 'CH 25400 to CH 26000',
            },
          ];
        },
      ),
    );

    final List<WorkRfiOption> options = await source.fetchElements(
      contractId: 'C01',
      structureId: '170',
      component: 'Blanketing',
      structureType: 'Minor Bridge',
    );

    expect(calls.single.method, 'POST');
    expect(calls.single.path, ApiConstants.activitiesUpdateComponentIdsPath);
    expect(_payload(calls.single), <String, dynamic>{
      'contract_id_fk': 'C01',
      'strip_chart_structure_id_fk': '170',
      'strip_chart_component': 'Blanketing',
      'structure_type_fk': 'Minor Bridge',
    });
    expect(options.single.id, 'CH 25400 to CH 26000');
    expect(options.single.label, 'CH 25400 to CH 26000');
    _expectReadOnlyLookups(calls);
  });

  test('labels parse from component and component-id fields', () {
    expect(
      parseWorkRfiComponents(<Map<String, dynamic>>[
        <String, dynamic>{'strip_chart_component': 'Blanketing'},
      ]).single.label,
      'Blanketing',
    );
    expect(
      parseWorkRfiElements(<Map<String, dynamic>>[
        <String, dynamic>{'strip_chart_component_id': 'CH 25400 to CH 26000'},
      ]).single.label,
      'CH 25400 to CH 26000',
    );
    expect(parseWorkRfiComponents(<dynamic>[]), isEmpty);
    expect(parseWorkRfiElements(<dynamic>[]), isEmpty);
  });

  testWidgets('create form loads components then elements from lookups', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final List<RequestOptions> calls = <RequestOptions>[];
    final WorkRfiRemoteDataSource source = WorkRfiRemoteDataSource(
      _scriptedDio(calls: calls, body: _createFormBody),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          workRfiRemoteDataSourceProvider.overrideWithValue(source),
        ],
        child: const MaterialApp(home: WorkRfiFormPage()),
      ),
    );
    await _until(tester, find.text('Select...'));
    expect(_onTap(tester, WorkRfiFormPage.componentFieldKey), isNull);
    expect(_onTap(tester, WorkRfiFormPage.elementFieldKey), isNull);

    await _pick(
      tester,
      field: 'Select...',
      sheet: 'Project',
      option: 'Project Alpha',
    );
    await _pick(
      tester,
      field: 'Select...',
      sheet: 'Contract',
      option: 'Contract Alpha',
    );
    await _pick(
      tester,
      field: 'Select...',
      sheet: 'Structure Type',
      option: 'Minor Bridge',
    );
    await _pick(
      tester,
      field: WorkRfiFormPage.structureFieldKey,
      sheet: 'Structure',
      option: 'Structure 170',
    );

    final RequestOptions components = _single(
      calls,
      ApiConstants.activitiesUpdateComponentsPath,
    );
    expect(components.method, 'POST');
    expect(_payload(components), <String, dynamic>{
      'contract_id_fk': 'C01',
      'strip_chart_structure_id_fk': '170',
      'structure_type_fk': 'Minor Bridge',
    });
    expect(_onTap(tester, WorkRfiFormPage.componentFieldKey), isNotNull);
    expect(_onTap(tester, WorkRfiFormPage.elementFieldKey), isNull);

    await _pick(
      tester,
      field: WorkRfiFormPage.componentFieldKey,
      sheet: 'Component',
      option: 'Blanketing',
    );
    final RequestOptions elements = _single(
      calls,
      ApiConstants.activitiesUpdateComponentIdsPath,
    );
    expect(elements.method, 'POST');
    expect(_payload(elements), <String, dynamic>{
      'contract_id_fk': 'C01',
      'strip_chart_structure_id_fk': '170',
      'strip_chart_component': 'Blanketing',
      'structure_type_fk': 'Minor Bridge',
    });
    expect(_onTap(tester, WorkRfiFormPage.elementFieldKey), isNotNull);
    await _pick(
      tester,
      field: WorkRfiFormPage.elementFieldKey,
      sheet: 'Element',
      option: 'CH 25400 to CH 26000',
    );
    expect(find.text('CH 25400 to CH 26000'), findsOneWidget);

    await _pick(
      tester,
      field: 'Structure 170',
      sheet: 'Structure',
      option: 'Structure 171',
    );
    expect(find.text('Blanketing'), findsNothing);
    expect(find.text('CH 25400 to CH 26000'), findsNothing);
    expect(find.byKey(WorkRfiFormPage.componentFieldKey), findsOneWidget);
    expect(_onTap(tester, WorkRfiFormPage.elementFieldKey), isNull);
    expect(
      _payload(
        calls
            .where(
              (RequestOptions call) =>
                  call.path == ApiConstants.activitiesUpdateComponentsPath,
            )
            .last,
      )['strip_chart_structure_id_fk'],
      '171',
    );

    await _pick(
      tester,
      field: 'Structure 171',
      sheet: 'Structure',
      option: 'Structure 172',
    );
    await _open(tester, field: WorkRfiFormPage.componentFieldKey, sheet: 'Component');
    expect(find.text('No components'), findsOneWidget);
    Navigator.of(
      tester.element(find.text('No components')),
      rootNavigator: true,
    ).pop();
    await _untilAbsent(tester, find.text('No components'));

    await _pick(
      tester,
      field: 'Minor Bridge',
      sheet: 'Structure Type',
      option: 'Important Bridge',
    );
    expect(find.byKey(WorkRfiFormPage.structureFieldKey), findsOneWidget);
    expect(_onTap(tester, WorkRfiFormPage.componentFieldKey), isNull);
    expect(find.textContaining('Chainage From'), findsNothing);
    _expectReadOnlyLookups(calls);
  });

  testWidgets('earthwork create keeps chainage and layer after structure', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final List<RequestOptions> calls = <RequestOptions>[];
    final WorkRfiRemoteDataSource source = WorkRfiRemoteDataSource(
      _scriptedDio(calls: calls, body: _createFormBody),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          workRfiRemoteDataSourceProvider.overrideWithValue(source),
        ],
        child: const MaterialApp(home: WorkRfiFormPage()),
      ),
    );
    await _until(tester, find.text('Select...'));
    await _pick(
      tester,
      field: 'Select...',
      sheet: 'Project',
      option: 'Project Alpha',
    );
    await _pick(
      tester,
      field: 'Select...',
      sheet: 'Contract',
      option: 'Contract Alpha',
    );
    await _pick(
      tester,
      field: 'Select...',
      sheet: 'Structure Type',
      option: 'Earthwork',
    );

    expect(find.text('Earthwork'), findsNWidgets(3));
    expect(find.textContaining('Chainage From'), findsOneWidget);
    expect(find.textContaining('Chainage To'), findsOneWidget);
    expect(find.byKey(WorkRfiFormPage.layerFieldKey), findsOneWidget);

    await _pick(
      tester,
      field: WorkRfiFormPage.structureFieldKey,
      sheet: 'Structure',
      option: 'Structure 170',
    );

    expect(find.text('Earthwork'), findsNWidgets(3));
    expect(find.textContaining('Chainage From'), findsOneWidget);
    expect(find.byKey(WorkRfiFormPage.layerFieldKey), findsOneWidget);
    expect(find.text('e.g. 12+500'), findsOneWidget);
    expect(
      _payload(_single(calls, ApiConstants.activitiesUpdateComponentsPath)),
      <String, dynamic>{
        'contract_id_fk': 'C01',
        'strip_chart_structure_id_fk': '170',
        'structure_type_fk': 'Earthwork',
      },
    );
    expect(
      calls.where((RequestOptions call) => call.method.toUpperCase() == 'PUT'),
      isEmpty,
    );
    expect(
      calls.where(
        (RequestOptions call) => call.path == ApiConstants.workRfiCreatePath,
      ),
      isEmpty,
    );
  });

  test('description lookup queries the activity label and WORK type', () async {
    final List<RequestOptions> calls = <RequestOptions>[];
    final WorkRfiRemoteDataSource source = WorkRfiRemoteDataSource(
      _scriptedDio(calls: calls, body: _createFormBody),
    );

    final List<WorkRfiOption> options = await source.fetchDescriptions(
      'Blanketing',
    );

    final RequestOptions request = calls.single;
    expect(request.method, 'GET');
    expect(request.path, ApiConstants.rfiTypeDescriptionsPath);
    expect(request.queryParameters['activity'], 'Blanketing');
    expect(request.queryParameters['rfitype'], 'WORK');
    expect(options.single.id, '8');
    expect(options.single.label, 'Formation - Blanketing');
    _expectReadOnlyLookups(calls);
  });

  testWidgets('create form fills RFI descriptions after activity is set', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final List<RequestOptions> calls = <RequestOptions>[];
    final WorkRfiRemoteDataSource source = WorkRfiRemoteDataSource(
      _scriptedDio(calls: calls, body: _createFormBody),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          workRfiRemoteDataSourceProvider.overrideWithValue(source),
        ],
        child: const MaterialApp(home: WorkRfiFormPage()),
      ),
    );
    await _until(tester, find.text('Select...'));
    expect(_onTap(tester, WorkRfiFormPage.descriptionFieldKey), isNull);

    await _pick(
      tester,
      field: 'Select...',
      sheet: 'Project',
      option: 'Project Alpha',
    );
    await _pick(
      tester,
      field: 'Select...',
      sheet: 'Contract',
      option: 'Contract Alpha',
    );
    expect(_onTap(tester, WorkRfiFormPage.descriptionFieldKey), isNull);
    await _pick(
      tester,
      field: 'Select...',
      sheet: 'Structure Type',
      option: 'Blanketing',
    );

    final RequestOptions descriptions = _single(
      calls,
      ApiConstants.rfiTypeDescriptionsPath,
    );
    expect(descriptions.method, 'GET');
    expect(descriptions.path, ApiConstants.rfiTypeDescriptionsPath);
    expect(descriptions.queryParameters['activity'], 'Blanketing');
    expect(descriptions.queryParameters['rfitype'], 'WORK');
    expect(descriptions.uri.toString().startsWith('http'), isFalse);
    expect(_onTap(tester, WorkRfiFormPage.descriptionFieldKey), isNotNull);

    await _pick(
      tester,
      field: WorkRfiFormPage.descriptionFieldKey,
      sheet: 'RFI Description',
      option: 'Formation - Blanketing',
    );
    expect(find.text('Formation - Blanketing'), findsOneWidget);

    await _pick(
      tester,
      field: 'Blanketing',
      sheet: 'Structure Type',
      option: 'Earthwork',
    );
    expect(find.text('Formation - Blanketing'), findsNothing);
    expect(_onTap(tester, WorkRfiFormPage.descriptionFieldKey), isNull);
    final List<RequestOptions> descriptionCalls = calls
        .where(
          (RequestOptions call) =>
              call.path == ApiConstants.rfiTypeDescriptionsPath,
        )
        .toList(growable: false);
    expect(descriptionCalls, hasLength(2));
    expect(descriptionCalls.last.method, 'GET');
    expect(descriptionCalls.last.queryParameters['activity'], 'Earthwork');
    expect(descriptionCalls.last.queryParameters['rfitype'], 'WORK');
    expect(find.text('Earthwork'), findsNWidgets(3));
    expect(find.textContaining('Chainage From'), findsOneWidget);
    _expectReadOnlyLookups(calls);
  });

  test('minor bridge activities parse id as value and name as label', () {
    final WorkRfiOption option = parseWorkRfiActivities(<Map<String, dynamic>>[
      <String, dynamic>{
        'strip_chart_activity_id': '2174',
        'strip_chart_activity_name': 'Excavation',
      },
    ]).single;

    expect(option.id, '2174');
    expect(option.label, 'Excavation');
  });

  test('activities lookup posts the element parents', () async {
    final List<RequestOptions> calls = <RequestOptions>[];
    final WorkRfiRemoteDataSource source = WorkRfiRemoteDataSource(
      _scriptedDio(
        calls: calls,
        body: (RequestOptions options) {
          expect(options.path, ApiConstants.activitiesUpdateActivitiesPath);
          return <Map<String, dynamic>>[
            <String, dynamic>{
              'strip_chart_activity_id': '2174',
              'strip_chart_activity_name': 'Excavation',
            },
          ];
        },
      ),
    );

    final List<WorkRfiOption> options = await source.fetchActivities(
      contractId: 'P01EN01',
      structureId: '113',
      structureType: 'Minor Bridge',
      component: 'Excavation & Levelling',
      element: 'Excavation',
    );

    expect(calls.single.method, 'POST');
    expect(calls.single.path, ApiConstants.activitiesUpdateActivitiesPath);
    expect(_payload(calls.single), <String, dynamic>{
      'contract_id_fk': 'P01EN01',
      'strip_chart_structure_id_fk': '113',
      'structure_type_fk': 'Minor Bridge',
      'strip_chart_component': 'Excavation & Levelling',
      'strip_chart_component_id': 'Excavation',
    });
    expect(options.single.id, '2174');
    expect(options.single.label, 'Excavation');
    _expectReadOnlyLookups(calls);
  });

  testWidgets('create form loads activities after element selection', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final List<RequestOptions> calls = <RequestOptions>[];
    final WorkRfiRemoteDataSource source = WorkRfiRemoteDataSource(
      _scriptedDio(calls: calls, body: _minorBridgeActivitiesBody),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          workRfiRemoteDataSourceProvider.overrideWithValue(source),
        ],
        child: const MaterialApp(home: WorkRfiFormPage()),
      ),
    );
    await _until(tester, find.text('Select...'));
    expect(_onTap(tester, WorkRfiFormPage.activityFieldKey), isNull);

    await _pick(
      tester,
      field: 'Select...',
      sheet: 'Project',
      option: 'Tumkuru Project',
    );
    await _pick(
      tester,
      field: 'Select...',
      sheet: 'Contract',
      option: 'New Broad gauge line',
    );
    await _pick(
      tester,
      field: 'Select...',
      sheet: 'Structure Type',
      option: 'Minor Bridge',
    );
    await _pick(
      tester,
      field: WorkRfiFormPage.structureFieldKey,
      sheet: 'Structure',
      option: 'MNB CH 63+200 (RCC Box)',
    );
    await _pick(
      tester,
      field: WorkRfiFormPage.componentFieldKey,
      sheet: 'Component',
      option: 'Excavation & Levelling',
    );
    expect(
      calls.where(
        (RequestOptions call) =>
            call.path == ApiConstants.activitiesUpdateActivitiesPath,
      ),
      isEmpty,
    );
    expect(_onTap(tester, WorkRfiFormPage.activityFieldKey), isNull);

    await _pick(
      tester,
      field: WorkRfiFormPage.elementFieldKey,
      sheet: 'Element',
      option: 'Excavation',
    );

    final RequestOptions activities = _single(
      calls,
      ApiConstants.activitiesUpdateActivitiesPath,
    );
    expect(activities.method, 'POST');
    expect(_payload(activities), <String, dynamic>{
      'contract_id_fk': 'P01EN01',
      'strip_chart_structure_id_fk': '113',
      'structure_type_fk': 'Minor Bridge',
      'strip_chart_component': 'Excavation & Levelling',
      'strip_chart_component_id': 'Excavation',
    });
    expect(activities.uri.toString().startsWith('http'), isFalse);
    expect(_onTap(tester, WorkRfiFormPage.activityFieldKey), isNotNull);

    await _open(tester, field: WorkRfiFormPage.activityFieldKey, sheet: 'Activity');
    expect(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.text('Excavation'),
      ),
      findsOneWidget,
    );
    Navigator.of(
      tester.element(_sheetTitle('Activity')),
      rootNavigator: true,
    ).pop();
    await _untilAbsent(tester, _sheetTitle('Activity'));

    await _pick(
      tester,
      field: WorkRfiFormPage.activityFieldKey,
      sheet: 'Activity',
      option: 'Excavation',
    );
    final RequestOptions descriptions = _single(
      calls,
      ApiConstants.rfiTypeDescriptionsPath,
    );
    expect(descriptions.method, 'GET');
    expect(descriptions.queryParameters['activity'], 'Excavation');
    expect(descriptions.queryParameters['rfitype'], 'WORK');
    expect(_onTap(tester, WorkRfiFormPage.descriptionFieldKey), isNotNull);

    await _pick(
      tester,
      field: WorkRfiFormPage.descriptionFieldKey,
      sheet: 'RFI Description',
      option: 'Box excavation check',
    );
    expect(find.text('Box excavation check'), findsOneWidget);

    await _pick(tester, field: 'Excavation', sheet: 'Element', option: 'PCC');
    expect(find.text('Box excavation check'), findsNothing);
    expect(find.byKey(WorkRfiFormPage.activityFieldKey), findsOneWidget);
    final List<RequestOptions> activityCalls = calls
        .where(
          (RequestOptions call) =>
              call.path == ApiConstants.activitiesUpdateActivitiesPath,
        )
        .toList(growable: false);
    expect(activityCalls, hasLength(2));
    expect(_payload(activityCalls.last)['strip_chart_component_id'], 'PCC');
    expect(_onTap(tester, WorkRfiFormPage.activityFieldKey), isNotNull);
    await _open(tester, field: WorkRfiFormPage.activityFieldKey, sheet: 'Activity');
    expect(find.text('PCC Layer'), findsOneWidget);
    expect(find.text('Excavation'), findsNothing);
    Navigator.of(
      tester.element(_sheetTitle('Activity')),
      rootNavigator: true,
    ).pop();
    await _untilAbsent(tester, _sheetTitle('Activity'));

    await _pick(
      tester,
      field: 'MNB CH 63+200 (RCC Box)',
      sheet: 'Structure',
      option: 'MNB CH 64+000',
    );
    expect(find.byKey(WorkRfiFormPage.componentFieldKey), findsOneWidget);
    expect(find.byKey(WorkRfiFormPage.activityFieldKey), findsOneWidget);
    expect(_onTap(tester, WorkRfiFormPage.activityFieldKey), isNull);
    expect(find.text('PCC Layer'), findsNothing);
    expect(
      calls.where(
        (RequestOptions call) =>
            call.path == ApiConstants.activitiesUpdateActivitiesPath,
      ),
      hasLength(2),
    );
    _expectReadOnlyLookups(calls);
  });
}

Dio _scriptedDio({
  required List<RequestOptions> calls,
  required Object? Function(RequestOptions options) body,
}) {
  final Dio dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        calls.add(options);
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: body(options),
          ),
        );
      },
    ),
  );
  return dio;
}

Object? _minorBridgeActivitiesBody(RequestOptions options) {
  switch (options.path) {
    case ApiConstants.rfiProjectNamesPath:
      return <Map<String, dynamic>>[
        <String, dynamic>{'projectId': 'P01', 'projectName': 'Tumkuru Project'},
      ];
    case ApiConstants.rfiContractNamesPath:
      return <Map<String, dynamic>>[
        <String, dynamic>{
          'contractIdFk': 'P01EN01',
          'contractShortName': 'New Broad gauge line',
        },
      ];
    case ApiConstants.structureTypesInActivitiesPath:
      return <Map<String, dynamic>>[
        <String, dynamic>{'structure_type': 'Minor Bridge'},
        <String, dynamic>{'structure_type': 'RUB'},
      ];
    case ApiConstants.activitiesUpdateStructuresPath:
      return <Map<String, dynamic>>[
        <String, dynamic>{
          'structure_id': '113',
          'strip_chart_structure_id_fk': 'MNB CH 63+200 (RCC Box)',
        },
        <String, dynamic>{
          'structure_id': '114',
          'strip_chart_structure_id_fk': 'MNB CH 64+000',
        },
      ];
    case ApiConstants.activitiesUpdateComponentsPath:
      return <Map<String, dynamic>>[
        <String, dynamic>{'strip_chart_component': 'Excavation & Levelling'},
      ];
    case ApiConstants.activitiesUpdateComponentIdsPath:
      return <Map<String, dynamic>>[
        <String, dynamic>{'strip_chart_component_id': 'Excavation'},
        <String, dynamic>{'strip_chart_component_id': 'PCC'},
      ];
    case ApiConstants.activitiesUpdateActivitiesPath:
      final String element =
          _payload(options)['strip_chart_component_id']?.toString() ?? '';
      if (element == 'Excavation') {
        return <Map<String, dynamic>>[
          <String, dynamic>{
            'strip_chart_activity_id': '2174',
            'strip_chart_activity_name': 'Excavation',
          },
        ];
      }
      return <Map<String, dynamic>>[
        <String, dynamic>{
          'strip_chart_activity_id': '3001',
          'strip_chart_activity_name': 'PCC Layer',
        },
      ];
    case ApiConstants.rfiTypeDescriptionsPath:
      final String activity =
          options.queryParameters['activity']?.toString() ?? '';
      final String rfiType =
          options.queryParameters['rfitype']?.toString() ?? '';
      if (activity == 'Excavation' && rfiType == 'WORK') {
        return <Map<String, dynamic>>[
          <String, dynamic>{'id': 71, 'rfiDescription': 'Box excavation check'},
        ];
      }
      return <Map<String, dynamic>>[];
    default:
      return <Map<String, dynamic>>[];
  }
}

Object? _createFormBody(RequestOptions options) {
  switch (options.path) {
    case ApiConstants.rfiProjectNamesPath:
      return <Map<String, dynamic>>[
        <String, dynamic>{'projectId': 'P01', 'projectName': 'Project Alpha'},
      ];
    case ApiConstants.rfiContractNamesPath:
      return <Map<String, dynamic>>[
        <String, dynamic>{
          'contractIdFk': 'C01',
          'contractShortName': 'Contract Alpha',
        },
      ];
    case ApiConstants.structureTypesInActivitiesPath:
      return <Map<String, dynamic>>[
        <String, dynamic>{'structure_type': 'Minor Bridge'},
        <String, dynamic>{'structure_type': 'Earthwork'},
        <String, dynamic>{'structure_type': 'Blanketing'},
        <String, dynamic>{'structure_type': 'Important Bridge'},
      ];
    case ApiConstants.activitiesUpdateStructuresPath:
      return <Map<String, dynamic>>[
        <String, dynamic>{
          'structure_id': 170,
          'strip_chart_structure_id_fk': 'Structure 170',
        },
        <String, dynamic>{
          'structure_id': '171',
          'strip_chart_structure_id_fk': 'Structure 171',
        },
        <String, dynamic>{
          'structure_id': 172,
          'strip_chart_structure_id_fk': 'Structure 172',
        },
      ];
    case ApiConstants.rfiLayerRangePath:
      return <String, dynamic>{'minLayer': 1, 'maxLayer': 2};
    case ApiConstants.activitiesUpdateComponentsPath:
      final String structureId = _payload(
        options,
      )['strip_chart_structure_id_fk'].toString();
      if (structureId == '171') {
        return <Map<String, dynamic>>[
          <String, dynamic>{'strip_chart_component': 'Excavation'},
        ];
      }
      if (structureId == '172') {
        return <Map<String, dynamic>>[];
      }
      return <Map<String, dynamic>>[
        <String, dynamic>{'strip_chart_component': 'Blanketing'},
      ];
    case ApiConstants.activitiesUpdateComponentIdsPath:
      return <Map<String, dynamic>>[
        <String, dynamic>{'strip_chart_component_id': 'CH 25400 to CH 26000'},
      ];
    case ApiConstants.rfiTypeDescriptionsPath:
      final String activity =
          options.queryParameters['activity']?.toString() ?? '';
      final String rfiType =
          options.queryParameters['rfitype']?.toString() ?? '';
      if (activity == 'Blanketing' && rfiType == 'WORK') {
        return <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 8,
            'rfiDescription': 'Formation - Blanketing',
            'pmisCalc': 'unused',
            'enclosures': <String>['4'],
          },
        ];
      }
      return <Map<String, dynamic>>[];
    default:
      return <Map<String, dynamic>>[];
  }
}

Map<String, dynamic> _payload(RequestOptions options) {
  return Map<String, dynamic>.from(options.data as Map);
}

RequestOptions _single(List<RequestOptions> calls, String path) {
  return calls.singleWhere((RequestOptions call) => call.path == path);
}

void _expectReadOnlyLookups(List<RequestOptions> calls) {
  expect(calls, isNotEmpty);
  for (final RequestOptions call in calls) {
    expect(call.path.startsWith('/'), isTrue);
    expect(call.uri.toString().startsWith('http'), isFalse);
    expect(call.method.toUpperCase(), isNot('PUT'));
    expect(call.path, isNot(ApiConstants.workRfiCreatePath));
    expect(call.path, isNot(ApiConstants.workRfiPath(1)));
  }
}

Finder _fieldTarget(Object field) {
  if (field is Key) {
    return find.descendant(
      of: find.byKey(field),
      matching: find.byType(InkWell),
    );
  }
  return find.ancestor(
    of: find.text(field as String),
    matching: find.byType(InkWell),
  );
}

VoidCallback? _onTap(WidgetTester tester, Object field) {
  return tester.widget<InkWell>(_fieldTarget(field).first).onTap;
}

Future<void> _pick(
  WidgetTester tester, {
  required Object field,
  required String sheet,
  required String option,
}) async {
  await _open(tester, field: field, sheet: sheet);
  final Finder choice = find.text(option).hitTestable();
  await _until(tester, choice);
  await tester.tap(choice.last);
  await _untilAbsent(tester, _sheetTitle(sheet));
  await _settle(tester);
}

Future<void> _open(
  WidgetTester tester, {
  required Object field,
  required String sheet,
}) async {
  await _settle(tester);
  final Finder target = field is Key
      ? _fieldTarget(field).hitTestable()
      : find.text(field as String).hitTestable();
  await _until(tester, target);
  await tester.ensureVisible(target.first);
  await tester.tap(target.first);
  await _until(tester, _sheetTitle(sheet).hitTestable());
}

Finder _sheetTitle(String title) {
  return find.descendant(
    of: find.byType(BottomSheet),
    matching: find.text(title),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (find.byType(LinearProgressIndicator).evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 20));
      if (find.byType(LinearProgressIndicator).evaluate().isEmpty) {
        return;
      }
    }
  }
  fail('Lookup did not finish');
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40; i++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Timed out waiting for $finder');
}

Future<void> _untilAbsent(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40; i++) {
    if (finder.evaluate().isEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Timed out waiting for $finder to leave');
}
