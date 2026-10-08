import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_list_item.dart';

void main() {
  test('work sample maps scheduled text 01-10-2026 14:30', () {
    final RfiListItem item = RfiListItem.fromJson(<String, dynamic>{
      'id': 57,
      'rfiId': 'RFI_W_RUB_36838_EXCL_EXC_0001',
      'rfiCategory': 'WORK',
      'projectName': '4th Line between Itarsi - Bhopal - Bina',
      'item': null,
      'material': null,
      'location': null,
      'batchLotNo': null,
      'structure': '43 (RCC Box)',
      'structureType': 'Important Bridge',
      'element': 'Excavation',
      'nameOfRepresentative': 'IT Test Contractor Rep',
      'assignedPersonClient': null,
      'contractName': 'EPC Contract for Important Bridges...',
      'dateOfSubmission': '01-10-2026',
      'dateOfInspection': '01-10-2026',
      'timeOfInspection': '14:30',
      'contractorSubmittedOn': '01-10-2026 16:40',
      'rfiStatus': 'AE_INSP_ONGOING',
    });

    expect(item.id, 57);
    expect(item.rfiId, 'RFI_W_RUB_36838_EXCL_EXC_0001');
    expect(item.scheduledText, '01-10-2026 14:30');
    expect(item.statusLabel, 'AE INSP ONGOING');
    expect(item.assignedPersonClient, isEmpty);
    expect(item.item, isEmpty);
    expect(item.structure, '43 (RCC Box)');
    expect(item.element, 'Excavation');
  });

  test('id accepts num and string, and missing fields stay blank', () {
    final RfiListItem item = RfiListItem.fromJson(<String, dynamic>{
      'id': 57.0,
      'rfiStatus': null,
    });

    expect(item.id, 57);
    expect(item.rfiId, isEmpty);
    expect(item.scheduledText, isEmpty);
    expect(item.statusLabel, isEmpty);
    expect(RfiListItem.fromJson(<String, dynamic>{'id': '58'}).id, 58);
  });
}
