import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_filter.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_row.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_inspection_actions.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_user_role.dart';

void main() {
  const Map<String, dynamic> sample = <String, dynamic>{
    'id': 57,
    'rfiCategory': 'WORK',
    'rfi_Id': 'RFI_W_RUB_36838_EXCL_EXC_0001',
    'dateOfSubmission': '01-10-2026',
    'dateOfInspection': '01-10-2026',
    'timeOfInspection': '14:30',
    'contractorSubmittedOn': '01-10-2026 16:40',
    'rfiDescription': 'Testing... RFI',
    'nameOfRepresentative': 'IT Test Contractor Rep',
    'assignedPersonClient': null,
    'measurementType': 'Volume',
    'totalQty': 81.0,
    'status': 'AE_INSP_ONGOING',
    'inspectionStatus': 'LAB_TEST',
    'action': 'Create',
    'element': 'Excavation',
    'structure': '43 (RCC Box)',
    'projectName': '4th Line between Itarsi - Bhopal - Bina',
    'contractName': 'EPC Contract for Important Bridges...',
    'structureType': 'Important Bridge',
  };

  test('rfi-details sample keeps rfi_Id, schedule, whole qty, and status', () {
    final RfiInspectionRow row = RfiInspectionRow.fromJson(sample);

    expect(row.rfiId, 'RFI_W_RUB_36838_EXCL_EXC_0001');
    expect(row.scheduledText, '01-10-2026 14:30');
    expect(row.qtyText, '81');
    expect(row.status, 'AE_INSP_ONGOING');
    expect(row.statusLabel, 'AE INSP ONGOING');
    expect(row.inspectionStatus, 'LAB_TEST');
    expect(row.action, 'Create');
    expect(row.assignedPersonClient, isEmpty);
    expect(row.toListItem().inspectionQty, '81');
    expect(row.toListItem().statusLabel, 'AE INSP ONGOING');
  });

  test(
    'filter payload round-trip keeps structureId numeric and nulls null',
    () {
      const RfiInspectionFilter filter = RfiInspectionFilter(structureId: 7);
      final Map<String, dynamic> json = filter.toJson();

      expect(json['structureId'], 7);
      expect(json['structureId'], isA<int>());
      expect(json['rfiCategory'], isNull);
      expect(json['projectId'], isNull);
      expect(json['contractId'], isNull);
      expect(json['structureType'], isNull);
      expect(json['itemId'], isNull);
      expect(json['materialId'], isNull);
      expect(json['qualityOrSafetyId'], isNull);

      final Map<String, dynamic> decoded =
          jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
      final RfiInspectionFilter again = RfiInspectionFilter.fromJson(decoded);

      expect(again.structureId, 7);
      expect(again.toJson()['structureId'], isA<int>());
      expect(again.itemId, isNull);
      expect(again.rfiCategory, isNull);
      expect(again.qualityOrSafetyId, isNull);
    },
  );

  test('selecting a category keeps project and contract and clears extras', () {
    const RfiInspectionFilter filter = RfiInspectionFilter(
      rfiCategory: 'WORK',
      projectId: '9',
      contractId: '3',
      structureType: 'Important Bridge',
      structureId: 7,
      itemId: 4,
      materialId: 2,
      qualityOrSafetyId: 1,
    );

    final RfiInspectionFilter next = filter.withCategory('MATERIAL');

    expect(next.rfiCategory, 'MATERIAL');
    expect(next.projectId, '9');
    expect(next.contractId, '3');
    expect(next.structureType, isNull);
    expect(next.structureId, isNull);
    expect(next.itemId, isNull);
    expect(next.materialId, isNull);
    expect(next.qualityOrSafetyId, isNull);
  });

  test(
    'sample row lets an engineer start inspection and hides it from a contractor',
    () {
      final RfiInspectionRow row = RfiInspectionRow.fromJson(sample);
      final DateTime now = DateTime(2026, 10, 8, 16);

      final List<RfiInspectionAction> engineer = rfiInspectionActions(
        role: RfiUserRole.engineer,
        row: row,
        now: now,
      );
      final List<RfiInspectionAction> contractor = rfiInspectionActions(
        role: RfiUserRole.contractor,
        row: row,
        now: now,
      );

      expect(engineer, contains(RfiInspectionAction.startOnline));
      expect(engineer, contains(RfiInspectionAction.startOffline));
      expect(engineer, contains(RfiInspectionAction.viewDetails));
      expect(engineer, contains(RfiInspectionAction.submit));
      expect(engineer, isNot(contains(RfiInspectionAction.sendForValidation)));
      expect(contractor, isNot(contains(RfiInspectionAction.startOnline)));
      expect(contractor, isNot(contains(RfiInspectionAction.startOffline)));
      expect(contractor, contains(RfiInspectionAction.viewDetails));
      expect(contractor, isNot(contains(RfiInspectionAction.submit)));
    },
  );
}
