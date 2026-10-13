import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/work_rfi_form.dart';

void main() {
  test('projects and contracts parse, with short-name fallback', () {
    final WorkRfiProjectCatalog catalog = parseWorkRfiProjectCatalog(
      <String, dynamic>{
        'projectsList': <Map<String, dynamic>>[
          <String, dynamic>{
            'project_id_fk': 'P01',
            'project_name': '4th Line between Itarsi - Bhopal - Bina',
          },
          <String, dynamic>{
            'project_id_fk': 'P02',
            'project_name': 'Panna - Kajuraho Section New B.G. Line Project',
          },
        ],
        'contractsList': <Map<String, dynamic>>[
          <String, dynamic>{
            'contract_id': 'P01EN01',
            'contract_short_name': 'New Broad gauge line Between KM 25.4',
            'contract_name': 'Full contract name',
            'project_id_fk': 'P01',
          },
          <String, dynamic>{
            'contract_id': 'P02EN02',
            'contract_name':
                'Earthwork, Minor and Major bridges bwn Khajuraho stn',
            'project_id_fk': 'P02',
          },
        ],
      },
    );

    expect(catalog.projects.map((WorkRfiOption option) => option.id), <String>[
      'P01',
      'P02',
    ]);
    expect(catalog.projects.first.label, contains('Itarsi'));
    final List<WorkRfiContractOption> p01 = workRfiContractsForProject(
      catalog.contracts,
      'P01',
    );
    expect(p01.single.id, 'P01EN01');
    expect(p01.single.label, 'New Broad gauge line Between KM 25.4');
    expect(
      workRfiContractsForProject(catalog.contracts, 'P02').single.label,
      contains('Earthwork'),
    );
  });

  test('contract endpoint accepts a list or one object', () {
    expect(
      parseWorkRfiContracts(<String, dynamic>{
        'contractsList': <Map<String, dynamic>>[
          <String, dynamic>{
            'contract_id': 'P01EN01',
            'contract_short_name': 'Broad gauge',
          },
        ],
      }, projectId: 'P01').single.projectId,
      'P01',
    );
    final WorkRfiContractOption single = parseWorkRfiContracts(
      <String, dynamic>{
        'contract_id': 'P02EN02',
        'contract_name': 'Earthwork',
        'project_id_fk': 'P02',
      },
    ).single;
    expect(single.label, 'Earthwork');
    expect(single.projectId, 'P02');
    expect(parseWorkRfiContracts(null), isEmpty);
    expect(parseWorkRfiContracts(<dynamic>[]), isEmpty);
  });

  test('structure types ignore nulls and accept list, wrap, or object', () {
    expect(
      parseWorkRfiStructureTypes(<dynamic>[
        <String, dynamic>{'structure_type': 'Important Bridge', 'foo': 1},
        <String, dynamic>{'structure_type': 'Minor Bridge'},
        <String, dynamic>{'structure_type': null},
        <String, dynamic>{'structure_type': 'Important Bridge'},
      ]).map((WorkRfiOption option) => option.label),
      <String>['Important Bridge', 'Minor Bridge'],
    );
    expect(
      parseWorkRfiStructureTypes(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'structure_type': 'Minor Bridge'},
          <String, dynamic>{'structure_type': null},
        ],
      }).single.id,
      'Minor Bridge',
    );
    expect(
      parseWorkRfiStructureTypes(<String, dynamic>{
        'structure_type': 'Important Bridge',
        'contract_id_fk': 'P01EN01',
      }).single.label,
      'Important Bridge',
    );
    expect(parseWorkRfiStructureTypes(<dynamic>[]), isEmpty);
  });

  test(
    'structures, components, elements, and activities parse both shapes',
    () {
      final List<WorkRfiOption> structures = parseWorkRfiStructures(<dynamic>[
        <String, dynamic>{
          'structure_id': 7,
          'strip_chart_structure_id_fk': '43 (RCC Box)',
        },
        <String, dynamic>{
          'structure_id': '61',
          'strip_chart_structure_id_fk': '343 UP (Open Web Girder)',
        },
      ]);
      expect(structures.map((WorkRfiOption option) => option.id), <String>[
        '7',
        '61',
      ]);
      expect(structures.first.label, '43 (RCC Box)');
      expect(
        parseWorkRfiStructures(<String, dynamic>{
          'structure_id': 6872,
          'strip_chart_structure_id_fk': '133/1 (RCC BOX)',
        }).single.id,
        '6872',
      );

      expect(
        parseWorkRfiComponents(<dynamic>[
          <String, dynamic>{'strip_chart_component': 'Excavation & Levelling'},
          <String, dynamic>{'strip_chart_component': 'Bottom Slab'},
        ]).map((WorkRfiOption option) => option.id),
        <String>['Excavation & Levelling', 'Bottom Slab'],
      );
      expect(
        parseWorkRfiComponents(<String, dynamic>{
          'strip_chart_component': 'Bottom Slab',
        }).single.label,
        'Bottom Slab',
      );

      expect(
        parseWorkRfiElements(<String, dynamic>{
          'data': <String, dynamic>{
            'strip_chart_component_id': 'Bottom Haunch',
          },
        }).single.id,
        'Bottom Haunch',
      );
      expect(
        parseWorkRfiElements(<dynamic>[
          <String, dynamic>{'strip_chart_component_id': 'Excavation'},
        ]).single.label,
        'Excavation',
      );

      final List<WorkRfiOption> activities = parseWorkRfiActivities(<dynamic>[
        <String, dynamic>{
          'strip_chart_activity_id': '2902',
          'strip_chart_activity_name': 'Excavation',
        },
        <String, dynamic>{
          'strip_chart_activity_id': 363548,
          'strip_chart_activity_name': 'Concrete',
        },
      ]);
      expect(activities.map((WorkRfiOption option) => option.id), <String>[
        '2902',
        '363548',
      ]);
      expect(activities.last.label, 'Concrete');
      expect(
        parseWorkRfiActivities(<String, dynamic>{
          'strip_chart_activity_id': '2902',
          'strip_chart_activity_name': 'Excavation',
        }).single.label,
        'Excavation',
      );
    },
  );

  test('descriptions and enclosures accept object, list, or empty', () {
    final List<WorkRfiOption> one = parseWorkRfiDescriptions(<String, dynamic>{
      'id': 71,
      'rfiDescription': 'Excavation',
      'enclosures': <String>['69'],
    });
    expect(one.single.id, '71');
    expect(one.single.label, 'Excavation');
    expect(
      parseWorkRfiDescriptions(<dynamic>[
        <String, dynamic>{'id': 58, 'rfiDescription': 'Raw Materials'},
        <String, dynamic>{'id': 71, 'rfiDescription': 'Concrete'},
      ]).map((WorkRfiOption option) => option.id),
      <String>['58', '71'],
    );
    expect(parseWorkRfiDescriptions(null), isEmpty);
    expect(parseWorkRfiDescriptions(<dynamic>[]), isEmpty);
    expect(parseWorkRfiDescriptions(<String, dynamic>{}), isEmpty);

    expect(
      parseWorkRfiEnclosures(<String, dynamic>{
        'id': 69,
        'encloserName': 'Excavation',
        'rfiCategory': 'WORK',
      }).single.label,
      'Excavation',
    );
    expect(
      parseWorkRfiEnclosures(<dynamic>[
        <String, dynamic>{'id': 69, 'encloserName': 'Main Work'},
        <String, dynamic>{
          'id': '70',
          'encloserName': 'RCC Work - Fine Aggregates',
        },
      ]).map((WorkRfiOption option) => option.id),
      <String>['69', '70'],
    );
    expect(
      parseWorkRfiEnclosures(<String, dynamic>{
        'data': <String, dynamic>{'id': 69, 'encloserName': 'Excavation'},
      }).single.id,
      '69',
    );
    expect(parseWorkRfiEnclosures(<dynamic>[]), isEmpty);
  });

  test('representatives read flexible keys and an empty list', () {
    expect(parseWorkRfiRepresentatives(<dynamic>[]), isEmpty);
    expect(
      parseWorkRfiRepresentatives(<String, dynamic>{
        'representatives': <Map<String, dynamic>>[
          <String, dynamic>{
            'userId': 'PMIS_RU_001',
            'userName': 'IT Test Contractor Rep',
          },
        ],
      }).single.id,
      'PMIS_RU_001',
    );
    expect(
      parseWorkRfiRepresentatives(<String, dynamic>{
        'userId': 'PMIS_RU_001',
        'userName': 'IT Test Contractor Rep',
      }).single,
      isA<WorkRfiOption>()
          .having((WorkRfiOption option) => option.id, 'id', 'PMIS_RU_001')
          .having(
            (WorkRfiOption option) => option.label,
            'label',
            'IT Test Contractor Rep',
          ),
    );
    expect(
      parseWorkRfiRepresentatives(<dynamic>[
        <String, dynamic>{'user_id': 'U2', 'name': 'Other'},
        <String, dynamic>{'id': 'U3', 'nameOfRepresentative': 'Third'},
      ]).map((WorkRfiOption option) => option.id),
      <String>['U2', 'U3'],
    );
  });

  test('detail reads typeOfRFI, numeric structure, and measurements', () {
    final WorkRfiDetail? detail = parseWorkRfiDetail(<String, dynamic>{
      'id': 33,
      'project': 'P01',
      'contract': 'P01EN01',
      'structureType': 'Important Bridge',
      'structure': 7,
      'component': 'Excavation & Levelling',
      'element': 'Excavation',
      'activity': '2902',
      'activityList': <String>['2902'],
      'rfiDescriptionList': <String>['71'],
      'enclosuresList': <dynamic>[69],
      'rfiRequired': 'Yes',
      'action': 'Create',
      'typeOfRFI': 'Spot RFI',
      'userIdOfRepresentative': 'PMIS_RU_001',
      'nameOfRepresentative': 'IT Test Contractor Rep',
      'timeOfInspection': '14:30',
      'dateOfSubmission': '2026-10-01',
      'dateOfInspection': '2026-10-01',
      'description': 'Testing _ RFI',
      'measurements': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 1,
          'measurementType': 'Volume',
          'length': 44,
          'breadth': 44,
          'height': 44,
          'weight': 0,
          'units': 'cm³',
          'noOfItems': 6,
          'totalQty': 511104,
          'activityIdFk': 362805,
          'activityName': 'Earth Filling',
        },
      ],
    });

    expect(detail, isNotNull);
    expect(detail!.structure, '7');
    expect(detail.typeOfRfi, 'Spot RFI');
    expect(detail.enclosuresList, <String>['69']);
    expect(detail.measurements.single.activityId, '362805');
    expect(detail.measurements.single.no, '6');
    expect(detail.measurements.single.length, '44');
    expect(parseWorkRfiDetail(<String, dynamic>{}), isNull);
    expect(parseWorkRfiDetail(null), isNull);
  });

  test(
    'edit keeps activityList ids and measurement ids missing from options',
    () {
      const List<WorkRfiOption> options = <WorkRfiOption>[
        WorkRfiOption(id: '2902', label: 'Excavation'),
        WorkRfiOption(id: '362805', label: 'Earth Filling'),
      ];
      final WorkRfiEditActivities resolved = resolveWorkRfiEditActivities(
        options: options,
        activityList: const <String>['2902'],
        activityId: '2902',
        measurements: const <WorkRfiMeasurementDraft>[
          WorkRfiMeasurementDraft(
            activityId: '362805',
            activityName: 'Earth Filling',
            measurementType: 'Volume',
            units: 'cm³',
            length: '44',
            breadth: '44',
            height: '44',
            weight: '0',
            no: '6',
          ),
          WorkRfiMeasurementDraft(
            activityId: '9999',
            activityName: 'Extra Pour',
            measurementType: 'Number',
            units: 'Nos',
            no: '3',
          ),
        ],
      );

      expect(
        resolved.selected.map((WorkRfiOption option) => option.id),
        <String>['2902', '362805', '9999'],
      );
      expect(resolved.rows[0].measurementType, isEmpty);
      expect(resolved.rows[1].activityName, 'Earth Filling');
      expect(resolved.rows[1].length, '44');
      expect(resolved.rows[2].activityName, 'Extra Pour');
      expect(resolved.rows[2].units, 'Nos');
    },
  );

  test('total quantity uses only the fields that type enables', () {
    expect(
      workRfiTotalQty(
        measurementType: 'Volume',
        length: '44',
        breadth: '44',
        height: '44',
        weight: '9',
        no: '6',
      ),
      511104,
    );
    expect(
      workRfiTotalQty(
        measurementType: 'Volume',
        length: '',
        breadth: '44',
        height: '44',
        weight: '0',
        no: '6',
      ),
      isNull,
    );
    expect(
      workRfiTotalQty(
        measurementType: 'Area',
        length: '2',
        breadth: '3',
        height: '9',
        weight: '',
        no: '4',
      ),
      24,
    );
    expect(
      workRfiTotalQty(
        measurementType: 'Length',
        length: '5',
        breadth: '',
        height: '',
        weight: '',
        no: '2',
      ),
      10,
    );
    expect(
      workRfiTotalQty(
        measurementType: 'Weight',
        length: '',
        breadth: '',
        height: '',
        weight: '1.5',
        no: '2',
      ),
      3,
    );
    expect(
      workRfiTotalQty(
        measurementType: 'Number',
        length: '',
        breadth: '',
        height: '',
        weight: '',
        no: '22',
      ),
      22,
    );
    expect(
      workRfiTotalQty(
        measurementType: 'Number',
        length: '4',
        breadth: '4',
        height: '4',
        weight: '4',
        no: '',
      ),
      isNull,
    );
  });

  test(
    'yes edit payload sends numeric volume factors and inspection fields',
    () {
      final Map<String, dynamic> body = buildWorkRfiPayload(
        const WorkRfiSubmitDraft(
          project: 'P01',
          contract: 'P01EN01',
          structureType: 'Important Bridge',
          structure: '7',
          component: 'Excavation & Levelling',
          element: 'Excavation',
          activities: <WorkRfiMeasurementDraft>[
            WorkRfiMeasurementDraft(
              activityId: '362805',
              activityName: 'Earth Filling',
              measurementType: 'Volume',
              units: 'cm³',
              length: '44',
              breadth: '44',
              height: '44',
              weight: '0',
              no: '6',
            ),
          ],
          descriptionIds: <String>['71'],
          rfiRequired: 'Yes',
          typeOfRfi: 'Spot RFI',
          contractorRepresentative: 'PMIS_RU_001',
          progressDate: '',
          dateOfSubmission: '2026-10-01',
          timeOfInspection: '02:30 PM',
          dateOfInspection: '01/10/2026',
          enclosureIds: <String>['69'],
          description: 'Testing _ RFI',
          editing: true,
        ),
      );

      expect(body['activity'], '362805');
      expect(body['selectedActivities'], <String>['362805']);
      expect(body['rfiDescription'], isEmpty);
      expect(body['selectedRfiDescriptions'], <String>['71']);
      expect(body['rfiDescriptions'], <String>['71']);
      expect(body['rfiRequired'], 'Yes');
      expect(body['action'], 'Create');
      expect(body['typeOfRfi'], 'Spot RFI');
      expect(body['contractorRepresentative'], 'PMIS_RU_001');
      expect(body['progressDate'], isEmpty);
      expect(body['dateOfSubmission'], '2026-10-01');
      expect(body['timeOfInspection'], '14:30');
      expect(body['dateOfInspection'], '2026-10-01');
      expect(body['boqItemRequired'], isEmpty);
      expect(body['selectedEnclosures'], <String>['69']);
      expect(body['enclosures'], <String>['69']);
      expect(body['projectId'], 'P01');
      expect(body['structureId'], '7');
      expect(body['chainageFrom'], isEmpty);
      final Map<String, dynamic> row =
          (body['activities'] as List<dynamic>).single as Map<String, dynamic>;
      expect(row['id'], '362805');
      expect(row['activityId'], '362805');
      expect(row['activity'], '362805');
      expect(row['activityName'], 'Earth Filling');
      expect(row['measurementType'], 'Volume');
      expect(row['units'], 'cm³');
      expect(row['length'], 44);
      expect(row['breadth'], 44);
      expect(row['height'], 44);
      expect(row['weight'], isEmpty);
      expect(row['no'], 6);
      expect(row['totalQty'], 511104);
    },
  );

  test(
    'no create payload blanks inspection fields and totals a number row',
    () {
      final Map<String, dynamic> body = buildWorkRfiPayload(
        const WorkRfiSubmitDraft(
          project: 'P02',
          contract: 'P02EN02',
          structureType: 'Minor Bridge',
          structure: '6872',
          component: 'Bottom Slab',
          element: 'Bottom Haunch',
          activities: <WorkRfiMeasurementDraft>[
            WorkRfiMeasurementDraft(
              activityId: '363548',
              activityName: 'Concrete',
              measurementType: 'Number',
              units: 'Nos',
              length: '44',
              breadth: '44',
              height: '44',
              weight: '9',
              no: '22',
            ),
          ],
          descriptionIds: <String>['58'],
          rfiRequired: 'No',
          typeOfRfi: 'Spot RFI',
          contractorRepresentative: 'PMIS_RU_001',
          progressDate: '12/10/2026',
          dateOfSubmission: '2026-10-12',
          timeOfInspection: '15:52',
          dateOfInspection: '2026-10-12',
          enclosureIds: <String>['69'],
          description: '',
        ),
      );

      expect(body['project'], 'P02');
      expect(body['contract'], 'P02EN02');
      expect(body['structure'], '6872');
      expect(body['activity'], '363548');
      expect(body['selectedActivities'], <String>['363548']);
      expect(body['rfiRequired'], 'No');
      expect(body['typeOfRfi'], isEmpty);
      expect(body['contractorRepresentative'], isEmpty);
      expect(body['progressDate'], '2026-10-12');
      expect(body['dateOfSubmission'], isEmpty);
      expect(body['timeOfInspection'], isEmpty);
      expect(body['dateOfInspection'], isEmpty);
      expect(body['boqItemRequired'], isEmpty);
      expect(body['selectedEnclosures'], isEmpty);
      expect(body['enclosures'], isEmpty);
      expect(body['selectedRfiDescriptions'], <String>['58']);
      expect(body['rfiDescriptions'], <String>['58']);
      expect(body['projectId'], 'P02');
      expect(body['structureId'], '6872');
      final Map<String, dynamic> row =
          (body['activities'] as List<dynamic>).single as Map<String, dynamic>;
      expect(row['length'], isEmpty);
      expect(row['breadth'], isEmpty);
      expect(row['height'], isEmpty);
      expect(row['weight'], isEmpty);
      expect(row['no'], '22');
      expect(row['totalQty'], 22);
      expect(row['units'], 'Nos');
      expect(row['activityName'], 'Concrete');
    },
  );

  test('type of RFI options are Regular RFI and Spot RFI', () {
    expect(
      workRfiTypeOptions.map((WorkRfiOption option) => option.label),
      <String>['Regular RFI', 'Spot RFI'],
    );
    expect(
      workRfiTypeOptions.map((WorkRfiOption option) => option.id),
      <String>['Regular RFI', 'Spot RFI'],
    );
  });

  test('dates and times format for the form and the API', () {
    expect(workRfiDisplayDate('2026-10-01'), '01/10/2026');
    expect(workRfiApiDate('12/10/2026'), '2026-10-12');
    expect(workRfiDisplayTime('14:30'), '02:30 PM');
    expect(workRfiDisplayTime('15:52'), '03:52 PM');
    expect(workRfiApiTime('02:30 PM'), '14:30');
  });

  test('earthwork and blanketing detection is case-insensitive', () {
    expect(workRfiIsEarthworkOrBlanketing('Earthwork'), isTrue);
    expect(workRfiIsEarthworkOrBlanketing('earthwork'), isTrue);
    expect(workRfiIsEarthworkOrBlanketing(' EARTHWORK '), isTrue);
    expect(workRfiIsEarthworkOrBlanketing('Blanketing'), isTrue);
    expect(workRfiIsEarthworkOrBlanketing('blanketing'), isTrue);
    expect(workRfiIsEarthworkOrBlanketing('RUB'), isFalse);
    expect(workRfiIsEarthworkOrBlanketing('Minor Bridge'), isFalse);
    expect(workRfiIsEarthworkOrBlanketing(''), isFalse);
  });

  test('layer labels run from min through max', () {
    expect(
      workRfiLayerOptions(
        minLayer: 1,
        maxLayer: 3,
      ).map((WorkRfiOption option) => option.id),
      <String>['Layer 1', 'Layer 2', 'Layer 3'],
    );
    expect(workRfiPostedLayer('2'), 'Layer 2');
    expect(workRfiPostedLayer('Layer 2'), 'Layer 2');
    final WorkRfiLayerRange? blanketing = parseWorkRfiLayerRange(
      <String, dynamic>{'maxLayer': 3, 'minLayer': 1},
    );
    expect(blanketing?.minLayer, 1);
    expect(blanketing?.maxLayer, 3);
    final WorkRfiLayerRange? earthwork = parseWorkRfiLayerRange(
      <String, dynamic>{'maxLayer': 54, 'minLayer': 1},
    );
    expect(
      workRfiLayerOptions(
        minLayer: earthwork!.minLayer,
        maxLayer: earthwork.maxLayer,
      ),
      hasLength(54),
    );
    expect(
      workRfiLayerOptions(
        minLayer: earthwork.minLayer,
        maxLayer: earthwork.maxLayer,
      ).first.label,
      'Layer 1',
    );
    expect(
      workRfiLayerOptions(
        minLayer: earthwork.minLayer,
        maxLayer: earthwork.maxLayer,
      ).last.label,
      'Layer 54',
    );
  });

  test('structure object uses structure id and strip chart label', () {
    final WorkRfiOption structure = parseWorkRfiStructures(<String, dynamic>{
      'structure_id': '170',
      'strip_chart_structure_id_fk': 'CH 25400 to CH 34000',
      'contract_id_fk': null,
      'component': null,
    }).single;
    expect(structure.id, '170');
    expect(structure.label, 'CH 25400 to CH 34000');
  });

  test('chainage posts whole multiples of 10 and rejects plus notation', () {
    const String fromAlert =
        'Chainage From must be a whole number divisible by 10. Please re-enter.';
    const String toAlert =
        'Chainage To must be a whole number divisible by 10. Please re-enter.';
    expect(workRfiChainageError('10', fieldLabel: 'Chainage From'), isNull);
    expect(workRfiChainageError('30', fieldLabel: 'Chainage To'), isNull);
    expect(workRfiPostedChainage('10'), '10');
    expect(workRfiPostedChainage('30'), '30');
    expect(
      workRfiChainageError('12.5', fieldLabel: 'Chainage From'),
      fromAlert,
    );
    expect(
      workRfiChainageError('12+501', fieldLabel: 'Chainage From'),
      fromAlert,
    );
    expect(
      workRfiChainageError('12+000', fieldLabel: 'Chainage From'),
      fromAlert,
    );
    expect(workRfiChainageError('12+500', fieldLabel: 'Chainage To'), toAlert);
    expect(workRfiPostedChainage('12+000'), isEmpty);
    expect(workRfiPostedChainage('12+500'), isEmpty);
    expect(workRfiPostedChainage('12.5'), isEmpty);

    final Map<String, dynamic> body = buildWorkRfiPayload(
      const WorkRfiSubmitDraft(
        project: 'P01',
        contract: 'P01EN01',
        structureType: 'Blanketing',
        structure: '55',
        component: '',
        element: '',
        activities: <WorkRfiMeasurementDraft>[],
        descriptionIds: <String>[],
        rfiRequired: 'No',
        typeOfRfi: '',
        contractorRepresentative: '',
        progressDate: '2026-10-12',
        dateOfSubmission: '',
        timeOfInspection: '',
        dateOfInspection: '',
        enclosureIds: <String>[],
        description: '',
        chainageFrom: '10',
        chainageTo: '30',
        layer: '2',
      ),
    );
    expect(body['chainageFrom'], '10');
    expect(body['chainageTo'], '30');
    expect(body['layer'], 'Layer 2');
  });

  group('create payload matches the web capture', () {
    const WorkRfiOption blanketingOption = WorkRfiOption(
      id: 'Blanketing',
      label: 'Blanketing',
    );

    WorkRfiSubmitDraft blanketingDraft({
      required String rfiRequired,
      String structureType = 'Blanketing',
      String activityId = 'Blanketing',
      String activityName = 'Blanketing',
    }) {
      final bool yes = rfiRequired == 'Yes';
      return WorkRfiSubmitDraft(
        project: 'P01',
        contract: 'P01EN01',
        structureType: structureType,
        structure: '55',
        component: 'Finishes',
        element:
            'Approach Road, Apron, curtain wall, drop wall and other protection works',
        chainageFrom: '40',
        chainageTo: '50',
        layer: 'Layer 2',
        activities: <WorkRfiMeasurementDraft>[
          WorkRfiMeasurementDraft(
            activityId: activityId,
            activityName: activityName,
            measurementType: 'Number',
            units: 'Nos',
            no: '5',
          ),
        ],
        descriptionIds: const <String>['1'],
        rfiRequired: rfiRequired,
        typeOfRfi: yes ? 'Spot RFI' : '',
        contractorRepresentative: yes ? 'PMIS_RU_001' : '',
        progressDate: yes ? '' : '2026-10-12',
        dateOfSubmission: yes ? '2026-10-13' : '',
        timeOfInspection: yes ? '12:54' : '',
        dateOfInspection: yes ? '2026-10-13' : '',
        enclosureIds: yes ? const <String>['4', '34', '44'] : const <String>[],
        description: '',
        today: DateTime(2026, 10, 13),
      );
    }

    Map<String, dynamic> activityRow(Map<String, dynamic> body) =>
        (body['activities'] as List<dynamic>).single as Map<String, dynamic>;

    test('Blanketing, RFI Required Yes, Spot RFI equals the web body', () {
      final WorkRfiSubmitDraft draft = blanketingDraft(rfiRequired: 'Yes');
      expect(workRfiValidationMessage(draft), isNull);
      final Map<String, dynamic> body = buildWorkRfiPayload(draft);

      expect(body, <String, dynamic>{
        'project': 'P01',
        'contract': 'P01EN01',
        'structureType': 'Blanketing',
        'structure': '55',
        'component': 'Finishes',
        'element':
            'Approach Road, Apron, curtain wall, drop wall and other protection works',
        'chainageFrom': '40',
        'chainageTo': '50',
        'layer': 'Layer 2',
        'activity': '0',
        'selectedActivities': <String>['0'],
        'rfiDescription': '',
        'selectedRfiDescriptions': <String>['1'],
        'rfiRequired': 'Yes',
        'action': 'Create',
        'typeOfRfi': 'Spot RFI',
        'contractorRepresentative': 'PMIS_RU_001',
        'progressDate': '',
        'dateOfSubmission': '2026-10-13',
        'timeOfInspection': '12:54',
        'dateOfInspection': '2026-10-13',
        'boqItemRequired': '',
        'boqItem': '',
        'selectedEnclosures': <String>['4', '34', '44'],
        'description': '',
        'activities': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': '0',
            'activityId': '0',
            'activity': '0',
            'activityName': 'Blanketing',
            'measurementType': 'Number',
            'units': 'Nos',
            'length': '',
            'breadth': '',
            'height': '',
            'weight': '',
            'no': '5',
            'totalQty': 5,
          },
        ],
        'rfiDescriptions': <String>['1'],
        'enclosures': <String>['4', '34', '44'],
        'projectId': 'P01',
        'structureId': '55',
      });
      expect(activityRow(body)['no'], isA<String>());
      expect(activityRow(body)['totalQty'], isA<int>());
      // The local option id/label stay untouched: the description lookup is
      // keyed by the label, never by the posted id.
      expect(blanketingOption.id, 'Blanketing');
      expect(blanketingOption.label, 'Blanketing');
    });

    test('Blanketing, RFI Required No keeps ids "0" and blank boq/dates', () {
      final WorkRfiSubmitDraft draft = blanketingDraft(rfiRequired: 'No');
      expect(workRfiValidationMessage(draft), isNull);
      final Map<String, dynamic> body = buildWorkRfiPayload(draft);

      expect(body['activity'], '0');
      expect(body['selectedActivities'], <String>['0']);
      expect(body['boqItemRequired'], '');
      expect(body['boqItem'], '');
      expect(body['progressDate'], '2026-10-12');
      expect(body['dateOfSubmission'], '');
      expect(body['timeOfInspection'], '');
      expect(body['dateOfInspection'], '');
      expect(body['selectedEnclosures'], isEmpty);
      expect(body['enclosures'], isEmpty);
      final Map<String, dynamic> row = activityRow(body);
      expect(row['id'], '0');
      expect(row['activityId'], '0');
      expect(row['activity'], '0');
      expect(row['activityName'], 'Blanketing');
      expect(row['no'], '5');
      expect(row['totalQty'], 5);
    });

    test('Earthwork also posts "0" and keeps its name in activityName', () {
      final Map<String, dynamic> body = buildWorkRfiPayload(
        blanketingDraft(
          rfiRequired: 'Yes',
          structureType: 'Earthwork',
          activityId: 'Earthwork',
          activityName: 'Earthwork',
        ),
      );
      expect(body['activity'], '0');
      expect(body['selectedActivities'], <String>['0']);
      final Map<String, dynamic> row = activityRow(body);
      expect(row['id'], '0');
      expect(row['activityId'], '0');
      expect(row['activity'], '0');
      expect(row['activityName'], 'Earthwork');
    });

    test('other structure types keep the strip-chart activity id', () {
      final Map<String, dynamic> body = buildWorkRfiPayload(
        blanketingDraft(
          rfiRequired: 'Yes',
          structureType: 'Minor Bridge',
          activityId: '2174',
          activityName: 'Concrete',
        ),
      );
      expect(body['activity'], '2174');
      expect(body['selectedActivities'], <String>['2174']);
      final Map<String, dynamic> row = activityRow(body);
      expect(row['id'], '2174');
      expect(row['activityId'], '2174');
      expect(row['activity'], '2174');
      expect(row['activityName'], 'Concrete');
    });

    test('a non-numeric activity id is rejected before sending', () {
      final String? message = workRfiValidationMessage(
        blanketingDraft(
          rfiRequired: 'Yes',
          structureType: 'Minor Bridge',
          activityId: 'Concrete',
          activityName: 'Concrete',
        ),
      );
      expect(message, isNotNull);
      expect(message, contains('valid activity'));
      expect(message, contains('Concrete'));
    });

    test('edit keeps numeric ids and numeric measurement factors', () {
      final WorkRfiSubmitDraft base = blanketingDraft(
        rfiRequired: 'Yes',
        structureType: 'Minor Bridge',
        activityId: '2174',
        activityName: 'Concrete',
      );
      final Map<String, dynamic> body = buildWorkRfiPayload(
        WorkRfiSubmitDraft(
          project: base.project,
          contract: base.contract,
          structureType: base.structureType,
          structure: base.structure,
          component: base.component,
          element: base.element,
          activities: base.activities,
          descriptionIds: base.descriptionIds,
          rfiRequired: base.rfiRequired,
          typeOfRfi: base.typeOfRfi,
          contractorRepresentative: base.contractorRepresentative,
          progressDate: base.progressDate,
          dateOfSubmission: base.dateOfSubmission,
          timeOfInspection: base.timeOfInspection,
          dateOfInspection: base.dateOfInspection,
          enclosureIds: base.enclosureIds,
          description: base.description,
          editing: true,
        ),
      );
      final Map<String, dynamic> row = activityRow(body);
      expect(row['id'], '2174');
      expect(row['activityId'], '2174');
      expect(row['no'], 5);
      expect(row['totalQty'], 5);
      expect(body['boqItemRequired'], '');
    });
  });

  group('Date of Inspection rules', () {
    // Injected local "today" with a time of day that must be ignored.
    final DateTime today = DateTime(2026, 10, 13, 23, 45);
    final DateTime yesterday = DateTime(2026, 10, 12);
    final DateTime todayDate = DateTime(2026, 10, 13);
    final DateTime tomorrow = DateTime(2026, 10, 14);
    final DateTime plusTwo = DateTime(2026, 10, 15);

    bool allowed(String type, DateTime date) =>
        workRfiInspectionDateAllowed(typeOfRfi: type, date: date, today: today);

    WorkRfiSubmitDraft draft({
      String type = 'Regular RFI',
      String date = '',
      String originalType = '',
      String originalDate = '',
    }) {
      return WorkRfiSubmitDraft(
        project: 'P01',
        contract: 'P01EN01',
        structureType: 'Minor Bridge',
        structure: '7',
        component: 'Bottom Slab',
        element: 'Bottom Haunch',
        activities: const <WorkRfiMeasurementDraft>[
          WorkRfiMeasurementDraft(
            activityId: '1',
            activityName: 'Concrete',
            measurementType: 'Number',
            units: 'Nos',
            no: '2',
          ),
        ],
        descriptionIds: const <String>['71'],
        rfiRequired: 'Yes',
        typeOfRfi: type,
        contractorRepresentative: 'U1',
        progressDate: '',
        dateOfSubmission: '2026-10-13',
        timeOfInspection: '10:00',
        dateOfInspection: date,
        enclosureIds: const <String>['69'],
        description: '',
        today: today,
        originalTypeOfRfi: originalType,
        originalDateOfInspection: originalDate,
      );
    }

    test('earliest date: Regular is today + 2, Spot is today', () {
      expect(
        workRfiEarliestInspectionDate(typeOfRfi: 'Regular RFI', today: today),
        plusTwo,
      );
      expect(
        workRfiEarliestInspectionDate(typeOfRfi: 'Spot RFI', today: today),
        todayDate,
      );
      expect(
        workRfiEarliestInspectionDate(typeOfRfi: '', today: today),
        isNull,
      );
    });

    test('Regular + 2 rolls over month and year boundaries', () {
      expect(
        workRfiEarliestInspectionDate(
          typeOfRfi: 'Regular RFI',
          today: DateTime(2026, 12, 31, 8),
        ),
        DateTime(2027, 1, 2),
      );
    });

    test('yesterday is rejected for both types', () {
      expect(allowed('Regular RFI', yesterday), isFalse);
      expect(allowed('Spot RFI', yesterday), isFalse);
    });

    test('today is rejected for Regular and accepted for Spot', () {
      expect(allowed('Regular RFI', todayDate), isFalse);
      expect(allowed('Spot RFI', todayDate), isTrue);
    });

    test('tomorrow is rejected for Regular and accepted for Spot', () {
      expect(allowed('Regular RFI', tomorrow), isFalse);
      expect(allowed('Spot RFI', tomorrow), isTrue);
    });

    test('today + 2 is accepted for Regular', () {
      expect(allowed('Regular RFI', plusTwo), isTrue);
      expect(allowed('Regular RFI', DateTime(2026, 11, 1)), isTrue);
    });

    test('unknown type allows nothing', () {
      expect(allowed('', plusTwo), isFalse);
    });

    test('type change clears a date that breaks the new rule', () {
      expect(
        workRfiInspectionDateAfterTypeChange(
          newType: 'Regular RFI',
          current: todayDate,
          today: today,
        ),
        isNull,
      );
      expect(
        workRfiInspectionDateAfterTypeChange(
          newType: 'Regular RFI',
          current: tomorrow,
          today: today,
        ),
        isNull,
      );
      expect(
        workRfiInspectionDateAfterTypeChange(
          newType: 'Spot RFI',
          current: yesterday,
          today: today,
        ),
        isNull,
      );
    });

    test('type change keeps a date that still satisfies the new rule', () {
      expect(
        workRfiInspectionDateAfterTypeChange(
          newType: 'Spot RFI',
          current: plusTwo,
          today: today,
        ),
        plusTwo,
      );
      expect(
        workRfiInspectionDateAfterTypeChange(
          newType: 'Regular RFI',
          current: plusTwo,
          today: today,
        ),
        plusTwo,
      );
      expect(
        workRfiInspectionDateAfterTypeChange(
          newType: 'Spot RFI',
          current: null,
          today: today,
        ),
        isNull,
      );
    });

    test('validation names the Regular and Spot rules', () {
      expect(
        workRfiValidationMessage(draft(date: '2026-10-14')),
        'Date of Inspection for a Regular RFI must be at least 2 days from today.',
      );
      expect(
        workRfiValidationMessage(draft(date: '2026-10-13')),
        'Date of Inspection for a Regular RFI must be at least 2 days from today.',
      );
      expect(workRfiValidationMessage(draft(date: '2026-10-15')), isNull);
      expect(
        workRfiValidationMessage(draft(type: 'Spot RFI', date: '2026-10-12')),
        'Date of Inspection for a Spot RFI cannot be in the past.',
      );
      expect(
        workRfiValidationMessage(draft(type: 'Spot RFI', date: '2026-10-13')),
        isNull,
      );
    });

    test('validation accepts dd/MM/yyyy dates and still reports missing', () {
      expect(workRfiValidationMessage(draft(date: '15/10/2026')), isNull);
      expect(
        workRfiValidationMessage(draft(date: '')),
        'Missing Date of Inspection.',
      );
    });

    test('rule is not applied when RFI Required is No', () {
      final WorkRfiSubmitDraft no = WorkRfiSubmitDraft(
        project: 'P01',
        contract: 'P01EN01',
        structureType: 'Minor Bridge',
        structure: '7',
        component: 'Bottom Slab',
        element: 'Bottom Haunch',
        activities: const <WorkRfiMeasurementDraft>[
          WorkRfiMeasurementDraft(
            activityId: '1',
            activityName: 'Concrete',
            measurementType: 'Number',
            units: 'Nos',
            no: '2',
          ),
        ],
        descriptionIds: const <String>['71'],
        rfiRequired: 'No',
        typeOfRfi: 'Regular RFI',
        contractorRepresentative: '',
        progressDate: '2026-10-01',
        dateOfSubmission: '',
        timeOfInspection: '',
        dateOfInspection: '2026-10-01',
        enclosureIds: const <String>[],
        description: '',
        today: today,
      );
      expect(workRfiValidationMessage(no), isNull);
    });

    test('edit: unchanged saved past date and type stay valid', () {
      expect(
        workRfiValidationMessage(
          draft(
            type: 'Regular RFI',
            date: '2026-10-01',
            originalType: 'Regular RFI',
            originalDate: '2026-10-01',
          ),
        ),
        isNull,
      );
      expect(
        workRfiValidationMessage(
          draft(
            type: 'Spot RFI',
            date: '01/10/2026',
            originalType: 'Spot RFI',
            originalDate: '2026-10-01',
          ),
        ),
        isNull,
      );
    });

    test('edit: a newly picked or retyped past date must follow the rules', () {
      expect(
        workRfiValidationMessage(
          draft(
            type: 'Spot RFI',
            date: '2026-10-02',
            originalType: 'Spot RFI',
            originalDate: '2026-10-01',
          ),
        ),
        'Date of Inspection for a Spot RFI cannot be in the past.',
      );
      expect(
        workRfiValidationMessage(
          draft(
            type: 'Regular RFI',
            date: '2026-10-01',
            originalType: 'Spot RFI',
            originalDate: '2026-10-01',
          ),
        ),
        'Date of Inspection for a Regular RFI must be at least 2 days from today.',
      );
    });
  });

  test('validation names the first missing location and measurement fields', () {
    expect(
      workRfiValidationMessage(
        const WorkRfiSubmitDraft(
          project: '',
          contract: '',
          structureType: '',
          structure: '',
          component: '',
          element: '',
          activities: <WorkRfiMeasurementDraft>[],
          descriptionIds: <String>[],
          rfiRequired: '',
          typeOfRfi: '',
          contractorRepresentative: '',
          progressDate: '',
          dateOfSubmission: '',
          timeOfInspection: '',
          dateOfInspection: '',
          enclosureIds: <String>[],
          description: '',
        ),
      ),
      'Missing Project, Contract, Structure Type, Structure, Component, Element, Activity, RFI Description, RFI Required.',
    );
  });
}
