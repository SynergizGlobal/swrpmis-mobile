/// Compares semantic versions `major.minor.patch` (optional build suffix ignored).
class AppVersionUtils {
  const AppVersionUtils._();

  static List<int> parse(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const <int>[0, 0, 0];
    }
    final String core = trimmed.split('+').first.split('-').first;
    final List<String> parts = core.split('.');
    final List<int> values = <int>[
      for (int i = 0; i < 3; i++)
        i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0,
    ];
    return values;
  }

  /// Returns `true` when [current] is strictly older than [target].
  static bool isOlderThan(String current, String target) {
    final List<int> a = parse(current);
    final List<int> b = parse(target);
    for (int i = 0; i < 3; i++) {
      if (a[i] < b[i]) {
        return true;
      }
      if (a[i] > b[i]) {
        return false;
      }
    }
    return false;
  }
}
