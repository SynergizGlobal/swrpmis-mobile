import 'package:swr_pmis_mobile/src/core/forms/form_menu_tree.dart';

const Set<String> _hiddenQualityInspectionKeys = <String>{
  'qualitytestmaster',
  'structurereferencemaster',
  'testgenerationsimulator',
  'qualityobligations',
  'qualityobligation',
  'qualityobservation',
  'qualityobservations',
};

List<FormMenuNode> filterHiddenUpdateForms(List<FormMenuNode> forms) {
  return <FormMenuNode>[
    for (final FormMenuNode node in forms) _filterNode(node),
  ];
}

FormMenuNode _filterNode(FormMenuNode node) {
  if (!_isQualityInspectionsGroup(node)) {
    return node;
  }
  final List<FormMenuNode> children = <FormMenuNode>[
    for (final FormMenuNode child in node.children)
      if (!_isHiddenQualityInspectionLeaf(child))
        FormMenuNode(
          formId: child.formId,
          formName: child.formName,
          webFormUrl: child.webFormUrl,
          mobileFormUrl: child.mobileFormUrl,
          priority: child.priority,
          children: <FormMenuNode>[
            for (final FormMenuNode nested in child.children)
              if (!_isHiddenQualityInspectionLeaf(nested)) nested,
          ],
        ),
  ];
  return FormMenuNode(
    formId: node.formId,
    formName: node.formName,
    webFormUrl: node.webFormUrl,
    mobileFormUrl: node.mobileFormUrl,
    priority: node.priority,
    children: children,
  );
}

bool _isQualityInspectionsGroup(FormMenuNode node) {
  final String name = node.formName.trim().toLowerCase();
  final String compactName = _compact(name);
  final String compactUrl = _compact(node.webFormUrl);
  return name == 'quality inspections' ||
      compactName == 'qualityinspections' ||
      compactUrl == 'quality' ||
      compactUrl == 'qualityinspections';
}

bool _isHiddenQualityInspectionLeaf(FormMenuNode node) {
  for (final String key in <String>[
    _compact(node.webFormUrl),
    _compact(node.mobileFormUrl),
    _compact(node.formName),
  ]) {
    if (key.isNotEmpty && _hiddenQualityInspectionKeys.contains(key)) {
      return true;
    }
  }
  return false;
}

String _compact(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[-_\s/]'), '');
}
