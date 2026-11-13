import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/rfi_inspection_pdf.dart';

RfiInspectionPdfData sampleInspection({
  List<Uint8List> images = const <Uint8List>[],
}) {
  return RfiInspectionPdfData(
    rfiNo: 'RFI_W_MNB_56319_FOUN_OPNF_RNFSHT_0001',
    rfiCategory: 'WORK',
    inspectionMode: 'ONLINE',
    contract:
        'New Broad gauge line Between KM 25.4 & KM 66.4 (41.0 KM) in Tumkur-Chitradurga-Davangere project',
    contractor: 'M/s GIRIRAJ CIVIL DEVELOPERS LIMITED - MUMBAI',
    contractorRep: 'KOUSTAV PAL',
    location: '1-',
    conSubmittedOn: '13/11/2026 12:47',
    enggSubmittedOn: '',
    raisedOn: '13/11/2026 11:02',
    rfiDescriptionSelected: 'Concreting',
    rfiDescription: 'Mobile QA test - please ignore',
    structureType: 'Minor Bridge',
    structure: 'MNB CH 56+319 (RCC Box)',
    component: 'Foundation',
    element: 'Open Foundation',
    activity: 'Reinforcement & Shuttering, Concreting',
    enclosures: <RfiPdfEnclosure>[
      RfiPdfEnclosure(
        rfiDescription: 'Concreting',
        enclosure: 'RCC Works - Concrete',
        checklist: <RfiPdfChecklistRow>[
          const RfiPdfChecklistRow(
            description: 'DRAWING APPROVED AND AVAILABLE',
            contractorStatus: 'YES',
            contractorRemark: 'testing',
          ),
          for (int i = 0; i < 18; i++)
            RfiPdfChecklistRow(
              description: 'CHECKLIST ITEM ${i + 2}',
              contractorStatus: 'YES',
            ),
        ],
      ),
    ],
    measurements: const <RfiPdfMeasurement>[
      RfiPdfMeasurement(
        component: 'Foundation',
        element: 'Open Foundation',
        activityName: 'Reinforcement & Shuttering',
        type: 'Percent',
        units: '%',
        total: '40',
      ),
      RfiPdfMeasurement(
        component: 'Foundation',
        element: 'Open Foundation',
        activityName: 'Concreting',
        type: 'Number',
        units: 'Nos',
        no: '3',
        total: '3',
      ),
    ],
    contractorImages: images,
  );
}

void main() {
  test('builds the inspection PDF like the web sample', () async {
    final Uint8List logo = File('assets/brand/swr_logo.png').readAsBytesSync();
    final Uint8List bytes = await RfiInspectionPdf.build(
      data: sampleInspection(images: <Uint8List>[logo, logo]),
      fonts: RfiInspectionPdfFonts.helvetica(),
      logo: logo,
    );
    expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
    final String out = Platform.environment['RFI_PDF_OUT'] ?? '';
    if (out.isNotEmpty) {
      File(out).writeAsBytesSync(bytes);
    }
  });

  test('details line follows the structure type', () {
    expect(
      sampleInspection().detailsLine.$2,
      'Minor Bridge/MNB CH 56+319 (RCC Box)/Foundation/Open Foundation/Reinforcement & Shuttering, Concreting/Concreting',
    );
  });

  test('duplicate and non-PDF files are not merged', () {
    final Uint8List pdf = Uint8List.fromList('%PDF-1.4 abc'.codeUnits);
    final Uint8List other = Uint8List.fromList('hello'.codeUnits);
    expect(rfiUniquePdfs(<Uint8List>[pdf, pdf, other]), hasLength(1));
  });
}
