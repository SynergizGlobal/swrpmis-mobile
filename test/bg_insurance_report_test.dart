import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/bg_insurance_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/list_of_contracts_report.dart';

void main() {
  test('detects BG/Insurance Report by formId, url, and name', () {
    expect(
      isBgInsuranceReport(
        formId: '1336',
        formName: 'BG/Insurance Report',
        webFormUrl: 'contract-report/8',
      ),
      isTrue,
    );
    expect(
      isBgInsuranceReport(
        formId: '',
        formName: 'BG/Insurance Report',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isBgInsuranceReport(
        formId: '',
        formName: 'Other',
        webFormUrl: 'contract-report/8',
      ),
      isTrue,
    );
    expect(
      isBgInsuranceReport(
        formId: '',
        formName: 'Other',
        webFormUrl: 'contract-report/generate-bg-insurance-report',
      ),
      isTrue,
    );
  });

  test('does not collide with List of Contracts or Contract Detail', () {
    expect(
      isBgInsuranceReport(
        formId: '1335',
        formName: 'List of Contracts',
        webFormUrl: 'contract-report/7',
      ),
      isFalse,
    );
    expect(
      isListOfContractsReport(
        formId: '1336',
        formName: 'BG/Insurance Report',
        webFormUrl: 'contract-report/8',
      ),
      isFalse,
    );
    expect(
      isBgInsuranceReport(
        formId: '282',
        formName: 'Contract Detail',
        webFormUrl: 'contract-detail',
      ),
      isFalse,
    );
  });

  test('parses projects, contractors with id-name label, and statuses', () {
    final List<ContractDetailOption> projects = parseBgInsuranceProjects(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'project_id': 'P01',
          'project_name': 'Bengaluru Railway Projects',
        },
      ],
    );
    expect(projects.single.id, 'P01');
    expect(projects.single.label, 'Bengaluru Railway Projects');

    final List<ContractDetailOption> contractors = parseBgInsuranceContractors(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'contractor_id_fk': '42',
          'contractor_id': 'CON0001',
          'contractor_name':
              'M/s GIRIRAJ CIVIL DEVELOPERS LIMITED - MUMBAI',
        },
      ],
    );
    expect(contractors.single.id, '42');
    expect(
      contractors.single.label,
      'CON0001 - M/s GIRIRAJ CIVIL DEVELOPERS LIMITED - MUMBAI',
    );

    final List<ContractDetailOption> statuses =
        parseBgInsuranceContractStatuses(<String, dynamic>{
          'contract_status_fk': 'Completed',
        });
    expect(statuses.single.id, 'Completed');
    expect(statuses.single.label, 'Completed');
  });
}
