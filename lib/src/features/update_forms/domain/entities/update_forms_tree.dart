import 'package:swr_pmis_mobile/src/core/forms/form_menu_tree.dart';

class UpdateFormsTree {
  const UpdateFormsTree({required this.forms});

  final List<FormMenuNode> forms;

  bool get isEmpty => forms.isEmpty;

  factory UpdateFormsTree.fromApi(List<Map<String, dynamic>> items) {
    return UpdateFormsTree(forms: parseFormMenu(items));
  }
}
