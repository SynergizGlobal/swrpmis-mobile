import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/quality_test_register/domain/quality_test_register_list.dart';
import 'package:swr_pmis_mobile/src/features/quality_test_register/domain/quality_test_register_parse.dart';

void main() {
  test('parses obligation list with 0-based page metadata', () {
    final ({List<QualityTestObligationRow> rows, int total}) list =
        parseQualityTestObligationList(<String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 401,
              'obligationCode': 'QT-2026-EEA51',
              'projectId': 'P05',
              'projectName': null,
              'sectionName': 'Mangalore – Sakleshpur',
              'contractId': 'P05CN01',
              'contractName': null,
              'materialCode': null,
              'materialName': 'Blanketing',
              'testName': 'Area Test',
              'frequencyBasis': 'AREA_BASED',
              'generatedFrom': 'MANUAL',
              'obligationBasisCoverage': 'Retest of QT-2026-4047A',
              'requiredByDate': null,
              'contractorStatus': 'SUBMITTED',
              'engineerStatus': 'PENDING',
              'batchLotNo': null,
            },
            <String, dynamic>{
              'id': 400,
              'obligationCode': 'QT-2026-A7185',
              'projectId': 'P05',
              'materialCode': 'PNT-100',
              'materialName': null,
              'testName': 'Painting',
              'frequencyBasis': 'PER_BATCH_LOT',
              'generatedFrom': 'MANUAL',
              'obligationBasisCoverage': 'Retest',
              'requiredByDate': <int>[2026, 9, 30],
              'contractorStatus': 'SUBMITTED',
              'engineerStatus': 'NCR_RAISED',
              'batchLotNo': 'PNT-20260928-100',
              'sectionName': 'Mangalore – Sakleshpur',
              'contractId': 'P05CN01',
            },
          ],
          'totalRecords': 397,
          'totalPages': 199,
          'currentPage': 0,
          'pageSize': 2,
        });

    expect(list.total, 397);
    expect(list.rows, hasLength(2));
    expect(list.rows.first.obligationCode, 'QT-2026-EEA51');
    expect(list.rows.first.materialLabel, 'Blanketing');
    expect(list.rows.last.requiredByDate, '30-09-2026');
    expect(list.rows.last.batchLotNo, 'PNT-20260928-100');
    expect(formatQualityTestStatus('NCR_RAISED'), 'NCR RAISED');
  });

  test('list query uses 0-based page and documented filter params', () {
    const QualityTestRegisterListQuery query = QualityTestRegisterListQuery(
      projectId: 'P05',
      sectionId: '92',
      contractId: 'P05CN01',
      materialCode: 'PNT-100',
      testStatus: 'PENDING',
      dateFrom: '2026-09-01',
      dateTo: '2026-10-23',
      search: 'Painting',
      page: 2,
      pageSize: 10,
    );
    final Map<String, dynamic> params = query.listQueryParameters();
    expect(params['page'], 1);
    expect(params['size'], 10);
    expect(params['projectId'], 'P05');
    expect(params['sectionId'], '92');
    expect(params['contractId'], 'P05CN01');
    expect(params['materialCode'], 'PNT-100');
    expect(params['testStatus'], 'PENDING');
    expect(params['dateFrom'], '2026-09-01');
    expect(params['dateTo'], '2026-10-23');
    expect(params['q'], 'Painting');
  });

  test('parses obligation detail', () {
    final detail = parseQualityTestObligationDetail(<String, dynamic>{
      'id': 401,
      'obligationCode': 'QT-2026-EEA51',
      'projectId': 'P05',
      'sectionId': 92,
      'contractId': 'P05CN01',
      'materialName': 'Blanketing',
      'testName': 'Area Test',
      'generatedFrom': 'MANUAL',
      'obligationBasisCoverage': 'Retest',
      'contractorStatus': 'SUBMITTED',
      'engineerStatus': 'PENDING',
      'finalResult': 'good',
      'testDate': <int>[2026, 10, 8],
      'submittedOn': <int>[2026, 10, 5, 17, 53, 27],
    });
    expect(detail.id, 401);
    expect(detail.obligationCode, 'QT-2026-EEA51');
    expect(detail.testDate, '08-10-2026');
    expect(detail.submittedOn, '05-10-2026 17:53');
  });
}
