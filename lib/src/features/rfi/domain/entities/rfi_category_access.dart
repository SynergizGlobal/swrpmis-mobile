/// Server-side access for one RFI category, as the web list page reads it
/// from `/rfi/api/category-view-only` and `/rfi/api/can-create`.
class RfiCategoryAccess {
  const RfiCategoryAccess({required this.viewOnly, required this.canCreate});

  /// True when the user may only view the list: no Add, Edit or Delete.
  final bool viewOnly;

  /// True when the user may raise a new RFI in this category.
  final bool canCreate;

  bool get canAdd => canCreate && !viewOnly;

  bool get canModify => !viewOnly;
}

/// Reads `{"viewOnly": false}`. Anything unreadable counts as view-only so a
/// broken response never exposes Edit/Delete.
bool parseRfiViewOnly(dynamic data) {
  final Object? value = _field(data, 'viewOnly');
  return value == null ? true : rfiAccessFlag(value);
}

/// Reads `{"rfiCategory": "WORK", "canCreate": true}`. Anything unreadable
/// counts as not allowed.
bool parseRfiCanCreate(dynamic data) {
  final Object? value = _field(data, 'canCreate');
  return value != null && rfiAccessFlag(value);
}

bool rfiAccessFlag(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final String text = value.trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }
  return false;
}

Object? _field(dynamic data, String key) {
  if (data is bool) {
    return data;
  }
  if (data is! Map) {
    return null;
  }
  if (data.containsKey(key)) {
    return data[key];
  }
  for (final String wrapper in const <String>['data', 'result', 'content']) {
    final Object? nested = data[wrapper];
    if (nested is Map && nested.containsKey(key)) {
      return nested[key];
    }
  }
  return null;
}
