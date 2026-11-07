import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/forms/form_menu_tree.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/features/p6_updates/domain/p6_list.dart';
import 'package:swr_pmis_mobile/src/features/p6_updates/domain/p6_parse.dart';
import 'package:swr_pmis_mobile/src/features/p6_updates/presentation/pages/p6_updates_page.dart';
import 'package:swr_pmis_mobile/src/features/update_forms/domain/update_form_destination.dart';

void main() {
  test('Structure P6 Updates routes to forms-p6', () {
    const FormMenuNode byUrl = FormMenuNode(
      formId: '42',
      formName: 'Structure P6 Updates',
      webFormUrl: 'structure-p6-updates',
      mobileFormUrl: '',
      priority: 2,
      children: <FormMenuNode>[],
    );
    const FormMenuNode byLegacyUrl = FormMenuNode(
      formId: '42',
      formName: 'Other',
      webFormUrl: 'p6-new-data',
      mobileFormUrl: '',
      priority: 2,
      children: <FormMenuNode>[],
    );
    expect(updateFormRouteName(byUrl), P6UpdatesPage.routeName);
    expect(updateFormRouteName(byLegacyUrl), P6UpdatesPage.routeName);
    expect(P6UpdatesPage.routePath, '/module/p6');
  });

  test('P6 API paths are relative', () {
    expect(ApiConstants.p6NewDataMasterPath, '/p6-new-data-new');
    expect(ApiConstants.p6HistoryListPath, '/ajax/getP6NewActivityData');
    expect(
      ApiConstants.p6ContractsForProjectPath,
      '/ajax/getContractListInP6New',
    );
    expect(ApiConstants.p6UploadNewDataPath, '/upload-p6-new-data');
  });

  test('parse form master projects and contracts', () {
    final P6FormMaster master = parseP6FormMaster(<String, dynamic>{
      'projectsList': <Map<String, dynamic>>[
        <String, dynamic>{
          'project_id_fk': 'P01',
          'project_name': 'Demo Project',
        },
      ],
      'contractsList': <Map<String, dynamic>>[
        <String, dynamic>{
          'contract_id': 'P01EN01',
          'contract_name': 'EPC',
          'contract_short_name': 'EPC Short',
        },
      ],
      'status': 'SUCCESS',
    });
    expect(master.projects.single.value, 'P01');
    expect(master.projects.single.label, 'Demo Project');
    expect(master.contracts.single.value, 'P01EN01');
    expect(master.contracts.single.label, 'EPC Short');
  });

  test('parse history rows and filters', () {
    final List<P6HistoryRow> rows = parseP6HistoryRows(<Map<String, dynamic>>[
      <String, dynamic>{
        'contract_id_fk': 'P21GA01',
        'upload_type': 'Baseline',
        'data_date': '08-10-2026',
        'soft_delete_status_fk': 'Active',
        'p6_file_path': 'P6BaselineFile (2).xlsx',
        'uploaded_by_user_id_fk': 'PMIS_IT_001',
        'uploaded_date': '28-10-2026 15:40:16',
      },
    ]);
    expect(rows, hasLength(1));
    expect(rows.single.contractId, 'P21GA01');
    expect(rows.single.dataType, 'Baseline');
    expect(rows.single.uploadedFile, 'P6BaselineFile (2).xlsx');

    expect(
      parseP6UploadTypes(<Map<String, dynamic>>[
        <String, dynamic>{'upload_type': 'Baseline'},
      ]).single.value,
      'Baseline',
    );
    expect(
      parseP6Statuses(<Map<String, dynamic>>[
        <String, dynamic>{'soft_delete_status_fk': 'Active'},
      ]).single.value,
      'Active',
    );
    expect(
      parseP6Contracts(<Map<String, dynamic>>[
        <String, dynamic>{
          'contract_id': 'P01EN01',
          'contract_short_name': 'Bridge EPC',
        },
      ]).single.label,
      'Bridge EPC',
    );
  });

  test('upload response error throws', () {
    expect(
      () => parseP6UploadMessage(<String, dynamic>{
        'error': 'Please select a file',
      }),
      throwsStateError,
    );
    expect(
      parseP6UploadMessage(<String, dynamic>{'status': 'SUCCESS'}),
      'P6 data uploaded successfully.',
    );
  });

  test('upload kind labels match UI', () {
    expect(P6UploadKind.baseline.title, 'Baseline');
    expect(P6UploadKind.revisedBaseline.actionLabel, 'Update');
    expect(P6UploadKind.update.actionLabel, 'Upload');
    expect(P6UploadKind.revisedBaseline.uploadType, 'Revised Baseline');
  });
}
