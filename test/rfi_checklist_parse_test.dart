import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_checklist_item.dart';

void main() {
  test('reads the checklist-items object the API returns', () {
    final List<RfiChecklistItem> items = parseRfiChecklistItems(
      <String, dynamic>{
        'gradeOfConcrete': 'M30',
        'rfiDescription': 'Concreting',
        'enclosureName': 'RCC Works - Concrete',
        'checklistItems': <Map<String, dynamic>>[
          <String, dynamic>{
            'checklistDescId': 86,
            'checklistDescription': 'DRAWING APPROVED AND AVAILABLE',
            'contractorStatus': null,
            'engineerStatus': null,
            'contractorRemarks': null,
            'engineerRemark': null,
          },
          <String, dynamic>{
            'checklistDescId': 87,
            'checklistDescription':
                'ACCESS AND WALKWAY FOR CHECKING IS AVAILABLE',
            'contractorStatus': 'YES',
            'engineerStatus': null,
            'contractorRemarks': 'testing',
            'engineerRemark': null,
          },
        ],
      },
    );
    expect(items, hasLength(2));
    expect(items.first.checklistDescId, 86);
    expect(items.first.contractorStatus, isEmpty);
    expect(items[1].contractorStatus, 'YES');
    expect(items[1].contractorRemarks, 'testing');
    expect(items.first.gradeOfConcrete, 'M30');
    expect(items.first.enclosureName, 'RCC Works - Concrete');
  });

  test('save rows match the web payload keys', () {
    final RfiChecklistItem item = parseRfiChecklistItems(<String, dynamic>{
      'checklistItems': <Map<String, dynamic>>[
        <String, dynamic>{
          'checklistDescId': 86,
          'checklistDescription': 'DRAWING APPROVED AND AVAILABLE',
        },
      ],
    }).single.copyWith(contractorStatus: 'YES', contractorRemarks: 'testing');
    expect(item.toSaveRowJson(), <String, dynamic>{
      'checklistDescriptionId': 86,
      'description': 'DRAWING APPROVED AND AVAILABLE',
      'contractorStatus': 'YES',
      'engineerStatus': '',
      'contractorRemark': 'testing',
      'aeRemark': '',
    });
  });

  test('a bare list still parses', () {
    expect(
      parseRfiChecklistItems(<Map<String, dynamic>>[
        <String, dynamic>{'checklistDescId': 1, 'checklistDescription': 'A'},
      ]),
      hasLength(1),
    );
  });
}
