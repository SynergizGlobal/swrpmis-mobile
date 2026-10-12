import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/paging/table_page.dart';

void main() {
  test('page 2 of 12 rows at size 5 shows items 6 to 10', () {
    final TablePage<int> page = TablePage.slice(
      List<int>.generate(12, (int index) => index + 1),
      page: 2,
      pageSize: 5,
    );

    expect(page.items, <int>[6, 7, 8, 9, 10]);
    expect(page.label, 'Showing 6 to 10 of 12 entries');
  });

  test('page size 50 on 3 rows shows the full short list', () {
    final TablePage<int> page = TablePage.slice(
      const <int>[1, 2, 3],
      page: 1,
      pageSize: 50,
    );

    expect(page.items, <int>[1, 2, 3]);
    expect(page.label, 'Showing 1 to 3 of 3 entries');
  });

  test('an empty list says 0 to 0 of 0', () {
    final TablePage<int> page = TablePage.slice(
      const <int>[],
      page: 1,
      pageSize: TablePage.defaultPageSize,
    );

    expect(page.items, isEmpty);
    expect(page.label, 'Showing 0 to 0 of 0 entries');
  });
}
