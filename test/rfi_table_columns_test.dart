import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_list_item.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_list_kind.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_table.dart';

void main() {
  test('material, work, and quality tables use their columns', () {
    expect(
      rfiTableColumns(RfiListKind.material).map((RfiTableColumn c) => c.label),
      <String>[
        'RFI ID',
        'Project',
        'Item',
        'Material',
        'Batch/Lot No.',
        'Location',
        'Assigned contractor',
        'Raised date',
        'Scheduled on',
        'Contractor submitted on',
        'Status',
        'Actions',
      ],
    );
    expect(
      rfiTableColumns(RfiListKind.work).map((RfiTableColumn c) => c.label),
      <String>[
        'RFI ID',
        'Project',
        'Structure',
        'Element',
        'Assigned contractor',
        "Assigned employer's engineer",
        'Raised date',
        'Scheduled on',
        'Contractor submitted on',
        'Status',
        'Actions',
      ],
    );
    expect(
      rfiTableColumns(RfiListKind.quality).map((RfiTableColumn c) => c.label),
      <String>[
        'RFI ID',
        'Category',
        'Project',
        'Structure type',
        'Raised date',
        'Scheduled on',
        'Status',
        'Actions',
      ],
    );
  });

  test('quality actions follow status and view-only', () {
    expect(
      rfiQualityRowActions('CREATED', canModify: true),
      <RfiQualityRowAction>[
        RfiQualityRowAction.edit,
        RfiQualityRowAction.delete,
      ],
    );
    expect(
      rfiQualityRowActions('OPEN', canModify: true),
      <RfiQualityRowAction>[
        RfiQualityRowAction.edit,
        RfiQualityRowAction.delete,
      ],
    );
    expect(
      rfiQualityRowActions('REASSIGNED', canModify: true),
      <RfiQualityRowAction>[
        RfiQualityRowAction.edit,
        RfiQualityRowAction.delete,
      ],
    );
    expect(
      rfiQualityRowActions('UPDATED', canModify: true),
      <RfiQualityRowAction>[
        RfiQualityRowAction.edit,
        RfiQualityRowAction.delete,
      ],
    );
    expect(
      rfiQualityRowActions('RESCHEDULED', canModify: true),
      <RfiQualityRowAction>[
        RfiQualityRowAction.edit,
        RfiQualityRowAction.delete,
      ],
    );
    expect(
      rfiQualityRowActions('CON_INSP_ONGOING', canModify: true),
      <RfiQualityRowAction>[RfiQualityRowAction.view],
    );
    expect(
      rfiQualityRowActions('INSPECTION_DONE', canModify: true),
      <RfiQualityRowAction>[RfiQualityRowAction.view],
    );
    expect(
      rfiQualityRowActions('CREATED', canModify: false),
      <RfiQualityRowAction>[RfiQualityRowAction.view],
    );
    expect(
      rfiQualityRowActions('REASSIGNED', canModify: false),
      <RfiQualityRowAction>[RfiQualityRowAction.view],
    );
    expect(
      rfiQualityRowActions('UNKNOWN_STATUS', canModify: true),
      <RfiQualityRowAction>[RfiQualityRowAction.view],
    );
    expect(
      rfiTableColumns(
        RfiListKind.quality,
        showActions: false,
      ).map((RfiTableColumn column) => column.label),
      isNot(contains('Actions')),
    );
  });

  test('empty cells read blank and status keeps spaces', () {
    const RfiListItem item = RfiListItem(
      id: 1,
      rfiId: '',
      rfiCategory: '',
      projectName: '',
      item: '',
      material: '',
      location: '',
      batchLotNo: '',
      structure: '',
      structureType: '',
      element: '',
      nameOfRepresentative: '',
      assignedPersonClient: '',
      contractName: '',
      dateOfSubmission: '',
      dateOfInspection: '',
      timeOfInspection: '',
      contractorSubmittedOn: '',
      rfiStatus: 'AE_INSP_ONGOING',
    );
    final RfiTableColumn status = rfiTableColumns(
      RfiListKind.material,
    ).firstWhere((RfiTableColumn column) => column.status);
    expect(status.status, isTrue);
    expect(status.read(item), 'AE INSP ONGOING');
    expect(rfiTableColumns(RfiListKind.material).first.read(item), isEmpty);
  });
}
