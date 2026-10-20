import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_list.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_parse.dart';

void main() {
  test('subheads parse id categoryId name sourceUrl', () {
    final List<RdsoSubhead> subheads = parseRdsoSubheads(<dynamic>[
      <String, dynamic>{
        'id': 7,
        'categoryId': 3,
        'name': 'Bridge Deck',
        'sourceUrl': 'https://example.com/deck',
      },
    ], categoryId: '3');

    expect(subheads, hasLength(1));
    expect(subheads.single.id, '7');
    expect(subheads.single.categoryId, '3');
    expect(subheads.single.name, 'Bridge Deck');
  });

  test('drawing list parses register-shaped rows', () {
    final List<RdsoDrawingRow> rows = parseRdsoDrawingList(<dynamic>[
      <String, dynamic>{
        'id': 'd1',
        'drawingKey': 'RDSO-X-1',
        'description': 'Detail A',
        'status': 'Current',
      },
    ]);
    expect(rows, hasLength(1));
    expect(rows.single.drawingKey, 'RDSO-X-1');
    expect(rows.single.title, 'Detail A');
  });

  test('files posts and crawl runs parse', () {
    final List<RdsoDrawingFile> files = parseRdsoDrawingFiles(<dynamic>[
      <String, dynamic>{
        'id': 'f1',
        'fileName': 'sheet.pdf',
        'fileType': 'PDF',
        'fileSize': 1024,
        'status': 'Current',
      },
    ]);
    expect(files.single.name, 'sheet.pdf');
    expect(files.single.type, 'PDF');

    final List<RdsoPost> posts = parseRdsoPosts(<dynamic>[
      <String, dynamic>{
        'id': 'p1',
        'drawingId': 'd1',
        'postType': 'feedback',
        'content': 'Looks good',
        'authorName': 'User A',
        'createdAt': '2024-01-01',
      },
    ]);
    expect(posts.single.isFeedback, isTrue);
    expect(posts.single.author, 'User A');

    final List<RdsoCrawlRun> runs = parseRdsoCrawlRuns(<dynamic>[
      <String, dynamic>{
        'id': 'run-1',
        'status': 'RUNNING',
        'phase': 'categories',
        'drawingsCount': 10,
        'logTail': 'tail line',
      },
    ]);
    expect(runs.single.isRunning, isTrue);
    expect(runs.single.drawingsCount, 10);
  });

  test('crawl logs and api message helpers', () {
    expect(parseRdsoCrawlLogs('line1\nline2'), 'line1\nline2');
    expect(
      parseRdsoCrawlLogs(<String>['a', 'b']),
      'a\nb',
    );
    expect(
      rdsoApiMessage(<String, dynamic>{'message': 'already active'}),
      'already active',
    );
  });

  test('library query params exclude cache bust', () {
    const RdsoLibraryQuery query = RdsoLibraryQuery(
      q: 'bridge',
      categoryId: '11',
      status: 'Current',
      page: 2,
    );
    final Map<String, dynamic> params = query.queryParameters();
    expect(params.containsKey('_t'), isFalse);
    expect(params['q'], 'bridge');
    expect(params['categoryId'], '11');
    expect(params['status'], 'Current');
    expect(params['page'], 1);
  });

  test('rdso library api path helpers', () {
    expect(
      ApiConstants.rdsoCategorySubheadsPath('c1'),
      '/api/rdso/categories/c1/subheads',
    );
    expect(
      ApiConstants.rdsoSubheadDrawingsPath('s1'),
      '/api/rdso/subheads/s1/drawings',
    );
    expect(
      ApiConstants.rdsoDrawingFilesPath('d1'),
      '/api/rdso/drawings/d1/files',
    );
    expect(
      ApiConstants.rdsoFileSendMailPath('f1'),
      '/api/rdso/files/f1/send-mail',
    );
    expect(ApiConstants.rdsoCrawlStartPath, '/api/rdso/admin/crawl');
  });
}
