import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_menu.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_user_role.dart';

void main() {
  test(
    'contractor nav is dashboard, inspection, and log, with three create actions',
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
          'Create Material RFI',
          'Create Work RFI',
          'Create Quality/Safety RFI',
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
      expect(RfiMenuItem.createItemsFor(role), isEmpty);
    },
  );

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
