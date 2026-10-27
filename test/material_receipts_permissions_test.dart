import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipts_permissions.dart';

void main() {
  group('materialReceiptsIsRole', () {
    test('matches role case-insensitively with trim', () {
      expect(materialReceiptsIsRole('Contractor', 'Contractor'), isTrue);
      expect(materialReceiptsIsRole(' contractor ', 'Contractor'), isTrue);
      expect(materialReceiptsIsRole('IT ADMIN', 'IT Admin'), isTrue);
      expect(materialReceiptsIsRole('Super User', 'Contractor'), isFalse);
      expect(materialReceiptsIsRole('', 'Contractor'), isFalse);
    });
  });

  group('materialReceiptsCanCreate', () {
    test('true for Contractor role (sample PMIS_CO_037)', () {
      expect(
        materialReceiptsCanCreate(
          userRoleNameFk: 'Contractor',
          userTypeFk: 'Contractor',
          departmentFk: 'CON',
          designation: 'Contractor Incharge',
          userId: 'PMIS_CO_037',
        ),
        isTrue,
      );
    });

    test('true for IT Admin role (sample PMIS_IT_001)', () {
      expect(
        materialReceiptsCanCreate(
          userRoleNameFk: 'IT Admin',
          userTypeFk: 'Others',
          departmentFk: 'CO',
          designation: 'PMIS Team Lead',
          userId: 'PMIS_IT_001',
        ),
        isTrue,
      );
    });

    test('false for Super User / engineer sample (PMIS_SU_009)', () {
      expect(
        materialReceiptsCanCreate(
          userRoleNameFk: 'Super User',
          userTypeFk: 'HOD',
          departmentFk: 'Engg',
          designation: 'CE/CN/II/UBL',
          userId: 'PMIS_SU_009',
        ),
        isFalse,
      );
    });

    test('true for contractor / IT Admin regardless of casing', () {
      expect(
        materialReceiptsCanCreate(userRoleNameFk: ' contractor '),
        isTrue,
      );
      expect(
        materialReceiptsCanCreate(userRoleNameFk: ' it admin '),
        isTrue,
      );
    });
  });

  group('MaterialReceiptsPermissions.fromSession', () {
    test('maps session fields and applies Create rule', () {
      const AuthSession contractor = AuthSession(
        userId: 'PMIS_CO_037',
        userName: 'Contractor User',
        emailId: 'contractor@example.com',
        userRoleNameFk: 'Contractor',
        userTypeFk: 'Contractor',
        departmentFk: 'CON',
        designation: 'Contractor Incharge',
      );
      final MaterialReceiptsPermissions permissions =
          MaterialReceiptsPermissions.fromSession(contractor);
      expect(permissions.isContractorRole, isTrue);
      expect(permissions.isItAdmin, isFalse);
      expect(permissions.isFullAccess, isFalse);
      expect(permissions.canCreate, isTrue);
      expect(permissions.userId, 'PMIS_CO_037');
      expect(permissions.userTypeFk, 'Contractor');
      expect(permissions.designation, 'Contractor Incharge');
      expect(permissions.departmentFk, 'CON');
    });

    test('IT Admin has full access and can create', () {
      const AuthSession itAdmin = AuthSession(
        userId: 'PMIS_IT_001',
        userName: 'IT Admin',
        emailId: 'it@example.com',
        userRoleNameFk: 'IT Admin',
        userTypeFk: 'Others',
        departmentFk: 'CO',
        designation: 'PMIS Team Lead',
      );
      final MaterialReceiptsPermissions permissions =
          MaterialReceiptsPermissions.fromSession(itAdmin);
      expect(permissions.isItAdmin, isTrue);
      expect(permissions.isFullAccess, isTrue);
      expect(permissions.canCreate, isTrue);
    });

    test('null session cannot create', () {
      final MaterialReceiptsPermissions permissions =
          MaterialReceiptsPermissions.fromSession(null);
      expect(permissions.isContractorRole, isFalse);
      expect(permissions.isItAdmin, isFalse);
      expect(permissions.canCreate, isFalse);
    });
  });
}
