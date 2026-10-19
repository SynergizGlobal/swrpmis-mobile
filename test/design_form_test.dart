import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/design/domain/design_form.dart';
import 'package:swr_pmis_mobile/src/features/design/domain/design_list.dart';

void main() {
  group('validateDesignForm', () {
    DesignStatusRowDraft row({String drawingNo = 'DR-1'}) {
      return DesignStatusRowDraft(drawingNo: drawingNo);
    }

    test('requires project, railway, structure type/structure, drawing type', () {
      expect(
        validateDesignForm(
          projectId: '',
          approvingRailwayId: 'SWR',
          structureTypeId: 'Minor Bridge',
          structureId: '56',
          drawingTypeId: 'GAD',
          approvalAuthorityId: 'CRS',
          drawingTitle: 'Title',
          statusRows: <DesignStatusRowDraft>[row()],
        ),
        'Please select a project.',
      );
      expect(
        validateDesignForm(
          projectId: 'P04',
          approvingRailwayId: '',
          structureTypeId: 'Minor Bridge',
          structureId: '56',
          drawingTypeId: 'GAD',
          approvalAuthorityId: 'CRS',
          drawingTitle: 'Title',
          statusRows: <DesignStatusRowDraft>[row()],
        ),
        'Please select an approving railway.',
      );
      expect(
        validateDesignForm(
          projectId: 'P04',
          approvingRailwayId: 'SWR',
          structureTypeId: '',
          structureId: '56',
          drawingTypeId: 'GAD',
          approvalAuthorityId: 'CRS',
          drawingTitle: 'Title',
          statusRows: <DesignStatusRowDraft>[row()],
        ),
        'Please select a structure type.',
      );
      expect(
        validateDesignForm(
          projectId: 'P04',
          approvingRailwayId: 'SWR',
          structureTypeId: 'Minor Bridge',
          structureId: '',
          drawingTypeId: 'GAD',
          approvalAuthorityId: 'CRS',
          drawingTitle: 'Title',
          statusRows: <DesignStatusRowDraft>[row()],
        ),
        'Please select a structure.',
      );
      expect(
        validateDesignForm(
          projectId: 'P04',
          approvingRailwayId: 'SWR',
          structureTypeId: 'Minor Bridge',
          structureId: '56',
          drawingTypeId: '',
          approvalAuthorityId: 'CRS',
          drawingTitle: 'Title',
          statusRows: <DesignStatusRowDraft>[row()],
        ),
        'Please select a drawing type.',
      );
    });

    test('requires approval authority, title, status rows and drawing no', () {
      expect(
        validateDesignForm(
          projectId: 'P04',
          approvingRailwayId: 'SWR',
          structureTypeId: 'Minor Bridge',
          structureId: '56',
          drawingTypeId: 'GAD',
          approvalAuthorityId: '',
          drawingTitle: 'Title',
          statusRows: <DesignStatusRowDraft>[row()],
        ),
        'Please select an approval authority.',
      );
      expect(
        validateDesignForm(
          projectId: 'P04',
          approvingRailwayId: 'SWR',
          structureTypeId: 'Minor Bridge',
          structureId: '56',
          drawingTypeId: 'GAD',
          approvalAuthorityId: 'CRS',
          drawingTitle: '   ',
          statusRows: <DesignStatusRowDraft>[row()],
        ),
        'Please enter a drawing title.',
      );
      expect(
        validateDesignForm(
          projectId: 'P04',
          approvingRailwayId: 'SWR',
          structureTypeId: 'Minor Bridge',
          structureId: '56',
          drawingTypeId: 'GAD',
          approvalAuthorityId: 'CRS',
          drawingTitle: 'A' * 201,
          statusRows: <DesignStatusRowDraft>[row()],
        ),
        'Drawing title must be at most 200 characters.',
      );
      expect(
        validateDesignForm(
          projectId: 'P04',
          approvingRailwayId: 'SWR',
          structureTypeId: 'Minor Bridge',
          structureId: '56',
          drawingTypeId: 'GAD',
          approvalAuthorityId: 'CRS',
          drawingTitle: 'Title',
          statusRows: const <DesignStatusRowDraft>[],
        ),
        'Please add at least one drawing status row.',
      );
      expect(
        validateDesignForm(
          projectId: 'P04',
          approvingRailwayId: 'SWR',
          structureTypeId: 'Minor Bridge',
          structureId: '56',
          drawingTypeId: 'GAD',
          approvalAuthorityId: 'CRS',
          drawingTitle: 'Title',
          statusRows: <DesignStatusRowDraft>[row(drawingNo: '')],
        ),
        'Please enter Drawing No. for status row 1.',
      );
    });

    test('returns null when required fields are present', () {
      expect(
        validateDesignForm(
          projectId: 'P04',
          approvingRailwayId: 'SWR',
          structureTypeId: 'Minor Bridge',
          structureId: '56 (RCC Box)',
          drawingTypeId: 'GAD of Bridges - New Lines',
          approvalAuthorityId: 'CRS',
          drawingTitle: 'GAD for bridge',
          statusRows: <DesignStatusRowDraft>[row()],
        ),
        isNull,
      );
    });
  });

  test('prefill maps list row fields', () {
    final DesignFormPrefill prefill = DesignFormPrefill.fromRow(
      const DesignRow(
        designId: 'D-9',
        pmisDrawingNo: 'PMIS-9',
        structureType: 'Minor Bridge',
        structure: '56 (RCC Box)',
        title: 'GAD',
        drawingType: 'GAD',
        drawingNo: 'AG-1',
        lastUpdate: '01-01-2026',
      ),
    );
    expect(prefill.designId, 'D-9');
    expect(prefill.structureType, 'Minor Bridge');
    expect(prefill.structure, '56 (RCC Box)');
    expect(prefill.title, 'GAD');
    expect(prefill.drawingType, 'GAD');
    expect(prefill.drawingNo, 'AG-1');
  });

  test('project catalog parses id and name', () {
    final List<DesignFormOption> projects = parseDesignFormProjects(<dynamic>[
      <String, dynamic>{'project_id': 'P04', 'project_name': 'P04 - Lines'},
      <String, dynamic>{'project_id': null, 'project_name': 'Skip'},
      <String, dynamic>{'project_id': 'P04', 'project_name': 'Duplicate'},
    ]);
    expect(projects, hasLength(1));
    expect(projects.single.id, 'P04');
    expect(projects.single.label, 'P04 - Lines');
  });
}
