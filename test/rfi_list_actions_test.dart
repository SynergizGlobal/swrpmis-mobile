import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_list_actions.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_user_role.dart';

void main() {
  group('rfiListRowActions', () {
    test('contractor + canModify gets Edit/Delete on CREATED and OPEN', () {
      for (final String status in <String>['CREATED', 'OPEN', 'REASSIGNED']) {
        final List<RfiListRowAction> actions = rfiListRowActions(
          role: RfiUserRole.contractor,
          status: status,
          canModify: true,
        );
        expect(actions, contains(RfiListRowAction.viewDetails));
        expect(actions, contains(RfiListRowAction.editRfi));
        expect(actions, contains(RfiListRowAction.deleteRfi));
      }
    });

    test('viewOnly blocks Edit/Delete even for contractor', () {
      final List<RfiListRowAction> actions = rfiListRowActions(
        role: RfiUserRole.contractor,
        status: 'CREATED',
        canModify: false,
      );
      expect(actions, <RfiListRowAction>[RfiListRowAction.viewDetails]);
    });

    test('CON_INSP_ONGOING is view-only for contractor (no edit/delete)', () {
      final List<RfiListRowAction> actions = rfiListRowActions(
        role: RfiUserRole.contractor,
        status: 'CON_INSP_ONGOING',
        canModify: true,
      );
      expect(actions, isNot(contains(RfiListRowAction.editRfi)));
      expect(actions, isNot(contains(RfiListRowAction.deleteRfi)));
      expect(actions, contains(RfiListRowAction.viewDetails));
    });

    test('contractor rep gets start/submit on early statuses', () {
      final List<RfiListRowAction> actions = rfiListRowActions(
        role: RfiUserRole.contractorRep,
        status: 'CREATED',
        canModify: false,
      );
      expect(actions, contains(RfiListRowAction.viewDetails));
      expect(actions, contains(RfiListRowAction.startOnline));
      expect(actions, contains(RfiListRowAction.startOffline));
      expect(actions, contains(RfiListRowAction.submit));
      expect(actions, isNot(contains(RfiListRowAction.editRfi)));
    });

    test('engineer does not get Edit; may get Change Executive', () {
      final List<RfiListRowAction> actions = rfiListRowActions(
        role: RfiUserRole.engineer,
        status: 'CREATED',
        canModify: true,
      );
      expect(actions, contains(RfiListRowAction.viewDetails));
      expect(actions, isNot(contains(RfiListRowAction.editRfi)));
      expect(actions, contains(RfiListRowAction.changeExecutive));
    });

    test('IT Admin can delete any status when canModify', () {
      final List<RfiListRowAction> actions = rfiListRowActions(
        role: RfiUserRole.itAdmin,
        status: 'INSPECTION_DONE',
        canModify: true,
      );
      expect(actions, contains(RfiListRowAction.deleteRfi));
      expect(actions, isNot(contains(RfiListRowAction.editRfi)));
    });
  });

  group('canEditRfi', () {
    test('matches WCR editable statuses including OPEN', () {
      expect(RfiUserRole.contractor.canEditRfi('OPEN'), isTrue);
      expect(RfiUserRole.contractor.canEditRfi('CREATED'), isTrue);
      expect(RfiUserRole.contractor.canEditRfi('CON_INSP_ONGOING'), isFalse);
      expect(RfiUserRole.engineer.canEditRfi('CREATED'), isFalse);
    });
  });
}
