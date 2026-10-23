import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/forms/form_menu_tree.dart';
import 'package:swr_pmis_mobile/src/features/update_forms/domain/entities/update_forms_tree.dart';
import 'package:swr_pmis_mobile/src/features/update_forms/domain/update_form_destination.dart';

void main() {
  test('update forms keep active mobile rows and sort each level', () {
    final UpdateFormsTree tree = UpdateFormsTree.fromApi(_sampleForms());
    final Set<String> names = _names(tree.forms);

    expect(names, isNot(contains('Quality Inspections')));
    expect(names, isNot(contains('Modify Actuals')));
    expect(names, isNot(contains('Land Acquisition process')));
    expect(names, isNot(contains('Add Land Details')));
    expect(names, isNot(contains('Inspection Checklist')));
    expect(names, isNot(contains('Closed Update')));
    expect(names, isNot(contains('Blank Mobile')));

    expect(
      tree.forms.map((FormMenuNode node) => node.formName),
      containsAll(<String>[
        'Projects',
        'Works',
        'Execution & Monitoring',
        'Design & Drawing',
      ]),
    );

    final FormMenuNode works = tree.forms.firstWhere(
      (FormMenuNode node) => node.formName == 'Works',
    );
    expect(works.children.map((FormMenuNode node) => node.formName), <String>[
      'Add Structure',
      'Update Structure',
    ]);

    final FormMenuNode execution = tree.forms.firstWhere(
      (FormMenuNode node) => node.formName == 'Execution & Monitoring',
    );
    expect(
      execution.children.map((FormMenuNode node) => node.formName),
      isNot(contains('Modify Actuals')),
    );
    expect(
      execution.children.map((FormMenuNode node) => node.formName),
      <String>[
        'Structure P6 Updates',
        'New Activities Update',
        'Linear Update Form',
      ],
    );

    final FormMenuNode land = tree.forms.firstWhere(
      (FormMenuNode node) => node.formName == 'Land Acquisition',
    );
    expect(land.webFormUrl, 'land-acquisition');
    expect(land.children, isEmpty);
    expect(land.isExpandable, isFalse);

    final FormMenuNode design = tree.forms.firstWhere(
      (FormMenuNode node) => node.formName == 'Design & Drawing',
    );
    expect(design.webFormUrl, 'design');
    expect(design.children, isEmpty);

    final FormMenuNode projects = tree.forms.firstWhere(
      (FormMenuNode node) => node.formName == 'Projects',
    );
    expect(projects.children.single.formName, 'Add Project');
    expect(projects.children.single.webFormUrl, 'project');
  });

  test('leaf route matches an existing module or stays unset', () {
    final UpdateFormsTree tree = UpdateFormsTree.fromApi(_sampleForms());
    final FormMenuNode projects = tree.forms.firstWhere(
      (FormMenuNode node) => node.formName == 'Projects',
    );
    final FormMenuNode works = tree.forms.firstWhere(
      (FormMenuNode node) => node.formName == 'Works',
    );
    final FormMenuNode design = tree.forms.firstWhere(
      (FormMenuNode node) => node.formName == 'Design & Drawing',
    );
    final FormMenuNode land = tree.forms.firstWhere(
      (FormMenuNode node) => node.formName == 'Land Acquisition',
    );

    expect(updateFormRouteName(projects.children.single), isNull);
    expect(updateFormRouteName(works.children.first), isNull);
    expect(updateFormRouteName(design), 'forms-design');
    expect(updateFormRouteName(land), 'forms-land');
  });

  test('Material Receipts under Quality Inspections routes to forms-quality', () {
    const FormMenuNode byUrl = FormMenuNode(
      formId: '1396',
      formName: 'Material Receipts',
      webFormUrl: 'materialreceipts',
      mobileFormUrl: '',
      priority: 1,
      children: <FormMenuNode>[],
    );
    const FormMenuNode byHyphenUrl = FormMenuNode(
      formId: '1396',
      formName: 'Other label',
      webFormUrl: 'material-receipts',
      mobileFormUrl: '',
      priority: 1,
      children: <FormMenuNode>[],
    );
    const FormMenuNode byName = FormMenuNode(
      formId: '1396',
      formName: 'Material Receipts',
      webFormUrl: '',
      mobileFormUrl: '',
      priority: 1,
      children: <FormMenuNode>[],
    );

    expect(updateFormRouteName(byUrl), 'forms-quality');
    expect(updateFormRouteName(byHyphenUrl), 'forms-quality');
    expect(updateFormRouteName(byName), 'forms-quality');
  });
}

Set<String> _names(List<FormMenuNode> nodes) {
  final Set<String> names = <String>{};
  for (final FormMenuNode node in nodes) {
    names.add(node.formName);
    names.addAll(_names(node.children));
  }
  return names;
}

List<Map<String, dynamic>> _sampleForms() {
  return <Map<String, dynamic>>[
    _form(
      formId: 1,
      formName: 'Projects',
      priority: 1,
      formsSubMenu: <Map<String, dynamic>>[
        _form(
          formId: 11,
          formName: 'Add Project',
          webFormUrl: 'project',
          priority: 1,
          parentId: 1,
          parentName: 'Projects',
        ),
      ],
    ),
    _form(
      formId: 2,
      formName: 'Works',
      priority: 2,
      formsSubMenu: <Map<String, dynamic>>[
        _form(
          formId: 22,
          formName: 'Update Structure',
          webFormUrl: 'structure-form',
          priority: 2,
          parentId: 2,
          parentName: 'Works',
        ),
        _form(
          formId: 21,
          formName: 'Add Structure',
          webFormUrl: 'structure',
          priority: 1,
          parentId: 2,
          parentName: 'Works',
        ),
      ],
    ),
    _form(
      formId: 3,
      formName: 'Contracts/Tenders',
      priority: 3,
      formsSubMenu: <Map<String, dynamic>>[
        _form(
          formId: 31,
          formName: 'Contract',
          webFormUrl: 'contract',
          priority: 1,
          parentId: 3,
          parentName: 'Contracts/Tenders',
        ),
        _form(
          formId: 32,
          formName: 'Contractor',
          webFormUrl: 'contractor',
          priority: 2,
          parentId: 3,
          parentName: 'Contracts/Tenders',
        ),
      ],
    ),
    _form(
      formId: 4,
      formName: 'Execution & Monitoring',
      priority: 4,
      formsSubMenu: <Map<String, dynamic>>[
        _form(
          formId: 41,
          formName: 'Modify Actuals',
          webFormUrl: 'modify-actuals',
          priority: 1,
          displayInMobile: 'No',
          parentId: 4,
          parentName: 'Execution & Monitoring',
        ),
        _form(
          formId: 44,
          formName: 'Linear Update Form',
          webFormUrl: 'linear-update-form',
          priority: 4,
          parentId: 4,
          parentName: 'Execution & Monitoring',
        ),
        _form(
          formId: 43,
          formName: 'New Activities Update',
          webFormUrl: 'new-activities-update',
          priority: 3,
          parentId: 4,
          parentName: 'Execution & Monitoring',
        ),
        _form(
          formId: 42,
          formName: 'Structure P6 Updates',
          webFormUrl: 'structure-p6-updates',
          priority: 2,
          parentId: 4,
          parentName: 'Execution & Monitoring',
        ),
      ],
    ),
    _form(
      formId: 5,
      formName: 'Design & Drawing',
      webFormUrl: 'design',
      priority: 5,
      formsSubMenu: <Map<String, dynamic>>[],
    ),
    _form(
      formId: 6,
      formName: 'Issues',
      webFormUrl: 'issues',
      priority: 6,
      displayInMobile: true,
      formsSubMenu: null,
    ),
    _form(
      formId: 7,
      formName: 'Utility Shifting',
      webFormUrl: 'utilityshifting',
      priority: 7,
      formsSubMenu: <Map<String, dynamic>>[],
    ),
    _form(
      formId: 8,
      formName: 'Quality Inspections',
      priority: 8,
      displayInMobile: 'No',
      formsSubMenu: <Map<String, dynamic>>[
        _form(
          formId: 81,
          formName: 'Inspection Checklist',
          displayInMobile: 'Yes',
          parentId: 8,
          parentName: 'Quality Inspections',
        ),
      ],
    ),
    _form(
      formId: 9,
      formName: 'Land Acquisition',
      webFormUrl: 'land-acquisition',
      priority: 9,
      formsSubMenu: <Map<String, dynamic>>[
        _form(
          formId: 91,
          formName: 'Land Acquisition process',
          displayInMobile: 'No',
          parentId: 9,
          parentName: 'Land Acquisition',
        ),
        _form(
          formId: 92,
          formName: 'Add Land Details',
          displayInMobile: 'No',
          parentId: 9,
          parentName: 'Land Acquisition',
        ),
      ],
    ),
    _form(
      formId: 10,
      formName: 'Closed Update',
      priority: 0,
      statusId: 'Inactive',
      displayInMobile: 'Yes',
    ),
    _form(
      formId: 11,
      formName: 'Blank Mobile',
      priority: 0,
      displayInMobile: null,
    ),
  ];
}

Map<String, dynamic> _form({
  required int formId,
  required String formName,
  String webFormUrl = '',
  String mobileFormUrl = '',
  Object? priority,
  String statusId = 'Active',
  Object? displayInMobile = 'Yes',
  int? parentId,
  String? parentName,
  Object? formsSubMenu,
  Object? formsSubMenuLevel2,
}) {
  return <String, dynamic>{
    'formId': formId,
    'formName': formName,
    'webFormUrl': webFormUrl,
    'mobileFormUrl': mobileFormUrl,
    'priority': priority,
    'statusId': statusId,
    'parentId': parentId,
    'parentName': parentName,
    'displayInMobile': displayInMobile,
    'formsSubMenu': formsSubMenu,
    'formsSubMenuLevel2': formsSubMenuLevel2,
  };
}
