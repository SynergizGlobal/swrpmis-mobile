import 'package:swr_pmis_mobile/src/core/forms/form_menu_tree.dart';
import 'package:swr_pmis_mobile/src/core/navigation/module_catalog.dart';

const Map<String, String> _updateFormAliases = <String, String>{
  'qualitytestregister': 'forms-quality-test-register',
  'testregister': 'forms-quality-test-register',
  'testobligations': 'forms-quality-test-register',
  'ncrobservations': 'forms-quality-ncr-observations',
  'ncrobservation': 'forms-quality-ncr-observations',
};

String? updateFormRouteName(FormMenuNode node) {
  final String url = _segment(node.webFormUrl);
  final String compactUrl = _compact(url);
  final String mobileUrl = _segment(node.mobileFormUrl);
  final String compactMobileUrl = _compact(mobileUrl);
  final String name = node.formName.trim().toLowerCase();
  final String compactName = _compact(name);

  for (final String key in <String>[
    compactUrl,
    url,
    compactMobileUrl,
    mobileUrl,
    compactName,
    name,
  ]) {
    if (key.isEmpty) {
      continue;
    }
    final String? aliased = _updateFormAliases[key];
    if (aliased != null) {
      return aliased;
    }
  }

  for (final AppModule module in ModuleCatalog.routable) {
    final String id = module.id.trim().toLowerCase();
    final String path = _segment(module.routePath);
    final String compactId = _compact(id);
    final String compactPath = _compact(path);
    if (_urlMatchesModule(
      url: url,
      compactUrl: compactUrl,
      id: id,
      path: path,
      compactId: compactId,
      compactPath: compactPath,
    )) {
      return module.routeName;
    }
    if (_urlMatchesModule(
      url: mobileUrl,
      compactUrl: compactMobileUrl,
      id: id,
      path: path,
      compactId: compactId,
      compactPath: compactPath,
    )) {
      return module.routeName;
    }
    if (name.isNotEmpty && name == module.title.trim().toLowerCase()) {
      return module.routeName;
    }
  }
  return null;
}

bool _urlMatchesModule({
  required String url,
  required String compactUrl,
  required String id,
  required String path,
  required String compactId,
  required String compactPath,
}) {
  if (url.isEmpty && compactUrl.isEmpty) {
    return false;
  }
  return (url.isNotEmpty && (url == id || url == path)) ||
      (compactUrl.isNotEmpty &&
          (compactUrl == compactId || compactUrl == compactPath));
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
