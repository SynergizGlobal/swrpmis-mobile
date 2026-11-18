import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/quality_rfi_form.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/work_rfi_form.dart';

void main() {
  group('parseQualityRfiProjects', () {
    test('normalizes single object and arrays', () {
      expect(
        parseQualityRfiProjects(<String, dynamic>{
          'projectId': 'P04',
          'projectName': '3rd & 4th Lines in Nagda-Mathura section',
        }).single.id,
        'P04',
      );
      expect(
        parseQualityRfiProjects(<dynamic>[
          <String, dynamic>{
            'projectId': 'P01',
            'projectName': 'One',
          },
          <String, dynamic>{
            'projectId': 'P02',
            'projectName': 'Two',
          },
        ]).map((QualityRfiOption o) => o.id),
        <String>['P01', 'P02'],
      );
      expect(parseQualityRfiProjects(null), isEmpty);
    });
  });

  group('parse descriptions and enclosures', () {
    test('keeps duplicate labels distinct by id', () {
      final List<QualityRfiOption> descriptions = parseQualityRfiDescriptions(
        <dynamic>[
          <String, dynamic>{'id': 21, 'rfiDescription': 'Blanketing'},
          <String, dynamic>{'id': 3, 'rfiDescription': 'Blanketing'},
          <String, dynamic>{'id': 18, 'rfiDescription': 'Quality'},
        ],
      );
      expect(
        descriptions.map((QualityRfiOption o) => o.id),
        <String>['21', '3', '18'],
      );
      expect(
        descriptions.map((QualityRfiOption o) => o.label),
        <String>['Blanketing', 'Blanketing', 'Quality'],
      );

      final List<QualityRfiOption> enclosures = parseQualityRfiEnclosures(
        <dynamic>[
          <String, dynamic>{'id': 3, 'encloserName': 'Blanketing'},
          <String, dynamic>{'id': 21, 'encloserName': 'Blanketing'},
          <String, dynamic>{'id': 27, 'encloserName': 'Quality'},
        ],
      );
      expect(
        enclosures.map((QualityRfiOption o) => o.id),
        <String>['3', '21', '27'],
      );
    });
  });

  group('structure cascade parsers', () {
    test('structure types and structures match work ajax shape', () {
      expect(
        parseQualityRfiStructureTypes(<dynamic>[
          <String, dynamic>{'structure_type': 'Minor Bridge'},
          <String, dynamic>{'structure_type': 'RUB'},
        ]).map((QualityRfiOption o) => o.label),
        <String>['Minor Bridge', 'RUB'],
      );
      expect(
        parseQualityRfiStructures(<dynamic>[
          <String, dynamic>{
            'structure_id': 7370,
            'strip_chart_structure_id_fk': '22 DN (RCC Box)',
          },
        ]).single,
        isA<QualityRfiOption>()
            .having((QualityRfiOption o) => o.id, 'id', '7370')
            .having(
              (QualityRfiOption o) => o.label,
              'label',
              '22 DN (RCC Box)',
            ),
      );
    });
  });

  group('representatives', () {
    test('maps userId for payload', () {
      expect(
        parseQualityRfiRepresentatives(<dynamic>[
          <String, dynamic>{
            'userId': 'PMIS_IT_017',
            'userName': 'Syed Altaf Hussain',
          },
        ]).single,
        isA<QualityRfiOption>()
            .having((QualityRfiOption o) => o.id, 'id', 'PMIS_IT_017')
            .having(
              (QualityRfiOption o) => o.label,
              'label',
              'Syed Altaf Hussain',
            ),
      );
    });
  });

  group('detail parse', () {
    test('reads PUT/GET quality detail shape', () {
      final QualityRfiDetail? detail = parseQualityRfiDetail(<String, dynamic>{
        'id': 113,
        'rfi_Id': 'RFI_QA_MNB_DN_P04_006280_0001',
        'project': 'P04',
        'contract': 'P04EN01',
        'structureType': 'Minor Bridge',
        'structure': '7370',
        'structureId': 7370,
        'typeOfRFI': 'Spot RFI',
        'userIdOfRepresentative': 'PMIS_IT_017',
        'nameOfRepresentative': 'Syed Altaf Hussain',
        'enclosuresList': <dynamic>['3', '21', '27'],
        'rfiDescriptionList': <dynamic>['21', '3', '18'],
        'description': 'dev testing',
        'timeOfInspection': '13:30',
        'dateOfSubmission': '2026-11-18',
        'dateOfInspection': '2026-11-18',
        'status': 'CREATED',
        'action': 'Create',
        'rfiCategory': 'QUALITY_OR_SAFETY',
      });
      expect(detail, isNotNull);
      expect(detail!.id, 113);
      expect(detail.rfiId, 'RFI_QA_MNB_DN_P04_006280_0001');
      expect(detail.structure, '7370');
      expect(detail.structureId, '7370');
      expect(detail.typeOfRfi, 'Spot RFI');
      expect(detail.rfiDescriptionList, <String>['21', '3', '18']);
      expect(detail.enclosuresList, <String>['3', '21', '27']);
    });

    test('unwraps data wrapper and list payloads', () {
      final QualityRfiDetail? wrapped = parseQualityRfiDetail(<String, dynamic>{
        'data': <String, dynamic>{
          'id': 9,
          'project': 'P01',
          'contract': 'C01',
          'structureId': 12,
          'structure': 'Pier 1',
        },
      });
      expect(wrapped, isNotNull);
      expect(wrapped!.id, 9);
      expect(wrapped.structureId, '12');
      expect(wrapped.structure, 'Pier 1');

      final QualityRfiDetail? listed = parseQualityRfiDetail(<dynamic>[
        <String, dynamic>{
          'id': 10,
          'project': 'P02',
          'contract': 'C02',
        },
      ]);
      expect(listed?.id, 10);
    });

    test('dedupes project ids used by dropdowns', () {
      expect(
        parseQualityRfiProjects(<dynamic>[
          <String, dynamic>{'projectId': 'P04', 'projectName': 'One'},
          <String, dynamic>{'projectId': 'P04', 'projectName': 'One again'},
          <String, dynamic>{'projectId': '', 'projectName': 'bad'},
        ]).map((QualityRfiOption o) => o.id),
        <String>['P04'],
      );
    });
  });

  group('payload and validation', () {
    test('create payload matches web body', () {
      final Map<String, dynamic> body = buildQualityRfiPayload(
        const QualityRfiSubmitDraft(
          project: 'P04',
          contract: 'P04EN01',
          structureType: 'Minor Bridge',
          structure: '7370',
          action: 'Create',
          typeOfRfi: 'Spot RFI',
          contractorRepresentative: 'PMIS_IT_017',
          dateOfSubmission: '2026-11-18',
          dateOfInspection: '2026-11-18',
          timeOfInspection: '13:30',
          rfiDescriptions: <String>['21', '3', '18'],
          enclosures: <String>['3', '21', '27'],
          description: 'dev testing ',
          editing: false,
        ),
      );
      expect(body['project'], 'P04');
      expect(body['contract'], 'P04EN01');
      expect(body['structure'], '7370');
      expect(body['action'], 'Create');
      expect(body['dateOfSubmission'], '');
      expect(body['dateOfInspection'], '2026-11-18');
      expect(body['timeOfInspection'], '13:30');
      expect(body['rfiDescriptions'], <String>['21', '3', '18']);
      expect(body['enclosures'], <String>['3', '21', '27']);
      expect(body['structureId'], isNull);
    });

    test('edit payload fills dateOfSubmission', () {
      final Map<String, dynamic> body = buildQualityRfiPayload(
        const QualityRfiSubmitDraft(
          project: 'P04',
          contract: 'P04EN01',
          structureType: 'Minor Bridge',
          structure: '7370',
          action: 'Reschedule',
          typeOfRfi: 'Spot RFI',
          contractorRepresentative: 'PMIS_IT_017',
          dateOfSubmission: '18/11/2026',
          dateOfInspection: '20/11/2026',
          timeOfInspection: '01:30 PM',
          rfiDescriptions: <String>['21'],
          enclosures: <String>['3'],
          description: 'dev testing',
          editing: true,
        ),
      );
      expect(body['action'], 'Reschedule');
      expect(body['dateOfSubmission'], '2026-11-18');
      expect(body['dateOfInspection'], '2026-11-20');
      expect(body['timeOfInspection'], '13:30');
    });

    test('validation requires hierarchy and schedule', () {
      expect(
        qualityRfiValidationMessage(
          const QualityRfiSubmitDraft(
            project: '',
            contract: '',
            structureType: '',
            structure: '',
            action: 'Create',
            typeOfRfi: '',
            contractorRepresentative: '',
            dateOfSubmission: '',
            dateOfInspection: '',
            timeOfInspection: '',
            rfiDescriptions: <String>[],
            enclosures: <String>[],
            description: '',
            editing: false,
          ),
        ),
        'Please select a Project.',
      );
    });

    test('Date of Inspection follows Spot/Regular rule like Work RFI', () {
      final DateTime today = DateTime(2026, 10, 13, 23, 45);

      QualityRfiSubmitDraft draft({
        required String type,
        required String date,
        String originalType = '',
        String originalDate = '',
      }) {
        return QualityRfiSubmitDraft(
          project: 'P04',
          contract: 'P04EN01',
          structureType: 'Minor Bridge',
          structure: '7370',
          action: 'Create',
          typeOfRfi: type,
          contractorRepresentative: 'PMIS_IT_017',
          dateOfSubmission: '2026-10-13',
          dateOfInspection: date,
          timeOfInspection: '13:30',
          rfiDescriptions: const <String>['21'],
          enclosures: const <String>['3'],
          description: '',
          editing: false,
          today: today,
          originalTypeOfRfi: originalType,
          originalDateOfInspection: originalDate,
        );
      }

      expect(
        qualityRfiValidationMessage(
          draft(type: 'Regular RFI', date: '2026-10-13'),
        ),
        workRfiRegularDateRule,
      );
      expect(
        qualityRfiValidationMessage(
          draft(type: 'Regular RFI', date: '2026-10-14'),
        ),
        workRfiRegularDateRule,
      );
      expect(
        qualityRfiValidationMessage(
          draft(type: 'Regular RFI', date: '2026-10-15'),
        ),
        isNull,
      );
      expect(
        qualityRfiValidationMessage(
          draft(type: 'Spot RFI', date: '2026-10-12'),
        ),
        workRfiSpotDateRule,
      );
      expect(
        qualityRfiValidationMessage(
          draft(type: 'Spot RFI', date: '2026-10-13'),
        ),
        isNull,
      );
      expect(
        qualityRfiValidationMessage(
          draft(
            type: 'Spot RFI',
            date: '2026-10-01',
            originalType: 'Spot RFI',
            originalDate: '2026-10-01',
          ),
        ),
        isNull,
      );
    });
  });

  group('edit action unlocks', () {
    test('Reschedule unlocks schedule and description text', () {
      expect(qualityRfiActionUnlocksSchedule(qualityRfiActionReschedule), isTrue);
      expect(
        qualityRfiActionUnlocksDescriptionText(qualityRfiActionReschedule),
        isTrue,
      );
      expect(
        qualityRfiActionUnlocksRepresentative(qualityRfiActionReschedule),
        isFalse,
      );
    });

    test('Update unlocks descriptions and description text', () {
      expect(
        qualityRfiActionUnlocksDescriptions(qualityRfiActionUpdate),
        isTrue,
      );
      expect(
        qualityRfiActionUnlocksDescriptionText(qualityRfiActionUpdate),
        isTrue,
      );
      expect(qualityRfiActionUnlocksSchedule(qualityRfiActionUpdate), isFalse);
      expect(
        qualityRfiActionUnlocksRepresentative(qualityRfiActionUpdate),
        isFalse,
      );
    });

    test('Reassign unlocks representative only', () {
      expect(
        qualityRfiActionUnlocksRepresentative(qualityRfiActionReassign),
        isTrue,
      );
      expect(
        qualityRfiActionUnlocksSchedule(qualityRfiActionReassign),
        isFalse,
      );
      expect(
        qualityRfiActionUnlocksDescriptions(qualityRfiActionReassign),
        isFalse,
      );
      expect(
        qualityRfiActionUnlocksDescriptionText(qualityRfiActionReassign),
        isFalse,
      );
    });

    test('edit action labels match screenshots', () {
      expect(
        qualityRfiEditActions.map((QualityRfiOption o) => o.label),
        <String>['Reschedule', 'Update', 'Reassign'],
      );
      expect(qualityRfiDefaultEditAction, 'Update');
    });
  });
}
