import 'package:swr_pmis_mobile/src/core/forms/form_menu_tree.dart';
import 'package:swr_pmis_mobile/src/core/navigation/module_catalog.dart';

String? updateFormRouteName(FormMenuNode node) {
  final String url = _segment(node.webFormUrl);
  final String compactUrl = _compact(url);
  final String name = node.formName.trim().toLowerCase();
  for (final AppModule module in ModuleCatalog.routable) {
    final String id = module.id.trim().toLowerCase();
    final String path = _segment(module.routePath);
    if (url.isNotEmpty &&
        (url == id ||
            url == path ||
            compactUrl == _compact(id) ||
            compactUrl == _compact(path))) {
      return module.routeName;
    }
    if (name.isNotEmpty && name == module.title.trim().toLowerCase()) {
      return module.routeName;
    }
  }
  return null;
}

String _segment(String value) {
  final String trimmed = value.trim().toLowerCase();
  if (trimmed.isEmpty) {
    return '';
  }
  final List<String> parts = trimmed
      .split('/')
      .where((String part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return '';
  }
  return parts.last;
}

String _compact(String value) {
  return value.replaceAll(RegExp(r'[-_\s]'), '');
}
