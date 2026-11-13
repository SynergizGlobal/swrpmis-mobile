import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_inspection_flow_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/rfi_inspection_pdf.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_inspection_flow_provider.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_submit_progress_dialog.dart';

const RfiInspectionFlowArgs _args = RfiInspectionFlowArgs(
  rfiId: 105,
  rfiCategory: 'WORK',
  offline: false,
);

void main() {
  test('engineer must pick a status, and give remarks unless Accepted', () {
    const RfiInspectionFlowState empty = RfiInspectionFlowState(args: _args);
    expect(rfiEngineerSubmitError(empty), 'Please select Inspection Status!');
    expect(
      rfiEngineerSubmitError(empty.copyWith(engineerStatus: 'Accepted')),
      isNull,
    );
    expect(
      rfiEngineerSubmitError(empty.copyWith(engineerStatus: 'Rejected')),
      'Remarks are mandatory when Inspection is Rejected!',
    );
    expect(
      rfiEngineerSubmitError(
        empty.copyWith(
          engineerStatus: rfiReturnForRectification,
          engineerRemarks: 'fix shuttering',
        ),
      ),
      isNull,
    );
  });

  test('Return For Rectification is online only, like the web', () {
    expect(
      rfiEngineerStatusOptions(
        offline: false,
      ).map(((String, String) o) => o.$1),
      <String>['Accepted', 'Rejected', 'Returned_For_Rectification'],
    );
    expect(rfiEngineerStatusOptions(offline: true), hasLength(2));
  });

  test('rectification shows its own two steps', () {
    expect(rfiSubmitSteps(rectification: true), <RfiSubmitStep>[
      RfiSubmitStep.rectifyPrepare,
      RfiSubmitStep.rectifySend,
    ]);
    final RfiSubmitProgress progress = RfiSubmitProgress(
      steps: rfiSubmitSteps(rectification: true),
    )..update(RfiSubmitStep.pdf, RfiStepStatus.done);
    expect(progress.statusOf(RfiSubmitStep.rectifySend), RfiStepStatus.waiting);
  });

  test('engineer endpoints match the web', () {
    expect(ApiConstants.rfiUploadPdfEngineerPath, '/rfi/rfi/uploadPdf/Engg');
    expect(ApiConstants.rfiStampEnggPdfFromXmlPath, '/rfi/stampEnggPdfFromXml');
  });

  test('engineer stamp only fails on status "error"', () {
    expect(
      rfiStampResult(
        '{"message":"Engineer e-sign done"}',
        requireSuccess: false,
      ),
      'Engineer e-sign done',
    );
    expect(
      () => rfiStampResult(
        '{"status":"error","message":"No XML"}',
        requireSuccess: false,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('RFI Required = No builds the short layout', () async {
    final Uint8List bytes = await RfiInspectionPdf.build(
      data: const RfiInspectionPdfData(
        rfiNo: 'RFI_W_TEST_0001',
        rfiCategory: 'WORK',
        inspectionMode: 'ONLINE',
        contract: 'Contract',
        contractor: 'Contractor',
        contractorRep: '',
        location: 'should not print',
        conSubmittedOn: '13/11/2026 12:47',
        enggSubmittedOn: '13/11/2026 13:10',
        raisedOn: '13/11/2026 11:02',
        rfiDescriptionSelected: 'Concreting',
        rfiDescription: 'Mobile QA test',
        structureType: 'Minor Bridge',
        structure: 'MNB',
        component: 'Foundation',
        element: 'Open Foundation',
        activity: 'Concreting',
        inspectionStatus: 'Rejected',
        engineerRemarks: 'Cover blocks missing',
        inspDescriptionEngg: 'Checked on site',
        rfiNotRequired: true,
        measurements: <RfiPdfMeasurement>[
          RfiPdfMeasurement(
            activityName: 'Concreting',
            type: 'Number',
            no: '5',
          ),
        ],
      ),
      fonts: RfiInspectionPdfFonts.helvetica(),
    );
    expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
    final String out = Platform.environment['RFI_NO_PDF_OUT'] ?? '';
    if (out.isNotEmpty) {
      File(out).writeAsBytesSync(bytes);
    }
  });
}
