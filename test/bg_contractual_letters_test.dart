import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/bg_contractual_letters.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/bg_insurance_report.dart';

void main() {
  test('detects BG Contractual Letters by formId, url, and name', () {
    expect(
      isBgContractualLettersReport(
        formId: '1369',
        formName: 'BG Contractual Letters',
        webFormUrl: 'bg-contractual-letters',
      ),
      isTrue,
    );
    expect(
      isBgContractualLettersReport(
        formId: '',
        formName: 'BG Contractual Letters',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isBgContractualLettersReport(
        formId: '',
        formName: 'Other',
        webFormUrl: 'bg-contractual-letters',
      ),
      isTrue,
    );
    expect(
      isBgContractualLettersReport(
        formId: '',
        formName: 'Other',
        webFormUrl: 'ajax/generate-bg-contractual-letters',
      ),
      isTrue,
    );
    expect(
      isBgContractualLettersReport(
        formId: '',
        formName: 'List of Contracts Closer to BG Expiry Date',
        webFormUrl: '',
      ),
      isTrue,
    );
  });

  test('does not collide with BG/Insurance Report', () {
    expect(
      isBgContractualLettersReport(
        formId: '1336',
        formName: 'BG/Insurance Report',
        webFormUrl: 'contract-report/8',
      ),
      isFalse,
    );
    expect(
      isBgInsuranceReport(
        formId: '1369',
        formName: 'BG Contractual Letters',
        webFormUrl: 'bg-contractual-letters',
      ),
      isFalse,
    );
  });

  test('parses list at root and nested aaData/data shapes', () {
    final List<BgContractualLetterRow> root = parseBgContractualLetters(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'contract_id': 'C-1',
          'contract_short_name': 'Short',
          'contractor_name': 'Acme',
          'bg_type': 'Performance',
          'issuing_bank': 'SBI',
          'bg_number': 'BG-9',
          'amount': '1000',
          'expiry_date': '2026-12-01',
          'status': 'Active',
        },
      ],
    );
    expect(root, hasLength(1));
    expect(root.first.contractId, 'C-1');
    expect(root.first.issuingBank, 'SBI');

    final List<BgContractualLetterRow> nested = parseBgContractualLetters(
      <String, dynamic>{
        'aaData': <Map<String, dynamic>>[
          <String, dynamic>{
            'contractId': 'C-2',
            'contractorName': 'Beta',
            'bgType': 'Advance',
          },
        ],
      },
    );
    expect(nested, hasLength(1));
    expect(nested.first.contractId, 'C-2');
    expect(nested.first.contractorName, 'Beta');
    expect(nested.first.bgType, 'Advance');

    expect(parseBgContractualLetters(<String, dynamic>{'data': <Object>[]}), isEmpty);
  });

  test('throws a clear message for unexpected HTML', () {
    expect(
      () => parseBgContractualLetters('<html><body>oops</body></html>'),
      throwsA(
        isA<StateError>().having(
          (StateError e) => e.message,
          'message',
          contains('Unexpected HTML'),
        ),
      ),
    );
  });
}
