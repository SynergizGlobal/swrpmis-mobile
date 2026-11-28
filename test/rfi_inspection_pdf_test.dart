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
        description: '1',
        type: 'Percent',
        units: '%',
        total: '40',
      ),
      RfiPdfMeasurement(
        component: 'Foundation',
        element: 'Open Foundation',
        activityName: 'Concreting',
        description: 'aa',
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

  test('earthwork details line includes chainage and layer', () {
    final RfiInspectionPdfData data = RfiInspectionPdfData(
      rfiNo: 'RFI_W_EW_S2_EFIL_SS10_0552',
      rfiCategory: 'WORK',
      inspectionMode: 'ONLINE',
      contract: 'Tumkur-Chitradurga-Davangere project',
      contractor: 'KRC ALTIS JOINT VENTURE',
      contractorRep: 'NA',
      location: '',
      conSubmittedOn: '09-09-2026 23:26',
      enggSubmittedOn: '12/09/2026 18:36',
      raisedOn: '09/09/2026 23:26',
      rfiDescriptionSelected: 'Formation - Embankment',
      rfiDescription: '',
      structureType: 'Earthwork',
      structure: 'CH 34000 to CH 55800',
      component: 'Earthwork Filling',
      element: 'CH 39000 to CH 40000',
      activity: '',
      chainageFrom: '39740',
      chainageTo: '39920',
      layer: 'Layer 3',
    );
    expect(
      data.detailsLine.$1,
      'Structure Type/Structure/Component/Element/Chainage From/Chainage To/Layer/Rfi-Description :',
    );
    expect(
      data.detailsLine.$2,
      'Earthwork/CH 34000 to CH 55800/Earthwork Filling/CH 39000 to CH 40000/39740/39920/3/Formation - Embankment',
    );
    expect(rfiPdfDisplayedLayer('Layer 3'), '3');
    expect(rfiPdfDisplayedLayer('Subgrade Top Layer'), 'Subgrade Top Layer');
  });

  test('track work details line includes chainage without layer', () {
    final RfiInspectionPdfData data = RfiInspectionPdfData(
      rfiNo: 'RFI_W_TW_0001',
      rfiCategory: 'WORK',
      inspectionMode: 'ONLINE',
      contract: 'Contract',
      contractor: 'Contractor',
      contractorRep: 'Rep',
      location: '',
      conSubmittedOn: '',
      enggSubmittedOn: '',
      raisedOn: '',
      rfiDescriptionSelected: 'Track Linking',
      rfiDescription: 'note',
      structureType: 'Track Work',
      structure: 'Main Line',
      component: 'Rails',
      element: 'Section A',
      activity: '',
      chainageFrom: '12500',
      chainageTo: '13000',
      layer: 'Layer 2',
    );
    expect(
      data.detailsLine.$1,
      'Structure Type/Structure/Component/Element/Chainage From/Chainage To/Rfi-Description :',
    );
    expect(
      data.detailsLine.$2,
      'Track Work/Main Line/Rails/Section A/12500/13000/Track Linking',
    );
  });

  test('duplicate and non-PDF files are not merged', () {
    final Uint8List pdf = Uint8List.fromList('%PDF-1.4 abc'.codeUnits);
    final Uint8List other = Uint8List.fromList('hello'.codeUnits);
    expect(rfiUniquePdfs(<Uint8List>[pdf, pdf, other]), hasLength(1));
  });
}
