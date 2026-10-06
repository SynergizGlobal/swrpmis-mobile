import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/reports_tree.dart';

void main() {
  test('report forms keep active mobile rows and sort the tree', () {
    final ReportsTree tree = ReportsTree.fromApi(_sampleForms());

    expect(tree.forms.map((ReportFormNode node) => node.formName), <String>[
      'Progress Report',
      'Issues',
      'Contracts',
      'Contract-wise Activities',
      'Land Acquisition',
      'Utility Shifting',
    ]);
    expect(tree.forms.map((ReportFormNode node) => node.isExpandable), <bool>[
      true,
      true,
      true,
      false,
      false,
      false,
    ]);

    final ReportFormNode progress = tree.forms[0];
    expect(progress.formId, '275');
    expect(
      progress.children.map((ReportFormNode node) => node.formName),
      <String>['FOB'],
    );
    expect(progress.children.single.isExpandable, isFalse);

    final ReportFormNode issues = tree.forms[1];
    expect(
      issues.children.map((ReportFormNode node) => node.formName),
      <String>[
        'Pending Issues Report',
        'Issue Details Report',
        'Issues Summary Report',
      ],
    );

    final ReportFormNode contracts = tree.forms[2];
    expect(contracts.formId, '281');
    expect(
      contracts.children.map((ReportFormNode node) => node.formName),
      <String>[
        'Date of Completion Letters',
        'BG Contractual Letters',
        'BG/Insurance Report',
        'Contract Detail',
        'List of Contracts',
        'Date of Completion Report',
        'Insurance Contractual Letters',
        'List of Contractors',
      ],
    );
    final ReportFormNode detail = contracts.children[3];
    expect(detail.isExpandable, isTrue);
    expect(
      detail.children.map((ReportFormNode node) => node.formName),
      <String>['Annex A', 'Letter Copy'],
    );
    expect(
      contracts.children.where((ReportFormNode node) => node.isExpandable),
      hasLength(1),
    );

    final ReportFormNode activities = tree.forms[3];
    expect(activities.formId, '1319');
    expect(activities.webFormUrl, 'activities-export-report');
    expect(activities.mobileFormUrl, 'activities-mobile');
    expect(activities.children, isEmpty);

    final ReportFormNode land = tree.forms[4];
    expect(land.formId, '1316');
    expect(land.webFormUrl, 'la-report');
    expect(land.children, isEmpty);

    final ReportFormNode utility = tree.forms[5];
    expect(utility.formId, '1317');
    expect(utility.isExpandable, isFalse);

    final Set<String> names = _names(tree.forms);
    expect(names, isNot(contains('New Line')));
    expect(names, isNot(contains('Network Expansion Works')));
    expect(names, isNot(contains('Utility Report')));
    expect(names, isNot(contains('Old Contracts')));
    expect(names, isNot(contains('Should Stay Hidden')));
    expect(names, isNot(contains('Hidden Copy')));
    expect(names, isNot(contains('Old Annex')));
  });
}

Set<String> _names(List<ReportFormNode> nodes) {
  final Set<String> names = <String>{};
  for (final ReportFormNode node in nodes) {
    names.add(node.formName);
    names.addAll(_names(node.children));
  }
  return names;
}

List<Map<String, dynamic>> _sampleForms() {
  return <Map<String, dynamic>>[
    _form(
      formId: 1317,
      formName: 'Utility Shifting',
      displayInMobile: 'Yes',
      formsSubMenu: <Map<String, dynamic>>[
        _form(
          formId: 1401,
          formName: 'Utility Report',
          displayInMobile: 'No',
          parentId: 1317,
          parentName: 'Utility Shifting',
        ),
      ],
    ),
    _form(
      formId: 900,
      formName: 'Old Contracts',
      priority: 1,
      statusId: 'Inactive',
      displayInMobile: 'Yes',
    ),
    _form(
      formId: 901,
      formName: 'Internal Only',
      priority: 1,
      displayInMobile: 'No',
      formsSubMenu: <Map<String, dynamic>>[
        _form(
          formId: 902,
          formName: 'Should Stay Hidden',
          displayInMobile: 'Yes',
          parentId: 901,
          parentName: 'Internal Only',
        ),
      ],
    ),
    _form(
      formId: 1316,
      formName: 'Land Acquisition',
      webFormUrl: 'la-report',
      formsSubMenu: null,
    ),
    _form(
      formId: 281,
      formName: 'Contracts',
      priority: 20,
      formsSubMenu: <Map<String, dynamic>>[
        _form(
          formId: 288,
          formName: 'List of Contractors',
          parentId: 281,
          parentName: 'Contracts',
          formsSubMenuLevel2: <Map<String, dynamic>>[],
        ),
        _form(
          formId: 282,
          formName: 'Contract Detail',
          priority: 3,
          parentId: 281,
          parentName: 'Contracts',
          formsSubMenuLevel2: <Map<String, dynamic>>[
            _form(
              formId: 501,
              formName: 'Hidden Copy',
              priority: 1,
              displayInMobile: 'No',
            ),
            _form(
              formId: 502,
              formName: 'Old Annex',
              priority: 0,
              statusId: 'Inactive',
              displayInMobile: 'Yes',
            ),
            _form(formId: 503, formName: 'Letter Copy', priority: 2),
            _form(formId: 504, formName: 'Annex A', priority: 1),
          ],
        ),
        _form(
          formId: 286,
          formName: 'Date of Completion Report',
          parentId: 281,
          parentName: 'Contracts',
        ),
        _form(
          formId: 284,
          formName: 'BG/Insurance Report',
          priority: 3,
          parentId: 281,
          parentName: 'Contracts',
        ),
        _form(
          formId: 289,
          formName: 'Insurance Contractual Letters',
          parentId: 281,
          parentName: 'Contracts',
        ),
        _form(
          formId: 285,
          formName: 'List of Contracts',
          priority: '4',
          parentId: 281,
          parentName: 'Contracts',
        ),
        _form(
          formId: 287,
          formName: 'BG Contractual Letters',
          priority: 2,
          parentId: 281,
          parentName: 'Contracts',
        ),
        _form(
          formId: 283,
          formName: 'Date of Completion Letters',
          priority: 1,
          parentId: 281,
          parentName: 'Contracts',
        ),
      ],
    ),
    _form(
      formId: 1319,
      formName: 'Contract-wise Activities',
      webFormUrl: 'activities-export-report',
      mobileFormUrl: 'activities-mobile',
      priority: 30,
      formsSubMenu: <Map<String, dynamic>>[],
    ),
    _form(
      formId: 278,
      formName: 'Issues',
      priority: 10,
      formsSubMenu: <Map<String, dynamic>>[
        _form(
          formId: 292,
          formName: 'Issues Summary Report',
          parentId: 278,
          parentName: 'Issues',
        ),
        _form(
          formId: 291,
          formName: 'Issue Details Report',
          priority: 2,
          parentId: 278,
          parentName: 'Issues',
        ),
        _form(
          formId: 290,
          formName: 'Pending Issues Report',
          priority: 1,
          parentId: 278,
          parentName: 'Issues',
        ),
      ],
    ),
    _form(
      formId: 275,
      formName: 'Progress Report',
      priority: '5',
      statusId: 'ACTIVE',
      displayInMobile: 'YES',
      formsSubMenu: <Map<String, dynamic>>[
        _form(
          formId: 277,
          formName: 'Network Expansion Works',
          priority: 1,
          displayInMobile: 'No',
          parentId: 275,
          parentName: 'Progress Report',
        ),
        _form(
          formId: 276,
          formName: 'New Line',
          priority: 2,
          displayInMobile: 'no',
          parentId: 275,
          parentName: 'Progress Report',
        ),
        _form(
          formId: 274,
          formName: 'FOB',
          priority: 5,
          displayInMobile: 'yes',
          parentId: 275,
          parentName: 'Progress Report',
          webFormUrl: 'fob-report',
        ),
      ],
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
  String displayInMobile = 'Yes',
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
