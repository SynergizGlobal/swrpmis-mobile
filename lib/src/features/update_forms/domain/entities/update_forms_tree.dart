import 'package:swr_pmis_mobile/src/core/forms/form_menu_tree.dart';
import 'package:swr_pmis_mobile/src/features/update_forms/domain/update_forms_visibility.dart';

class UpdateFormsTree {
  const UpdateFormsTree({required this.forms});

  final List<FormMenuNode> forms;

  bool get isEmpty => forms.isEmpty;

  factory UpdateFormsTree.fromApi(List<Map<String, dynamic>> items) {
    return UpdateFormsTree(
      forms: filterHiddenUpdateForms(parseFormMenu(items)),
    );
  }
}
