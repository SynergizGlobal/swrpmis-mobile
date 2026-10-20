import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/forms/form_menu_tree.dart';
import 'package:swr_pmis_mobile/src/features/update_forms/domain/update_form_destination.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/data/utility_shifting_export_file.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/domain/utility_shifting_list.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/domain/utility_shifting_parse.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/presentation/pages/utility_shifting_page.dart';

void main() {
  test('location and status filters parse string values', () {
    final List<UtilityShiftingOption> locations =
        parseUtilityShiftingLocations(<dynamic>[
          <String, dynamic>{'location_name': 'Mumbai'},
          <String, dynamic>{'location_name': 'Mumbai'},
          <String, dynamic>{'location_name': null},
        ]);
    expect(locations, hasLength(1));
    expect(locations.single.value, 'Mumbai');

    final List<UtilityShiftingOption> statuses =
        parseUtilityShiftingStatuses(<String, dynamic>{
          'aaData': <dynamic>[
            <String, dynamic>{'shifting_status_fk': 'In Progress'},
          ],
        });
    expect(statuses.single.label, 'In Progress');
  });

  test('utility shifting list parses aaData totals and row fields', () {
    final ({List<UtilityShiftingRow> rows, int total}) parsed =
        parseUtilityShiftingList(<String, dynamic>{
          'iTotalDisplayRecords': 5,
          'aaData': <dynamic>[
            <String, dynamic>{
              'utility_shifting_id': 'US-1',
              'utility_description': 'Power line shift',
              'utility_type_fk': 'Electric',
              'execution_agency_fk': 'Agency A',
              'designation': 'HOD Name',
              'custodian': 'Custodian X',
              'shifting_status_fk': 'Open',
              'modified_date': '20-07-2026',
              'project_name': 'Project P1',
              'location_name': 'Site 1',
            },
            <String, dynamic>{
              'utility_description': null,
              'utility_shifting_id': null,
            },
          ],
        });

    expect(parsed.total, 5);
    expect(parsed.rows, hasLength(1));
    expect(parsed.rows.single.utilityShiftingId, 'US-1');
    expect(parsed.rows.single.description, 'Power line shift');
    expect(parsed.rows.single.hod, 'HOD Name');
    expect(parsed.rows.single.project, 'Project P1');
  });

  test('uploads list parses rows and trims uploaded_on fractions', () {
    final List<UtilityShiftingUploadRow> rows = parseUtilityShiftingUploads(
      <dynamic>[
        <String, dynamic>{
          'utility_data_id': 'U-1',
          'uploaded_file': 'utility.xlsx',
          'status': 'Pass',
          'remarks': 'ok',
          'uploaded_by_user_id_fk': 'user1',
          'uploaded_on': '2026-07-20 10:15:30.123',
        },
        <String, dynamic>{
          'uploaded_file': null,
          'status': 'Fail',
        },
      ],
    );

    expect(rows, hasLength(1));
    expect(rows.single.uploadedFile, 'utility.xlsx');
    expect(rows.single.uploadedOn, '2026-07-20 10:15:30');
  });

  test('export workbook encodes utility shifting rows', () {
    final List<int> bytes = buildUtilityShiftingXlsxBytes(const <UtilityShiftingRow>[
      UtilityShiftingRow(
        utilityShiftingId: 'US-1',
        project: 'P1',
        executionAgency: 'Agency',
        hod: 'HOD',
        utilityType: 'Electric',
        description: 'Desc',
        location: 'Loc',
        custodian: 'Cust',
        identificationDate: '01-01-2026',
        referenceNo: 'REF-1',
        chainage: '100',
        executedBy: 'Team',
        impactedContract: 'C1',
        requirementStage: 'Stage',
        impactedElement: 'Element',
        affectedStructures: 'Struct',
        targetDate: '02-02-2026',
        scope: 'Scope',
        completed: '50',
        unit: 'm',
        startDate: '03-03-2026',
        status: 'Open',
        completionDate: '04-04-2026',
        remarks: 'Note',
        lastUpdate: '20-07-2026',
      ),
    ]);
    expect(bytes, isNotEmpty);
    expect(utilityShiftingExportHeaders, hasLength(24));
  });

  test('Update Forms Utility Shifting routes to forms-utility', () {
    const FormMenuNode utility = FormMenuNode(
      formId: 'utility',
      formName: 'Utility Shifting',
      webFormUrl: 'utility',
      mobileFormUrl: '',
      priority: 1,
      children: <FormMenuNode>[],
    );
    expect(updateFormRouteName(utility), UtilityShiftingPage.routeName);
    expect(UtilityShiftingPage.routePath, '/module/utility');
  });

  test('list query maps pagination and filter body', () {
    const UtilityShiftingListQuery query = UtilityShiftingListQuery(
      locationName: 'Mumbai',
      utilityCategory: 'Power',
      utilityType: 'Electric',
      status: 'Open',
      search: 'line',
      page: 2,
      pageSize: 10,
    );
    expect(query.displayStart, 10);
    expect(query.listQueryParameters()['iDisplayStart'], 10);
    expect(query.listQueryParameters()['sSearch'], 'line');
    expect(query.filterBody()['location_name'], 'Mumbai');
    expect(query.filterBody()['shifting_status_fk'], 'Open');
  });
}
