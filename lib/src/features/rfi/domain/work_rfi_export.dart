import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_list_item.dart';

const List<String> workRfiExportHeaders = <String>[
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
];

List<String> workRfiExportCells(RfiListItem item) {
  return <String>[
    item.rfiId,
    item.projectName,
    item.structure,
    item.element,
    item.nameOfRepresentative,
    item.assignedPersonClient,
    item.dateOfSubmission,
    item.scheduledText,
    item.contractorSubmittedOn,
    item.statusLabel,
  ];
}
