import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/bg_contractual_letters.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_completion_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/doc_contractual_letters.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/insurance_contractual_letters.dart';

void main() {
  test('detects Date of Completion Letters by formId, url, and name', () {
    expect(
      isDocContractualLettersReport(
        formId: '1371',
        formName: 'Date of Completion Letters',
        webFormUrl: 'doc-contractual-letters',
      ),
      isTrue,
    );
    expect(
      isDocContractualLettersReport(
        formId: '',
        formName: 'Date of Completion Letters',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isDocContractualLettersReport(
        formId: '',
        formName: 'List of Contracts Closer to DOC Expiry Date',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isDocContractualLettersReport(
        formId: '',
        formName: 'Other',
        webFormUrl: 'doc-contractual-letters',
      ),
      isTrue,
    );
  });

  test(
    'does not collide with Date of Completion Report or sibling letters',
    () {
      expect(
        isDocContractualLettersReport(
          formId: '1337',
          formName: 'Date of Completion Report',
          webFormUrl: 'contract-report/9',
        ),
        isFalse,
      );
      expect(
        isDocContractualLettersReport(
          formId: '',
          formName: 'Contract Completion Report',
          webFormUrl: '',
        ),
        isFalse,
      );
      expect(
        isDocContractualLettersReport(
          formId: '1369',
          formName: 'BG Contractual Letters',
          webFormUrl: 'bg-contractual-letters',
        ),
        isFalse,
      );
      expect(
        isDocContractualLettersReport(
          formId: '1370',
          formName: 'Insurance Contractual Letters',
          webFormUrl: 'insurance-contractual-letters',
        ),
        isFalse,
      );
      expect(
        isContractCompletionReport(
          formId: '1371',
          formName: 'Date of Completion Letters',
          webFormUrl: 'doc-contractual-letters',
        ),
        isFalse,
      );
      expect(
        isBgContractualLettersReport(
          formId: '1371',
          formName: 'Date of Completion Letters',
          webFormUrl: 'doc-contractual-letters',
        ),
        isFalse,
      );
      expect(
        isInsuranceContractualLettersReport(
          formId: '1371',
          formName: 'Date of Completion Letters',
          webFormUrl: 'doc-contractual-letters',
        ),
        isFalse,
      );
    },
  );
}
