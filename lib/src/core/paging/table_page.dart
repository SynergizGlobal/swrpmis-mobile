class TablePage<T> {
  const TablePage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.start,
    required this.end,
    required this.pageCount,
  });

  static const List<int> pageSizes = <int>[5, 8, 10, 20, 50];
  static const int defaultPageSize = 10;
  static const int compactDefaultPageSize = 5;

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;
  final int start;
  final int end;
  final int pageCount;

  String get label {
    if (total == 0) {
      return 'Showing 0 to 0 of 0 entries';
    }
    return 'Showing ${start + 1} to $end of $total entries';
  }

  int serial(int indexOnPage) => start + indexOnPage + 1;

  static TablePage<T> slice<T>(
    List<T> filtered, {
    required int page,
    required int pageSize,
  }) {
    final int size = pageSize < 1 ? defaultPageSize : pageSize;
    final int total = filtered.length;
    final int pageCount = total == 0 ? 1 : (total / size).ceil();
    int current = page < 1 ? 1 : page;
    if (current > pageCount) {
      current = pageCount;
    }
    final int start = total == 0 ? 0 : (current - 1) * size;
    final int end = total == 0 ? 0 : (start + size).clamp(0, total);
    return TablePage<T>(
      items: total == 0
          ? List<T>.empty(growable: false)
          : filtered.sublist(start, end),
      page: current,
      pageSize: size,
      total: total,
      start: start,
      end: end,
      pageCount: pageCount,
    );
  }
}

List<int?> pageNumberWindow({
  required int current,
  required int pageCount,
  required bool compact,
}) {
  final int pages = pageCount < 1 ? 1 : pageCount;
  final int safe = current.clamp(1, pages);
  final int maxSlots = compact ? 5 : 7;
  if (pages <= maxSlots) {
    return <int?>[for (int index = 1; index <= pages; index++) index];
  }
  final Set<int> keep = <int>{1, pages, safe};
  if (safe - 1 > 1) {
    keep.add(safe - 1);
  }
  if (safe + 1 < pages) {
    keep.add(safe + 1);
  }
  final List<int> sorted = keep.toList()..sort();
  final List<int?> tokens = <int?>[];
  for (int index = 0; index < sorted.length; index++) {
    if (index > 0 && sorted[index] - sorted[index - 1] > 1) {
      tokens.add(null);
    }
    tokens.add(sorted[index]);
  }
  return tokens;
}
