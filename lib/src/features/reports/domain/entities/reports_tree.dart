import 'package:swr_pmis_mobile/src/core/forms/form_menu_tree.dart';

class ReportFormNode {
  const ReportFormNode({
    required this.formId,
    required this.formName,
    required this.webFormUrl,
    required this.mobileFormUrl,
    required this.priority,
    required this.children,
  });

  factory ReportFormNode.fromMenu(FormMenuNode node) {
    return ReportFormNode(
      formId: node.formId,
      formName: node.formName,
      webFormUrl: node.webFormUrl,
      mobileFormUrl: node.mobileFormUrl,
      priority: node.priority,
      children: node.children
          .map(ReportFormNode.fromMenu)
          .toList(growable: false),
    );
  }

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
    return ReportsTree(
      forms: parseFormMenu(
        items,
      ).map(ReportFormNode.fromMenu).toList(growable: false),
    );
  }
}
