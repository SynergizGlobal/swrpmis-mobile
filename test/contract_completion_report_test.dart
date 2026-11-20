import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/bg_insurance_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_completion_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/list_of_contracts_report.dart';

void main() {
  test('detects Contract Completion Report by formId, url, and name', () {
    expect(
      isContractCompletionReport(
        formId: '1337',
        formName: 'Date of Completion Report',
        webFormUrl: 'contract-report/9',
      ),
      isTrue,
    );
    expect(
      isContractCompletionReport(
        formId: '',
        formName: 'Contract Completion Report',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isContractCompletionReport(
        formId: '',
        formName: 'Date of Completion Report',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isContractCompletionReport(
        formId: '',
        formName: 'Other',
        webFormUrl: 'contract-report/9',
      ),
      isTrue,
    );
    expect(
      isContractCompletionReport(
        formId: '',
        formName: 'Other',
        webFormUrl: 'contract-report/generate-contract-completion-report',
      ),
      isTrue,
    );
  });

  test('does not collide with other contract reports or letters', () {
    expect(
      isContractCompletionReport(
        formId: '1335',
        formName: 'List of Contracts',
        webFormUrl: 'contract-report/7',
      ),
      isFalse,
    );
    expect(
      isContractCompletionReport(
        formId: '1336',
        formName: 'BG/Insurance Report',
        webFormUrl: 'contract-report/8',
      ),
      isFalse,
    );
    expect(
      isContractCompletionReport(
        formId: '282',
        formName: 'Contract Detail',
        webFormUrl: 'contract-detail',
      ),
      isFalse,
    );
    expect(
      isContractCompletionReport(
        formId: '',
        formName: 'Date of Completion Letters',
        webFormUrl: '',
      ),
      isFalse,
    );
    expect(
      isListOfContractsReport(
        formId: '1337',
        formName: 'Date of Completion Report',
        webFormUrl: 'contract-report/9',
      ),
      isFalse,
    );
    expect(
      isBgInsuranceReport(
        formId: '1337',
        formName: 'Date of Completion Report',
        webFormUrl: 'contract-report/9',
      ),
      isFalse,
    );
  });

  test('parses projects, contractors with id-name label, HODs, and statuses', () {
    final List<ContractDetailOption> projects =
        parseContractCompletionProjects(<Map<String, dynamic>>[
          <String, dynamic>{
            'project_id': 'P01',
            'project_name': 'Bengaluru Railway Projects',
          },
        ]);
    expect(projects.single.id, 'P01');
    expect(projects.single.label, 'Bengaluru Railway Projects');

    final List<ContractDetailOption> contractors =
        parseContractCompletionContractors(<Map<String, dynamic>>[
          <String, dynamic>{
            'contractor_id_fk': 'CON0001',
            'contractor_id': 'CON0001',
            'contractor_name':
                'M/s GIRIRAJ CIVIL DEVELOPERS LIMITED - MUMBAI',
          },
        ]);
    expect(contractors.single.id, 'CON0001');
    expect(
      contractors.single.label,
      'CON0001 - M/s GIRIRAJ CIVIL DEVELOPERS LIMITED - MUMBAI',
    );

    final List<ContractDetailOption> hods =
        parseContractCompletionHods(<Map<String, dynamic>>[
          <String, dynamic>{
            'designation': 'CE/CN/IV/BNC',
            'user_name': 'John Doe',
          },
        ]);
    expect(hods.single.id, 'CE/CN/IV/BNC');
    expect(hods.single.label, 'John Doe (CE/CN/IV/BNC)');

    final List<ContractDetailOption> statuses =
        parseContractCompletionContractStatuses(<String, dynamic>{
          'contract_status_fk': 'Completed',
        });
    expect(statuses.single.id, 'Completed');
    expect(statuses.single.label, 'Completed');
  });
}
