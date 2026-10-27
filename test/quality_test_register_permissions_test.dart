import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:swr_pmis_mobile/src/features/quality_test_register/domain/quality_test_register_permissions.dart';

void main() {
  group('qualityTestRegisterIsContractorRole', () {
    test('matches Contractor case-insensitively with trim', () {
      expect(qualityTestRegisterIsContractorRole('Contractor'), isTrue);
      expect(qualityTestRegisterIsContractorRole(' contractor '), isTrue);
      expect(qualityTestRegisterIsContractorRole('CONTRACTOR'), isTrue);
      expect(qualityTestRegisterIsContractorRole('Super User'), isFalse);
      expect(qualityTestRegisterIsContractorRole('Data Admin'), isFalse);
      expect(qualityTestRegisterIsContractorRole(''), isFalse);
    });
  });

  group('qualityTestRegisterCanCreate', () {
    test('false for Contractor role (sample PMIS_CO_003)', () {
      expect(
        qualityTestRegisterCanCreate(
          userRoleNameFk: 'Contractor',
          userTypeFk: 'Contractor Rep',
          departmentFk: 'Engg',
          designation: 'ENGINEER QUALITY CONTROL',
        ),
        isFalse,
      );
    });

    test('true for non-Contractor roles', () {
      expect(
        qualityTestRegisterCanCreate(userRoleNameFk: 'Super User'),
        isTrue,
      );
      expect(
        qualityTestRegisterCanCreate(userRoleNameFk: 'Data Admin'),
        isTrue,
      );
      expect(
        qualityTestRegisterCanCreate(userRoleNameFk: 'Engineer'),
        isTrue,
      );
    });

    test('false for contractor role regardless of casing', () {
      expect(
        qualityTestRegisterCanCreate(userRoleNameFk: ' contractor '),
        isFalse,
      );
    });
  });

  group('QualityTestRegisterPermissions.fromSession', () {
    test('maps session fields and applies Create rule', () {
      const AuthSession contractor = AuthSession(
        userId: 'PMIS_CO_003',
        userName: 'SHANI YADAV',
        emailId: 'sateesh.r@synergizglobal.com',
        userRoleNameFk: 'Contractor',
        userTypeFk: 'Contractor Rep',
        departmentFk: 'Engg',
        designation: 'ENGINEER QUALITY CONTROL',
      );
      final QualityTestRegisterPermissions permissions =
          QualityTestRegisterPermissions.fromSession(contractor);
      expect(permissions.isContractorRole, isTrue);
      expect(permissions.canCreate, isFalse);
      expect(permissions.userTypeFk, 'Contractor Rep');
      expect(permissions.designation, 'ENGINEER QUALITY CONTROL');
      expect(permissions.departmentFk, 'Engg');
    });

    test('null session cannot create as contractor and allows create default', () {
      final QualityTestRegisterPermissions permissions =
          QualityTestRegisterPermissions.fromSession(null);
      expect(permissions.isContractorRole, isFalse);
      expect(permissions.canCreate, isTrue);
    });
  });
}
