import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/design/data/design_export_file.dart';
import 'package:swr_pmis_mobile/src/features/design/domain/design_list.dart';
import 'package:swr_pmis_mobile/src/features/design/domain/design_parse.dart';
import 'package:swr_pmis_mobile/src/features/design/presentation/pages/design_drawing_page.dart';
import 'package:swr_pmis_mobile/src/features/update_forms/domain/update_form_destination.dart';
import 'package:swr_pmis_mobile/src/core/forms/form_menu_tree.dart';

void main() {
  test('contract filter options parse id and short name', () {
    final List<DesignOption> contracts = parseDesignContracts(<dynamic>[
      <String, dynamic>{
        'contract_id_fk': 'P01EN02',
        'contract_short_name': 'Contract A',
        'contract_name': 'Long Contract A',
      },
      <String, dynamic>{
        'contract_id_fk': 'P01EN02',
        'contract_short_name': 'Duplicate',
      },
      <String, dynamic>{
        'contract_id_fk': 'P01EN03',
        'contract_name': 'Only Name',
      },
      <String, dynamic>{
        'contract_id_fk': null,
        'contract_short_name': 'Skip',
      },
    ]);

    expect(contracts, hasLength(2));
    expect(contracts.first.value, 'P01EN02');
    expect(contracts.first.label, 'Contract A');
    expect(
      contracts.any(
        (DesignOption option) =>
            option.value == 'P01EN03' && option.label == 'Only Name',
      ),
      isTrue,
    );
  });

  test('structure and drawing type filters parse string values', () {
    final DesignOption structure = parseDesignStructureTypes(<String, dynamic>{
      'structure_type_fk': 'Minor Bridge',
    }).single;
    expect(structure.value, 'Minor Bridge');
    expect(structure.label, 'Minor Bridge');

    final DesignOption drawing = parseDesignDrawingTypes(<dynamic>[
      <String, dynamic>{'drawing_type_fk': 'GAD'},
      <String, dynamic>{'drawing_type_fk': 'GAD'},
      <String, dynamic>{'drawing_type_fk': null},
    ]).single;
    expect(drawing.value, 'GAD');
  });

  test('designs list parses aaData totals and drawing number fallbacks', () {
    final ({List<DesignRow> rows, int total}) parsed = parseDesignsList(
      <String, dynamic>{
        'iTotalDisplayRecords': 42,
        'iTotalRecords': 50,
        'aaData': <dynamic>[
          <String, dynamic>{
            'design_id': 'D-1',
            'design_seq_id': 'PMIS-001',
            'structure_type_fk': 'Minor Bridge',
            'structure_id_fk': 'MB-12',
            'drawing_title': 'GAD Drawing',
            'drawing_type_fk': 'GAD',
            'mrvc_drawing_no': '8765',
            'contractor_drawing_no': 'DR0011HR',
            'modified_date': '20-07-2026',
          },
          <String, dynamic>{
            'design_seq_id': 'PMIS-002',
            'structure_type_fk': 'Major Bridge',
            'structure_id_fk': 'MJ-1',
            'drawing_title': 'Title 2',
            'drawing_type_fk': 'Structural',
            'contractor_drawing_no': 'DR0011HR',
            'modified_date': 20260720,
          },
          <String, dynamic>{
            'drawing_title': 'Missing keys',
          },
        ],
      },
    );

    expect(parsed.total, 42);
    expect(parsed.rows, hasLength(2));
    expect(parsed.rows.first.pmisDrawingNo, 'PMIS-001');
    expect(parsed.rows.first.drawingNo, '8765');
    expect(parsed.rows.first.structureType, 'Minor Bridge');
    expect(parsed.rows[1].drawingNo, 'DR0011HR');
    expect(parsed.rows[1].lastUpdate, '20260720');
  });

  test('designs list accepts nested data payload and raw list', () {
    final ({List<DesignRow> rows, int total}) nested = parseDesignsList(
      <String, dynamic>{
        'data': <String, dynamic>{
          'iTotalRecords': 1,
          'aaData': <dynamic>[
            <String, dynamic>{
              'design_seq_id': 'SEQ-9',
              'drawing_no': 'N-1',
            },
          ],
        },
      },
    );
    expect(nested.total, 1);
    expect(nested.rows.single.drawingNo, 'N-1');

    final ({List<DesignRow> rows, int total}) listOnly = parseDesignsList(
      <dynamic>[
        <String, dynamic>{
          'design_seq_id': 'SEQ-8',
          'division_drawing_no': 'DIV-1',
        },
      ],
    );
    expect(listOnly.total, 1);
    expect(listOnly.rows.single.drawingNo, 'DIV-1');
  });

  test('uploads list parses rows and trims uploaded_on fractions', () {
    final List<DesignUploadRow> rows = parseDesignUploads(<dynamic>[
      <String, dynamic>{
        'design_data_id': 'U-1',
        'uploaded_file': 'designs.xlsx',
        'status': 'Pass',
        'remarks': 'ok',
        'uploaded_by_user_id_fk': 'user1',
        'uploaded_on': '2026-07-20 10:15:30.123',
      },
      <String, dynamic>{
        'uploaded_file': null,
        'status': 'Fail',
      },
    ]);

    expect(rows, hasLength(1));
    expect(rows.single.uploadedFile, 'designs.xlsx');
    expect(rows.single.status, 'Pass');
    expect(rows.single.uploadedBy, 'user1');
    expect(rows.single.uploadedOn, '2026-07-20 10:15:30');
  });

  test('uploads list accepts aaData wrapper', () {
    final List<DesignUploadRow> rows = parseDesignUploads(<String, dynamic>{
      'aaData': <dynamic>[
        <String, dynamic>{
          'design_data_id': 12,
          'uploaded_file': 'a.csv',
          'status': 'Success',
          'remarks': null,
          'uploaded_by_user_id_fk': 'admin',
          'uploaded_on': '2026-01-01',
        },
      ],
    });
    expect(rows.single.designDataId, '12');
    expect(rows.single.remarks, '');
  });

  test('export workbook encodes current design rows', () {
    final List<int> bytes = buildDesignXlsxBytes(const <DesignRow>[
      DesignRow(
        designId: '1',
        pmisDrawingNo: 'PMIS-1',
        structureType: 'Minor Bridge',
        structure: 'MB-1',
        title: 'Title',
        drawingType: 'GAD',
        drawingNo: '8765',
        lastUpdate: '20-07-2026',
      ),
    ]);
    expect(bytes, isNotEmpty);
  });

  test('Update Forms Design & Drawing routes to forms-design', () {
    const FormMenuNode design = FormMenuNode(
      formId: 'design',
      formName: 'Design & Drawing',
      webFormUrl: 'design',
      mobileFormUrl: '',
      priority: 1,
      children: <FormMenuNode>[],
    );
    expect(updateFormRouteName(design), DesignDrawingPage.routeName);
    expect(DesignDrawingPage.routePath, '/module/design');
  });

  test('upload response success message is parsed', () {
    expect(
      parseDesignUploadMessage(<String, dynamic>{
        'success':
            '0 new design(s) added, 0 design(s) updated, 0 status row(s) saved.',
      }),
      '0 new design(s) added, 0 design(s) updated, 0 status row(s) saved.',
    );
    expect(
      () => parseDesignUploadMessage(<String, dynamic>{
        'error': 'Invalid template',
      }),
      throwsStateError,
    );
  });

  test('list query maps pagination and filter params', () {
    const DesignListQuery query = DesignListQuery(
      contractId: 'C1',
      structureType: 'Minor Bridge',
      drawingType: 'GAD',
      search: 'bridge',
      page: 2,
      pageSize: 10,
    );
    expect(query.displayStart, 10);
    expect(query.listQueryParameters()['iDisplayStart'], 10);
    expect(query.listQueryParameters()['sSearch'], 'bridge');
    expect(query.filterBody()['structure_type_fk'], 'Minor Bridge');
  });
}
