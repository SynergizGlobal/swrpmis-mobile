import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_permissions.dart';

void main() {
  group('rfiCanCreate', () {
    test('true for Contractor (userTypeFk Contractor)', () {
      expect(
        rfiCanCreate(
          userRoleNameFk: 'Regular User',
          userTypeFk: 'Contractor',
          departmentFk: 'CON',
          designation: 'Contractor Incharge',
          userId: 'PMIS_CO_037',
        ),
        isTrue,
      );
    });

    test('true for IT Admin role', () {
      expect(
        rfiCanCreate(
          userRoleNameFk: 'IT Admin',
          userTypeFk: 'Others',
          departmentFk: 'CO',
          designation: 'PMIS Team Lead',
          userId: 'PMIS_IT_001',
        ),
        isTrue,
      );
    });

    test('false for Super User sample (PMIS_SU_009)', () {
      expect(
        rfiCanCreate(
          userRoleNameFk: 'Super User',
          userTypeFk: 'HOD',
          departmentFk: 'Engg',
          designation: 'CE/CN/II/UBL',
          userId: 'PMIS_SU_009',
        ),
        isFalse,
      );
    });

    test('false for engineer / other non-creator roles', () {
      expect(
        rfiCanCreate(
          userRoleNameFk: 'Regular User',
          userTypeFk: 'Officer (Jr./Sr. Scale)',
        ),
        isFalse,
      );
      expect(
        rfiCanCreate(userRoleNameFk: 'Regular User', userTypeFk: 'HOD'),
        isFalse,
      );
    });
  });

  group('RfiPermissions.fromSession', () {
    test('Contractor can create', () {
      const AuthSession contractor = AuthSession(
        userId: 'PMIS_CO_037',
        userName: 'Contractor User',
        emailId: 'contractor@example.com',
        userRoleNameFk: 'Regular User',
        userTypeFk: 'Contractor',
        departmentFk: 'CON',
        designation: 'Contractor Incharge',
      );
      final RfiPermissions permissions = RfiPermissions.fromSession(contractor);
      expect(permissions.isContractorRole, isTrue);
      expect(permissions.isItAdmin, isFalse);
      expect(permissions.isSuperUser, isFalse);
      expect(permissions.canCreate, isTrue);
    });

    test('IT Admin can create', () {
      const AuthSession itAdmin = AuthSession(
        userId: 'PMIS_IT_001',
        userName: 'IT Admin',
        emailId: 'it@example.com',
        userRoleNameFk: 'IT Admin',
        userTypeFk: 'Others',
        departmentFk: 'CO',
        designation: 'PMIS Team Lead',
      );
      final RfiPermissions permissions = RfiPermissions.fromSession(itAdmin);
      expect(permissions.isItAdmin, isTrue);
      expect(permissions.canCreate, isTrue);
    });

    test('Super User cannot create', () {
      const AuthSession superUser = AuthSession(
        userId: 'PMIS_SU_009',
        userName: 'T VENKATESWARA RAO',
        emailId: 'su@example.com',
        userRoleNameFk: 'Super User',
        userTypeFk: 'HOD',
        departmentFk: 'Engg',
        designation: 'CE/CN/II/UBL',
      );
      final RfiPermissions permissions = RfiPermissions.fromSession(superUser);
      expect(permissions.isSuperUser, isTrue);
      expect(permissions.canCreate, isFalse);
    });

    test('null session cannot create', () {
      final RfiPermissions permissions = RfiPermissions.fromSession(null);
      expect(permissions.canCreate, isFalse);
    });
  });
}
