import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/bg_contractual_letters.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/insurance_contractual_letters.dart';

void main() {
  test('detects Insurance Contractual Letters by formId, url, and name', () {
    expect(
      isInsuranceContractualLettersReport(
        formId: '1370',
        formName: 'Insurance Contractual Letters',
        webFormUrl: 'insurance-contractual-letters',
      ),
      isTrue,
    );
    expect(
      isInsuranceContractualLettersReport(
        formId: '',
        formName: 'Insurance Contractual Letters',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isInsuranceContractualLettersReport(
        formId: '',
        formName: 'List of Contracts Closer to Insurance Expiry Date',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isInsuranceContractualLettersReport(
        formId: '',
        formName: 'Other',
        webFormUrl: 'insurance-contractual-letters',
      ),
      isTrue,
    );
  });

  test('does not collide with BG letters or Date of Completion Letters', () {
    expect(
      isInsuranceContractualLettersReport(
        formId: '1369',
        formName: 'BG Contractual Letters',
        webFormUrl: 'bg-contractual-letters',
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
    expect(
      isInsuranceContractualLettersReport(
        formId: '',
        formName: 'BG Contractual Letters',
        webFormUrl: '',
      ),
      isFalse,
    );
    expect(
      isBgContractualLettersReport(
        formId: '1370',
        formName: 'Insurance Contractual Letters',
        webFormUrl: 'insurance-contractual-letters',
      ),
      isFalse,
    );
  });
}
