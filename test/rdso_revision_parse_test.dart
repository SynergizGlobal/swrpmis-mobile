import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_list.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_parse.dart';

void main() {
  test('categories parse id name sourceUrl', () {
    final List<RdsoCategory> categories = parseRdsoCategories(<dynamic>[
      <String, dynamic>{
        'id': 11,
        'name': 'Abutments',
        'sourceUrl': 'https://example.com/abutments',
      },
      <String, dynamic>{'id': null, 'name': null},
    ]);

    expect(categories, hasLength(1));
    expect(categories.single.id, '11');
    expect(categories.single.name, 'Abutments');
    expect(categories.single.sourceUrl, 'https://example.com/abutments');
  });

  test('register list parses items totals and summary counts', () {
    final RdsoRevisionSnapshot snapshot = parseRdsoRegister(<String, dynamic>{
      'items': <dynamic>[
        <String, dynamic>{
          'id': 101,
          'subheadId': 5,
          'subheadName': 'Bridge',
          'drawingKey': 'RDSO-B-001',
          'name': 'Abutment detail',
          'description': 'Abutment Type A',
          'sourceUrl': 'https://example.com/d1',
          'fileSize': 1572864,
          'fileId': 'file-9',
          'status': 'Current',
          'department': 'Bridges',
          'revision': 'R2',
          'revisionDate': '15/03/2024',
        },
        <String, dynamic>{
          'id': 102,
          'drawingKey': 'RDSO-B-002',
          'name': 'Only name',
          'description': null,
          'fileSize': null,
          'fileId': null,
          'status': 'Archived',
        },
        <String, dynamic>{'id': null, 'drawingKey': null},
      ],
      'total': 42,
      'page': 0,
      'size': 8,
      'currentFiles': 120,
      'archivedFiles': 35,
    });

    expect(snapshot.total, 42);
    expect(snapshot.page, 0);
    expect(snapshot.size, 8);
    expect(snapshot.currentFiles, 120);
    expect(snapshot.archivedFiles, 35);
    expect(snapshot.items, hasLength(2));

    final RdsoDrawingRow first = snapshot.items.first;
    expect(first.drawingKey, 'RDSO-B-001');
    expect(first.title, 'Abutment Type A');
    expect(first.department, 'Bridges');
    expect(first.revision, 'R2');
    expect(first.revisionDate, '15/03/2024');
    expect(first.fileSize, 1572864);
    expect(first.fileId, 'file-9');
    expect(first.hasFile, isTrue);

    final RdsoDrawingRow second = snapshot.items.last;
    expect(second.title, 'Only name');
    expect(second.hasFile, isFalse);
    expect(second.fileId, isNull);
  });

  test('query params match web register filters', () {
    const RdsoRevisionQuery query = RdsoRevisionQuery(
      q: 'abutment',
      categoryId: '11',
      status: 'Current',
      date: '2024-03-15',
      page: 2,
      size: 8,
    );
    expect(query.apiPage, 1);
    expect(query.queryParameters(), <String, dynamic>{
      'page': 1,
      'size': 8,
      'q': 'abutment',
      'categoryId': '11',
      'status': 'Current',
      'date': '2024-03-15',
    });

    const RdsoRevisionQuery empty = RdsoRevisionQuery();
    expect(empty.queryParameters(), <String, dynamic>{'page': 0, 'size': 8});
  });

  test('file size formatting matches web thresholds', () {
    expect(formatRdsoFileSize(null), '—');
    expect(formatRdsoFileSize(-1), '—');
    expect(formatRdsoFileSize(500), '500 B');
    expect(formatRdsoFileSize(2048), '2.0 KB');
    expect(formatRdsoFileSize(1572864), '1.50 MB');
  });

  test('rdso api path helpers', () {
    expect(ApiConstants.rdsoCategoriesPath, '/api/rdso/categories');
    expect(
      ApiConstants.rdsoDrawingsRegisterPath,
      '/api/rdso/drawings/register',
    );
    expect(ApiConstants.rdsoFileViewPath('abc'), '/api/rdso/files/abc/view');
    expect(
      ApiConstants.rdsoFileDownloadPath('abc'),
      '/api/rdso/files/abc/download',
    );
  });
}
