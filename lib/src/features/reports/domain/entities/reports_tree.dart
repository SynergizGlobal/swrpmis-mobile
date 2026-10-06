class ReportFormNode {
  const ReportFormNode({
    required this.formId,
    required this.formName,
    required this.webFormUrl,
    required this.mobileFormUrl,
    required this.priority,
    required this.children,
  });

  final String formId;
  final String formName;
  final String webFormUrl;
  final String mobileFormUrl;
  final num? priority;
  final List<ReportFormNode> children;

  bool get isExpandable => children.isNotEmpty;
}

class ReportsTree {
  const ReportsTree({required this.forms});

  final List<ReportFormNode> forms;

  bool get isEmpty => forms.isEmpty;

  factory ReportsTree.fromApi(List<Map<String, dynamic>> items) {
    final List<ReportFormNode> forms = <ReportFormNode>[];
    for (final Map<String, dynamic> item in items) {
      final ReportFormNode? node = _visibleParent(item);
      if (node != null) {
        forms.add(node);
      }
    }
    forms.sort(_compareNodes);
    return ReportsTree(forms: forms);
  }
}

ReportFormNode? _visibleParent(Map<String, dynamic> json) {
  if (!_isListed(json)) {
    return null;
  }
  return _node(json, _childrenFromSubMenu(json));
}

List<ReportFormNode> _childrenFromSubMenu(Map<String, dynamic> json) {
  final List<ReportFormNode> children = <ReportFormNode>[];
  for (final Map<String, dynamic> child in _maps(json['formsSubMenu'])) {
    final ReportFormNode? node = _visibleChild(child);
    if (node != null) {
      children.add(node);
    }
  }
  children.sort(_compareNodes);
  return children;
}

ReportFormNode? _visibleChild(Map<String, dynamic> json) {
  if (!_isListed(json)) {
    return null;
  }
  final List<ReportFormNode> nested = <ReportFormNode>[];
  for (final Map<String, dynamic> item in _maps(json['formsSubMenuLevel2'])) {
    if (!_isListed(item)) {
      continue;
    }
    nested.add(_node(item, const <ReportFormNode>[]));
  }
  nested.sort(_compareNodes);
  return _node(json, nested);
}

ReportFormNode _node(Map<String, dynamic> json, List<ReportFormNode> children) {
  return ReportFormNode(
    formId: _id(json['formId']),
    formName: _text(json['formName']),
    webFormUrl: _text(json['webFormUrl']),
    mobileFormUrl: _text(json['mobileFormUrl']),
    priority: _priority(json['priority']),
    children: children,
  );
}

bool _isListed(Map<String, dynamic> json) {
  return _text(json['statusId']).toLowerCase() == 'active' &&
      _displayYes(json['displayInMobile']);
}

bool _displayYes(Object? value) {
  if (value is bool) {
    return value;
  }
  return _text(value).toLowerCase() == 'yes';
}

int _compareNodes(ReportFormNode a, ReportFormNode b) {
  final num? left = a.priority;
  final num? right = b.priority;
  if (left == null && right != null) {
    return 1;
  }
  if (left != null && right == null) {
    return -1;
  }
  if (left != null && right != null) {
    final int byPriority = left.compareTo(right);
    if (byPriority != 0) {
      return byPriority;
    }
  }
  final int byName = a.formName.toLowerCase().compareTo(
    b.formName.toLowerCase(),
  );
  if (byName != 0) {
    return byName;
  }
  return a.formName.compareTo(b.formName);
}

List<Map<String, dynamic>> _maps(Object? value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  return value
      .whereType<Map>()
      .map((Map item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

String _text(Object? value) {
  if (value == null) {
    return '';
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return '';
  }
  return text;
}

String _id(Object? value) {
  final String text = _text(value);
  final num? number = num.tryParse(text);
  if (number != null && number == number.roundToDouble()) {
    return number.toInt().toString();
  }
  return text;
}

num? _priority(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    if (value.isNaN) {
      return null;
    }
    return value;
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return num.tryParse(text);
}
