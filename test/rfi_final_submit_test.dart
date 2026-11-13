import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_inspection_flow_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_final_submit_payload.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_inspection_flow_provider.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_submit_progress_dialog.dart';

void main() {
  test('finalSubmit data matches the web payload for RFI 105', () {
    final Map<String, dynamic> data = buildRfiFinalSubmitPayload(
      inspectionId: 89,
      rfiId: 105,
      uploadedBy: 'CON',
      location: '1-',
      chainage: '',
      nameOfRepresentative: 'KOUSTAV PAL',
      measurements: const <RfiSubmitMeasurement>[
        RfiSubmitMeasurement(
          activityIdFk: 1887,
          activityName: 'Reinforcement & Shuttering',
          measurementType: 'Percent',
          units: '%',
          length: '',
          breadth: '',
          height: '',
          weight: '',
          no: '',
          totalQty: 40.0,
        ),
        RfiSubmitMeasurement(
          activityIdFk: 1888,
          activityName: 'Concreting',
          measurementType: 'Number',
          units: 'Nos',
          length: '',
          breadth: '',
          height: '',
          weight: '',
          no: '3',
          totalQty: 3.0,
        ),
      ],
      testInsiteLab: 'VISUAL',
      inspectionStatus: null,
      engineerRemarks: null,
      descriptionEnclosure: '',
      supportingDescriptions: const <String>[],
      inspectionMode: 'ONLINE',
    );
    expect(data, <String, dynamic>{
      'inspectionId': 89,
      'rfiId': 105,
      'uploadedBy': 'CON',
      'location': '1-',
      'chainage': null,
      'nameOfRepresentative': 'KOUSTAV PAL',
      'measurements': <Map<String, dynamic>>[
        <String, dynamic>{
          'activityIdFk': 1887,
          'activityName': 'Reinforcement & Shuttering',
          'measurementType': 'Percent',
          'l': null,
          'b': null,
          'h': null,
          'weight': null,
          'units': '%',
          'no': null,
          'totalQty': 40,
        },
        <String, dynamic>{
          'activityIdFk': 1888,
          'activityName': 'Concreting',
          'measurementType': 'Number',
          'l': null,
          'b': null,
          'h': null,
          'weight': null,
          'units': 'Nos',
          'no': 3,
          'totalQty': 3,
        },
      ],
      'testInsiteLab': 'VISUAL',
      'inspectionStatus': null,
      'engineerRemarks': null,
      'descriptionEnclosure': '',
      'supportingDescriptions': <String>[],
      'inspectionMode': 'ONLINE',
    });
  });

  test('txnId is epoch millis plus a 3-digit suffix', () {
    final String id = rfiStampTxnId(
      now: DateTime.fromMillisecondsSinceEpoch(1794554248616),
      random: 44,
    );
    expect(id, '1794554248616044');
  });

  test('stamp reply: success passes, anything else fails', () {
    expect(
      rfiStampResult(
        '{"message":"Contractor e-sign successfully from XML","status":"success"}',
      ),
      'Contractor e-sign successfully from XML',
    );
    expect(
      () => rfiStampResult('{"status":"error","message":"No XML"}'),
      throwsA(isA<StateError>()),
    );
  });

  test('stamping is skipped only when RFI is not required', () {
    expect(rfiRequiresStamp('Yes'), isTrue);
    expect(rfiRequiresStamp(''), isTrue);
    expect(rfiRequiresStamp('No'), isFalse);
  });

  test('PDF dates match the web format', () {
    expect(rfiPdfServerDate('13-11-2026 11:02'), '13/11/2026 11:02');
    expect(rfiPdfTimestamp(DateTime(2026, 11, 13, 12, 47)), '13/11/2026 12:47');
    expect(rfiPdfQuantity(40), '40');
    expect(rfiPdfQuantity(2.5), '2.5');
  });

  test('step failure messages name the step', () {
    expect(
      rfiSubmitStepMessage(
        RfiSubmitStepFailure(RfiSubmitStep.stamp, StateError('No XML')),
      ),
      startsWith('E-sign failed'),
    );
  });

  testWidgets('progress dialog shows the five web steps', (
    WidgetTester tester,
  ) async {
    final RfiSubmitProgress progress = RfiSubmitProgress()
      ..update(RfiSubmitStep.session, RfiStepStatus.done)
      ..update(RfiSubmitStep.pdf, RfiStepStatus.done)
      ..update(RfiSubmitStep.upload, RfiStepStatus.active);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RfiSubmitProgressDialog(progress: progress)),
      ),
    );
    expect(find.text('Submitting Inspection'), findsOneWidget);
    for (final RfiSubmitStep step in progress.steps) {
      expect(find.text(step.label), findsOneWidget);
    }
    expect(find.text('Completed'), findsNWidgets(2));
    expect(find.text('Processing...'), findsOneWidget);
    expect(find.text('Waiting'), findsNWidgets(2));
    progress.fail('E-sign failed: No XML');
    await tester.pump();
    expect(find.text('Close'), findsOneWidget);
  });
}
