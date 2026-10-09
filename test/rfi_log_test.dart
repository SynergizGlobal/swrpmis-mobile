import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_hosts.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/rfi_log_pdf.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_filter.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_log_report.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_log_row.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_log_links.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_stored_file.dart';

void main() {
  const String selfie =
      r'C:\Users\Vikas\git\swrpmis\Rfi-Storage\uploads\siteImages\5d368f52-edb3-4efa-9533-415d6eb08908_selfie.jpg';
  const String testReport =
      r'C:\Users\Vikas/git/swrpmis/Rfi-Storage/Inspection-Site-Documents/RFI_57_null_report_1790853051049.pdf';

  const Map<String, dynamic> logRow = <String, dynamic>{
    'id': 57,
    'status': 'AE_INSP_ONGOING',
    'contract': 'P01EN01',
    'structure': '43 (RCC Box)',
    'project': 'P01',
    'rfiCategory': 'WORK',
    'rfiDescription': 'Excavation',
    'rfiId': 'RFI_W_RUB_36838_EXCL_EXC_0001',
    'nameOfRepresentative': 'IT Test Contractor Rep',
    'person': null,
    'dateRaised': '01-10-2026',
    'conRespondedDate': '01-10-2026',
    'enggRespondedDate': null,
    'notes': null,
    'txnId': '1790853050301193',
  };

  final Map<String, dynamic> reportJson = <String, dynamic>{
    'reportDetails': <String, dynamic>{
      'rfiStatus': 'Active',
      'rfiId': 'RFI_W_RUB_36838_EXCL_EXC_0001',
      'dateOfCreation': '2026-10-01',
      'project': '4th Line between Itarsi - Bhopal - Bina',
      'contract': 'New Broad gauge line',
      'contractId': 'P01EN01',
      'structureType': 'Important Bridge',
      'structure': '43 (RCC Box)',
      'component': 'Excavation & Levelling',
      'element': 'Excavation',
      'activity': 'Excavation',
      'rfiDescription': 'Excavation',
      'rfiCategory': 'WORK',
      'typeOfRfi': 'Spot RFI',
      'enclosures': 'Excavation',
      'contractor': null,
      'contractorRepresentative': 'IT Test Contractor Rep',
      'clientRepresentative': null,
      'chainage': null,
      'proposedDateOfInspection': '2026-10-01',
      'proposedInspectionTime': '14:30:00',
      'conInspDate': '2026-10-01',
      'conInspTime': '16:40:51',
      'enggInspDate': null,
      'descriptionByContractor': 'Testing... RFI',
      'conLocation': 'Vishwanathapura',
      'clientLocation': 'Vishwanathapura',
      'typeOfTest': 'LAB_TEST',
      'testStatus': 'Accepted',
      'dyHodUserName': 'Mr. A K Meena',
      'validationStatus': null,
      'remarks': null,
      'validationComments': null,
      'selfieContractor': selfie,
      'selfieClient': selfie,
      'testSiteDocumentsContractor': testReport,
      'attachments': <dynamic>[],
    },
    'workDetails': <Map<String, dynamic>>[
      <String, dynamic>{
        'activityName': null,
        'unit': 'Cum',
        'scope': 494.99,
        'completedTillDate': 0,
        'inspectionQuantity': '697.320000',
      },
    ],
    'measurementDetails': <String, dynamic>{
      'measurementType': 'Volume',
      'units': 'km³',
      'l': 3,
      'b': 3,
      'h': 3,
      'weight': null,
      'no': 3,
      'totalQty': 81.0,
    },
    'checklistItems': <Map<String, dynamic>>[
      for (int index = 0; index < 7; index++)
        <String, dynamic>{
          'enclosureName': 'Excavation',
          'checklistDescription': 'Check $index',
          'conStatus': 'YES',
          'aeStatus': 'YES',
          'contractorRemark': null,
          'aeRemark': '',
        },
    ],
    'enclosures': <dynamic>[],
  };

  test('log row keeps dates, readable status, and a numeric download id', () {
    final RfiLogRow row = RfiLogRow.fromJson(logRow);

    expect(row.id, 57);
    expect(row.rfiId, 'RFI_W_RUB_36838_EXCL_EXC_0001');
    expect(row.dateRaised, '01-10-2026');
    expect(row.conRespondedDate, '01-10-2026');
    expect(row.enggRespondedDate, isEmpty);
    expect(row.person, isEmpty);
    expect(row.notes, isEmpty);
    expect(rfiLogCell(row.person), '—');
    expect(row.status, 'AE_INSP_ONGOING');
    expect(row.statusLabel, 'AE INSP ONGOING');
    expect(row.statusLabel, isNot('Open'));
    expect(row.txnId, '1790853050301193');
    expect(
      RfiLogLinks.downloadPath(row.rfiId, row.txnId),
      '/api/rfiLog/pdf/download/RFI_W_RUB_36838_EXCL_EXC_0001/1790853050301193',
    );
  });

  test('report sample keeps schedule, qty 81, and seven checklist rows', () {
    final RfiLogReport report = RfiLogReport.fromJson(reportJson);
    final RfiLogReportDetails details = report.details;

    expect(details.scheduledText, '2026-10-01 14:30:00');
    expect(details.proposedDateOfInspection, '2026-10-01');
    expect(details.proposedInspectionTime, '14:30:00');
    expect(details.conInspDate, '2026-10-01');
    expect(details.conInspTime, '16:40:51');
    expect(details.enggInspDate, isEmpty);
    expect(details.statusText, 'Active');
    expect(report.measurement?.totalQty, '81');
    expect(report.measurement?.length, '3');
    expect(report.measurement?.weight, isEmpty);
    expect(rfiLogPdfText(report.measurement!.weight), '---');
    expect(report.checklistItems, hasLength(7));
    expect(
      report.checklistGroups.single.titleFor(details.rfiDescription),
      'Excavation / Excavation',
    );
    expect(report.workDetails.single.activityName, isEmpty);
    expect(rfiLogPdfText(report.workDetails.single.activityName), '---');
    expect(report.hasEnclosures, isFalse);
  });

  test('a Windows selfie path is not treated as a URL', () {
    final RfiLogReport report = RfiLogReport.fromJson(reportJson);

    expect(RfiStoredFile.isWindowsPath(selfie), isTrue);
    expect(RfiStoredFile.isHttpUrl(selfie), isFalse);
    expect(report.details.selfieClientIsUrl, isFalse);
    expect(report.details.selfieContractorIsUrl, isFalse);
    expect(RfiStoredFile.isWindowsPath(testReport), isTrue);
    expect(
      RfiStoredFile.fileName(testReport),
      'RFI_57_null_report_1790853051049.pdf',
    );
    expect(RfiStoredFile.isHttpUrl('https://example.com/a.jpg'), isTrue);
  });

  test('logo url uses the app base url and empty filters stay null', () {
    expect(
      RfiLogLinks.logoUrl(ApiHosts.qaBaseUrl),
      'http://115.124.125.151:8443/swrpmis_qa/static/media/swrlogo.ed293643301635609477.png',
    );
    final Map<String, dynamic> body = const RfiInspectionFilter(
      structureId: 43,
    ).toJson();
    expect(body['structureId'], 43);
    expect(body['structureId'], isA<int>());
    expect(body['rfiCategory'], isNull);
    expect(body['projectId'], isNull);
    expect(body['itemId'], isNull);
    final Map<String, dynamic> decoded =
        jsonDecode(jsonEncode(body)) as Map<String, dynamic>;
    expect(decoded['structureId'], 43);
  });

  test('pdf bytes start with the pdf header without a logo', () async {
    final RfiLogReport report = RfiLogReport.fromJson(reportJson);
    final bytes = await RfiLogPdf.build(
      report: report,
      fonts: RfiLogPdfFonts.helvetica(),
    );

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(RfiLogPdf.sections(), hasLength(5));
  });

  test(
    'a logo that is not a real image is skipped and print still builds',
    () async {
      final RfiLogReport report = RfiLogReport.fromJson(reportJson);
      final Uint8List fakePng = Uint8List.fromList(<int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        1,
        2,
        3,
      ]);

      final Uint8List bytes = await RfiLogPdf.build(
        report: report,
        fonts: RfiLogPdfFonts.helvetica(),
        logoBytes: fakePng,
      );

      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    },
  );
}
