import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/list_of_contractors_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/list_of_contracts_report.dart';

void main() {
  test('detects List of Contractors by name, url, and formId', () {
    expect(
      isListOfContractorsReport(
        formId: '290',
        formName: 'List of Contractors',
        webFormUrl: 'contractorslist',
      ),
      isTrue,
    );
    expect(
      isListOfContractorsReport(
        formId: '',
        formName: 'List of Contractors',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isListOfContractorsReport(
        formId: '',
        formName: 'Other',
        webFormUrl: 'contractorslist',
      ),
      isTrue,
    );
    expect(
      isListOfContractorsReport(
        formId: '',
        formName: 'Other',
        webFormUrl: 'contract-report/contractorslist',
      ),
      isTrue,
    );
    expect(
      isListOfContractorsReport(
        formId: '290',
        formName: '',
        webFormUrl: '',
      ),
      isTrue,
    );
  });

  test('does not collide with List of Contracts or Contract Detail', () {
    expect(
      isListOfContractorsReport(
        formId: '1335',
        formName: 'List of Contracts',
        webFormUrl: 'contract-report/7',
      ),
      isFalse,
    );
    expect(
      isListOfContractorsReport(
        formId: '',
        formName: 'List of Contracts',
        webFormUrl: '',
      ),
      isFalse,
    );
    expect(
      isListOfContractorsReport(
        formId: '285',
        formName: 'Contract Detail',
        webFormUrl: 'contract-report/2',
      ),
      isFalse,
    );
    expect(
      isListOfContractsReport(
        formId: '290',
        formName: 'List of Contractors',
        webFormUrl: 'contractorslist',
      ),
      isFalse,
    );
  });
}
