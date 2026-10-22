import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_list.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_parse.dart';

void main() {
  test('subheads parse wrapped subheads array', () {
    final List<RdsoSubhead> subheads = parseRdsoSubheads(<String, dynamic>{
      'subheads': <dynamic>[
        <String, dynamic>{
          'id': 71,
          'categoryId': 4,
          'name': '3*60 ft BGML loading (Suitable for MBG)',
        },
      ],
    }, categoryId: '4');

    expect(subheads, hasLength(1));
    expect(subheads.single.id, '71');
    expect(subheads.single.name, contains('BGML'));
  });

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

  test('drawing search parses bare array with null optional fields', () {
    final List<RdsoDrawingRow> rows = parseRdsoDrawingList(<dynamic>[
      <String, dynamic>{
        'id': 931,
        'subheadId': 71,
        'subheadName': '3*60 ft BGML loading (Suitable for MBG)',
        'drawingKey': 'BA-1744',
        'name': 'BA-1744',
        'description': 'Details of bearing',
        'sourceUrl':
            'http://203.153.40.44:90/drawing/frmDrawingView.aspx?h=842',
        'fileSize': null,
        'fileId': null,
        'status': null,
      },
    ]);

    expect(rows, hasLength(1));
    expect(rows.single.id, '931');
    expect(rows.single.drawingKey, 'BA-1744');
    expect(rows.single.title, 'Details of bearing');
    expect(rows.single.fileSize, isNull);
    expect(rows.single.fileId, isNull);
    expect(rows.single.status, isEmpty);
    expect(formatRdsoFileSize(rows.single.fileSize), '—');
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

    expect(
      const RdsoCrawlRun(id: 'r', status: 'in_progress', phase: '').isRunning,
      isTrue,
    );
    expect(
      const RdsoCrawlRun(id: 'r', status: 'IN_PROGRESS', phase: '').isRunning,
      isTrue,
    );
    expect(
      const RdsoCrawlRun(id: 'r', status: 'completed', phase: '').isRunning,
      isFalse,
    );
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

  test('drawing status filter matches Current and Archived', () {
    const RdsoDrawingRow current = RdsoDrawingRow(
      id: '1',
      subheadId: '',
      subheadName: '',
      drawingKey: 'A',
      name: 'A',
      description: '',
      sourceUrl: '',
      fileSize: null,
      fileId: null,
      status: 'Current',
      department: '',
      revision: '',
      revisionDate: '',
    );
    const RdsoDrawingRow archived = RdsoDrawingRow(
      id: '2',
      subheadId: '',
      subheadName: '',
      drawingKey: 'B',
      name: 'B',
      description: '',
      sourceUrl: '',
      fileSize: null,
      fileId: null,
      status: 'Archived',
      department: '',
      revision: '',
      revisionDate: '',
    );
    const RdsoDrawingRow emptyStatus = RdsoDrawingRow(
      id: '3',
      subheadId: '',
      subheadName: '',
      drawingKey: 'C',
      name: 'C',
      description: '',
      sourceUrl: '',
      fileSize: null,
      fileId: null,
      status: '',
      department: '',
      revision: '',
      revisionDate: '',
    );

    expect(rdsoDrawingMatchesStatus(current.status, 'Current'), isTrue);
    expect(rdsoDrawingMatchesStatus(archived.status, 'current'), isFalse);
    expect(rdsoDrawingMatchesStatus(archived.status, 'Archived'), isTrue);
    expect(rdsoDrawingMatchesStatus(emptyStatus.status, 'Current'), isFalse);
    expect(rdsoDrawingMatchesStatus(current.status, ''), isTrue);

    final List<RdsoDrawingRow> filtered = filterRdsoDrawingsByStatus(
      <RdsoDrawingRow>[current, archived, emptyStatus],
      'Current',
    );
    expect(filtered, <RdsoDrawingRow>[current]);
    expect(
      filterRdsoDrawingsByStatus(
        <RdsoDrawingRow>[current, archived],
        '',
      ),
      <RdsoDrawingRow>[current, archived],
    );

    final List<RdsoDrawingRow> many = List<RdsoDrawingRow>.generate(
      10,
      (int i) => RdsoDrawingRow(
        id: '$i',
        subheadId: '',
        subheadName: '',
        drawingKey: 'K$i',
        name: 'N$i',
        description: '',
        sourceUrl: '',
        fileSize: null,
        fileId: null,
        status: 'Current',
        department: '',
        revision: '',
        revisionDate: '',
      ),
    );
    expect(
      paginateRdsoDrawings(many, page: 1, size: 8),
      many.sublist(0, 8),
    );
    expect(
      paginateRdsoDrawings(many, page: 2, size: 8),
      many.sublist(8, 10),
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

  test('drawing search query sends q only', () {
    const RdsoLibraryQuery query = RdsoLibraryQuery(
      q: 'BA-1744',
      categoryId: '11',
      status: 'Current',
      page: 3,
    );
    final Map<String, dynamic> params = query.drawingSearchQueryParameters();
    expect(params, <String, dynamic>{'q': 'BA-1744'});
    expect(query.usesDrawingSearchEndpoint, isTrue);
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
    expect(
      ApiConstants.rdsoDrawingsSearchPath,
      '/api/rdso/drawings/search',
    );
    expect(ApiConstants.rdsoCrawlStartPath, '/api/rdso/admin/crawl');
    expect(
      ApiConstants.rdsoCrawlRunCancelPath('run-42'),
      '/api/rdso/admin/crawl/runs/run-42/cancel',
    );
  });
}
