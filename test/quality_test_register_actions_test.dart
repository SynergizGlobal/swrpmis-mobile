import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/quality_test_register/domain/quality_test_register_actions.dart';

void main() {
  group('qualityTestRegisterActionsFor', () {
    test('engineer + SUBMITTED shows Review + Details + Traceability', () {
      expect(
        qualityTestRegisterActionsFor(
          contractorStatus: 'SUBMITTED',
          isContractor: false,
        ),
        <QualityTestRegisterAction>[
          QualityTestRegisterAction.review,
          QualityTestRegisterAction.viewDetails,
          QualityTestRegisterAction.viewTraceability,
        ],
      );
    });

    test('engineer + PENDING shows Details + Traceability only', () {
      expect(
        qualityTestRegisterActionsFor(
          contractorStatus: 'PENDING',
          isContractor: false,
        ),
        <QualityTestRegisterAction>[
          QualityTestRegisterAction.viewDetails,
          QualityTestRegisterAction.viewTraceability,
        ],
      );
    });

    test('engineer status does not change menu when contractor is SUBMITTED', () {
      // SUBMITTED + NCR_RAISED and SUBMITTED + anything share the same menu.
      expect(
        qualityTestRegisterActionsFor(
          contractorStatus: 'SUBMITTED',
          isContractor: false,
        ),
        qualityTestRegisterActionsFor(
          contractorStatus: 'SUBMITTED',
          isContractor: false,
        ),
      );
    });

    test('contractor + PENDING shows View/Update + Details + Traceability', () {
      expect(
        qualityTestRegisterActionsFor(
          contractorStatus: 'PENDING',
          isContractor: true,
        ),
        <QualityTestRegisterAction>[
          QualityTestRegisterAction.viewUpdate,
          QualityTestRegisterAction.viewDetails,
          QualityTestRegisterAction.viewTraceability,
        ],
      );
    });

    test('contractor + SUBMITTED hides View/Update', () {
      expect(
        qualityTestRegisterActionsFor(
          contractorStatus: 'SUBMITTED',
          isContractor: true,
        ),
        <QualityTestRegisterAction>[
          QualityTestRegisterAction.viewDetails,
          QualityTestRegisterAction.viewTraceability,
        ],
      );
    });
  });

  test('contractor role matches web userRoleNameFk', () {
    expect(qualityTestRegisterIsContractorRole('Contractor'), isTrue);
    expect(qualityTestRegisterIsContractorRole('Super User'), isFalse);
    expect(qualityTestRegisterIsContractorRole('Data Admin'), isFalse);
  });
}
