import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_category_access.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_list_kind.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_table.dart';

void main() {
  group('category-view-only', () {
    test('reads the web response', () {
      expect(parseRfiViewOnly(<String, dynamic>{'viewOnly': false}), isFalse);
      expect(parseRfiViewOnly(<String, dynamic>{'viewOnly': true}), isTrue);
      expect(parseRfiViewOnly(<String, dynamic>{'viewOnly': 'false'}), isFalse);
    });

    test('treats an unreadable response as view-only', () {
      expect(parseRfiViewOnly(null), isTrue);
      expect(parseRfiViewOnly(<String, dynamic>{}), isTrue);
    });
  });

  group('can-create', () {
    test('reads the web response', () {
      expect(
        parseRfiCanCreate(<String, dynamic>{
          'rfiCategory': 'WORK',
          'canCreate': true,
        }),
        isTrue,
      );
      expect(
        parseRfiCanCreate(<String, dynamic>{
          'rfiCategory': 'WORK',
          'canCreate': false,
        }),
        isFalse,
      );
    });

    test('treats an unreadable response as not allowed', () {
      expect(parseRfiCanCreate(null), isFalse);
      expect(parseRfiCanCreate('oops'), isFalse);
    });
  });

  test('view-only blocks Add even when create is allowed', () {
    const RfiCategoryAccess access = RfiCategoryAccess(
      viewOnly: true,
      canCreate: true,
    );
    expect(access.canAdd, isFalse);
    expect(access.canModify, isFalse);
  });

  test('work table drops the Actions column when view-only', () {
    final List<String> labels = rfiTableColumns(
      RfiListKind.work,
      showActions: false,
    ).map((RfiTableColumn c) => c.label).toList();
    expect(labels, isNot(contains('Actions')));
    expect(labels.last, 'Status');
  });

  group('work row actions', () {
    test('Edit only while CREATED or RESCHEDULED, like the web', () {
      expect(rfiWorkRowEditable('CREATED'), isTrue);
      expect(rfiWorkRowEditable('RESCHEDULED'), isTrue);
      expect(rfiWorkRowEditable('UPDATED'), isTrue);
      expect(rfiWorkRowEditable('CON_INSP_ONGOING'), isFalse);
      expect(rfiWorkRowEditable('INSPECTION_DONE'), isFalse);
      expect(rfiWorkRowEditable('AE_INSP_PENDING'), isFalse);
    });
  });

  test('status tones follow the web badges', () {
    expect(rfiStatusTone('CREATED'), RfiStatusTone.created);
    expect(rfiStatusTone('RESCHEDULED'), RfiStatusTone.rescheduled);
    expect(rfiStatusTone('INSPECTION_DONE'), RfiStatusTone.done);
    expect(rfiStatusTone('AE_INSP_PENDING'), RfiStatusTone.pending);
    expect(rfiStatusTone('UPDATED'), RfiStatusTone.updated);
    expect(rfiStatusTone('CON_INSP_ONGOING'), RfiStatusTone.ongoing);
    expect(rfiStatusTone('REJECTED'), RfiStatusTone.rejected);
  });

  test('delete reads the plain-text server message', () {
    expect(
      rfiDeleteMessage('RFI marked as deleted successfully!'),
      'RFI marked as deleted successfully!',
    );
    expect(rfiDeleteMessage(<String, dynamic>{'message': 'Done'}), 'Done');
    expect(rfiDeleteMessage(null), rfiDeleteDefaultMessage);
    expect(rfiDeleteMessage(''), rfiDeleteDefaultMessage);
  });
}
