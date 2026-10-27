import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_menu_access.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_menu.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_user_role.dart';

void main() {
  test(
    'contractor nav is dashboard, inspection, and log, with three RFI list shortcuts',
    () {
      final RfiUserRole role = RfiUserRoleResolver.fromFields(
        userTypeFk: 'Contractor',
        userRoleNameFk: 'Regular User',
      );

      expect(
        RfiMenuItem.navItemsFor(role).map((RfiMenuItem item) => item.id),
        <RfiMenuId>[RfiMenuId.home, RfiMenuId.inspection, RfiMenuId.log],
      );
      expect(
        RfiMenuItem.createItemsFor(role).map((RfiMenuItem item) => item.title),
        <String>[
          'Material RFI',
          'Work RFI',
          'Quality/Safety RFI',
        ],
      );
      expect(RfiMenuItem.navBarFor(role).overflow, isEmpty);
      expect(RfiMenuItem.navItemsFor(role).first.navLabel, 'Dashboard');
    },
  );

  test(
    'engineer nav is dashboard, inspection, validation, log, and assign',
    () {
      final RfiUserRole role = RfiUserRoleResolver.fromFields(
        userTypeFk: 'Officer (Jr./Sr. Scale)',
        userRoleNameFk: 'Regular User',
      );

      expect(
        RfiMenuItem.navItemsFor(role).map((RfiMenuItem item) => item.id),
        <RfiMenuId>[
          RfiMenuId.home,
          RfiMenuId.inspection,
          RfiMenuId.validation,
          RfiMenuId.log,
          RfiMenuId.assignExecutive,
        ],
      );
      expect(
        RfiMenuItem.createItemsFor(role).map((RfiMenuItem item) => item.id),
        <RfiMenuId>[
          RfiMenuId.createMaterial,
          RfiMenuId.createWork,
          RfiMenuId.createQuality,
        ],
      );
    },
  );

  test('super user gets FAB list shortcuts without create permission', () {
    final RfiUserRole role = RfiUserRoleResolver.fromFields(
      userTypeFk: 'HOD',
      userRoleNameFk: 'Super User',
    );

    expect(role.canCreateRfi, isFalse);
    expect(
      RfiMenuItem.createItemsFor(role).map((RfiMenuItem item) => item.title),
      <String>[
        'Material RFI',
        'Work RFI',
        'Quality/Safety RFI',
      ],
    );
  });

  test('menu-access flags drive visibility independently of create permission', () {
    final RfiUserRole role = RfiUserRoleResolver.fromFields(
      userTypeFk: 'HOD',
      userRoleNameFk: 'Super User',
    );
    const RfiMenuAccess access = RfiMenuAccess(
      showHome: true,
      showMaterialRfi: true,
      showWorkRfi: true,
      showQualitySafetyRfi: true,
      showInspection: true,
      showValidation: true,
      showRfiLog: true,
      showAssignExecutive: true,
      showReferenceForms: true,
    );

    expect(role.canCreateRfi, isFalse);
    expect(
      RfiMenuItem.visibleFor(role, access: access).map((RfiMenuItem i) => i.id),
      RfiMenuItem.all.map((RfiMenuItem i) => i.id),
    );
    expect(
      RfiMenuItem.createItemsFor(role, access: access)
          .map((RfiMenuItem i) => i.id),
      <RfiMenuId>[
        RfiMenuId.createMaterial,
        RfiMenuId.createWork,
        RfiMenuId.createQuality,
      ],
    );
  });

  test('menu-access can hide RFI list shortcuts and nav tabs', () {
    final RfiUserRole role = RfiUserRoleResolver.fromFields(
      userTypeFk: 'Contractor',
      userRoleNameFk: 'Regular User',
    );
    const RfiMenuAccess access = RfiMenuAccess(
      showHome: true,
      showMaterialRfi: false,
      showWorkRfi: true,
      showQualitySafetyRfi: false,
      showInspection: true,
      showValidation: false,
      showRfiLog: true,
      showAssignExecutive: false,
      showReferenceForms: false,
    );

    expect(
      RfiMenuItem.createItemsFor(role, access: access)
          .map((RfiMenuItem i) => i.id),
      <RfiMenuId>[RfiMenuId.createWork],
    );
    expect(
      RfiMenuItem.navItemsFor(role, access: access)
          .map((RfiMenuItem i) => i.id),
      <RfiMenuId>[RfiMenuId.home, RfiMenuId.inspection, RfiMenuId.log],
    );
  });

  test('RfiMenuAccess parses boolean flags from API json', () {
    final RfiMenuAccess access = RfiMenuAccess.fromJson(<String, dynamic>{
      'showHome': true,
      'showMaterialRfi': 'true',
      'showWorkRfi': 1,
      'showQualitySafetyRfi': false,
      'showInspection': 'yes',
      'showValidation': 0,
      'showRfiLog': true,
      'showAssignExecutive': 'false',
      'showReferenceForms': true,
    });

    expect(access.showHome, isTrue);
    expect(access.showMaterialRfi, isTrue);
    expect(access.showWorkRfi, isTrue);
    expect(access.showQualitySafetyRfi, isFalse);
    expect(access.showInspection, isTrue);
    expect(access.showValidation, isFalse);
    expect(access.showRfiLog, isTrue);
    expect(access.showAssignExecutive, isFalse);
    expect(access.showReferenceForms, isTrue);
  });

  test('IT admin sees every RFI menu item', () {
    final RfiUserRole role = RfiUserRoleResolver.fromFields(
      userTypeFk: 'HOD',
      userRoleNameFk: 'IT Admin',
    );

    expect(RfiMenuItem.visibleFor(role).length, RfiMenuItem.all.length);
    expect(
      RfiMenuItem.navItemsFor(role).map((RfiMenuItem item) => item.id),
      <RfiMenuId>[
        RfiMenuId.home,
        RfiMenuId.inspection,
        RfiMenuId.validation,
        RfiMenuId.log,
        RfiMenuId.assignExecutive,
        RfiMenuId.inspectionReference,
      ],
    );
    final ({List<RfiMenuItem> bar, List<RfiMenuItem> overflow}) nav =
        RfiMenuItem.navBarFor(role);
    expect(nav.bar.map((RfiMenuItem item) => item.id), <RfiMenuId>[
      RfiMenuId.home,
      RfiMenuId.inspection,
      RfiMenuId.validation,
      RfiMenuId.log,
    ]);
    expect(nav.overflow.map((RfiMenuItem item) => item.id), <RfiMenuId>[
      RfiMenuId.assignExecutive,
      RfiMenuId.inspectionReference,
    ]);
  });
}
