import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/list_of_contracts_report.dart';

void main() {
  test('detects List of Contracts and excludes List of Contractors', () {
    expect(
      isListOfContractsReport(
        formId: '1335',
        formName: 'List of Contracts',
        webFormUrl: 'contract-report/7',
      ),
      isTrue,
    );
    expect(
      isListOfContractsReport(
        formId: '',
        formName: 'List of Contracts',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isListOfContractsReport(
        formId: '',
        formName: 'Other',
        webFormUrl: 'contract-report/7',
      ),
      isTrue,
    );
    expect(
      isListOfContractsReport(
        formId: '290',
        formName: 'List of Contractors',
        webFormUrl: 'contractorslist',
      ),
      isFalse,
    );
    expect(
      isListOfContractsReport(
        formId: '999',
        formName: 'Other',
        webFormUrl: 'contract-report/contractorslist',
      ),
      isFalse,
    );
    expect(
      isListOfContractsReport(
        formId: '',
        formName: 'List of Contractors',
        webFormUrl: '',
      ),
      isFalse,
    );
    expect(
      isListOfContractsReport(
        formId: '285',
        formName: 'Contract Detail',
        webFormUrl: 'contract-report/2',
      ),
      isFalse,
    );
  });

  test('parses Status of Work and Contract Status payloads', () {
    final List<ContractDetailOption> workStatuses =
        parseListOfContractsWorkStatuses(<String, dynamic>{'status': 'Open'});
    expect(workStatuses.single.id, 'Open');
    expect(workStatuses.single.label, 'Open');

    final List<ContractDetailOption> contractStatuses =
        parseListOfContractsContractStatuses(<String, dynamic>{
          'contract_status_fk': 'Completed',
        });
    expect(contractStatuses.single.id, 'Completed');
    expect(contractStatuses.single.label, 'Completed');
  });
}
