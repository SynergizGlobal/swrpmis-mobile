import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_list.dart';

List<RdsoSubhead> parseRdsoSubheads(dynamic data, {String categoryId = ''}) {
  final List<RdsoSubhead> out = <RdsoSubhead>[];
  for (final Map<String, dynamic> json in _maps(data)) {
    final String id = _display(json['id']);
    final String name = _display(json['name']);
    if (id.isEmpty && name.isEmpty) {
      continue;
    }
    final String cat = _display(json['categoryId']);
    out.add(
      RdsoSubhead(
        id: id.isEmpty ? name : id,
        categoryId: cat.isEmpty ? categoryId : cat,
        name: name.isEmpty ? id : name,
        sourceUrl: _display(json['sourceUrl']),
      ),
    );
  }
  return out;
}

List<RdsoDrawingRow> parseRdsoDrawingList(dynamic data) {
  final List<RdsoDrawingRow> items = <RdsoDrawingRow>[];
  for (final Map<String, dynamic> json in _maps(data)) {
    final RdsoDrawingRow? row = _row(json);
    if (row != null) {
      items.add(row);
    }
  }
  return items;
}

List<RdsoDrawingFile> parseRdsoDrawingFiles(dynamic data) {
  final List<RdsoDrawingFile> out = <RdsoDrawingFile>[];
  for (final Map<String, dynamic> json in _maps(data)) {
    final String id = _display(json['id'] ?? json['fileId']);
    final String name = _display(
      json['name'] ?? json['fileName'] ?? json['title'],
    );
    if (id.isEmpty && name.isEmpty) {
      continue;
    }
    out.add(
      RdsoDrawingFile(
        id: id.isEmpty ? name : id,
        name: name.isEmpty ? id : name,
        type: _display(json['type'] ?? json['fileType'] ?? json['mimeType']),
        status: _display(json['status']),
        size: _int(json['size'] ?? json['fileSize']),
      ),
    );
  }
  return out;
}

List<RdsoPost> parseRdsoPosts(dynamic data) {
  final List<RdsoPost> out = <RdsoPost>[];
  for (final Map<String, dynamic> json in _maps(data)) {
    final String content = _display(json['content'] ?? json['body']);
    if (content.isEmpty && _display(json['id']).isEmpty) {
      continue;
    }
    out.add(
      RdsoPost(
        id: _display(json['id']),
        drawingId: _display(json['drawingId']),
        postType: _display(json['postType'] ?? json['type']),
        content: content,
        author: _display(
          json['author'] ??
              json['authorName'] ??
              json['userName'] ??
              json['createdBy'],
        ),
        createdAt: _display(
          json['createdAt'] ?? json['created_at'] ?? json['postedAt'],
        ),
      ),
    );
  }
  return out;
}

List<RdsoCrawlRun> parseRdsoCrawlRuns(dynamic data) {
  final List<RdsoCrawlRun> out = <RdsoCrawlRun>[];
  for (final Map<String, dynamic> json in _maps(data)) {
    final String id = _display(json['id'] ?? json['runId']);
    if (id.isEmpty) {
      continue;
    }
    out.add(
      RdsoCrawlRun(
        id: id,
        status: _display(json['status']),
        phase: _display(json['phase']),
        categoriesCount: _int(
          json['categoriesCount'] ?? json['categoryCount'],
        ),
        subheadsCount: _int(json['subheadsCount'] ?? json['subheadCount']),
        drawingsCount: _int(json['drawingsCount'] ?? json['drawingCount']),
        filesCount: _int(json['filesCount'] ?? json['fileCount']),
        startedAt: _nullableText(json['startedAt'] ?? json['startTime']),
        finishedAt: _nullableText(json['finishedAt'] ?? json['endTime']),
        logTail: _display(json['logTail'] ?? json['tail']),
      ),
    );
  }
  return out;
}

String parseRdsoCrawlLogs(dynamic data) {
  if (data == null) {
    return '';
  }
  if (data is String) {
    return data;
  }
  if (data is List) {
    return data.map((dynamic line) => line.toString()).join('\n');
  }
  final Map<String, dynamic> map = _asMap(data);
  final dynamic lines = map['lines'] ?? map['logs'] ?? map['log'];
  if (lines is List) {
    return lines.map((dynamic line) => line.toString()).join('\n');
  }
  if (lines is String) {
    return lines;
  }
  final String text = _display(map['text'] ?? map['content']);
  return text;
}

String? rdsoApiMessage(dynamic data) {
  if (data is Map) {
    final dynamic message = data['message'] ?? data['error'];
    if (message != null) {
      final String text = message.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
  }
  if (data is String && data.trim().isNotEmpty) {
    return data.trim();
  }
  return null;
}

List<RdsoCategory> parseRdsoCategories(dynamic data) {
  final List<RdsoCategory> out = <RdsoCategory>[];
  for (final Map<String, dynamic> json in _maps(data)) {
    final String id = _display(json['id']);
    final String name = _display(json['name']);
    if (id.isEmpty && name.isEmpty) {
      continue;
    }
    out.add(
      RdsoCategory(
        id: id.isEmpty ? name : id,
        name: name.isEmpty ? id : name,
        sourceUrl: _display(json['sourceUrl']),
      ),
    );
  }
  return out;
}

RdsoRevisionSnapshot parseRdsoRegister(dynamic data) {
  final Map<String, dynamic> map = _asMap(data);
  final List<RdsoDrawingRow> items = <RdsoDrawingRow>[];
  for (final Map<String, dynamic> json in _maps(map['items'])) {
    final RdsoDrawingRow? row = _row(json);
    if (row != null) {
      items.add(row);
    }
  }
  return RdsoRevisionSnapshot(
    items: items,
    total: _int(map['total']) ?? items.length,
    page: _int(map['page']) ?? 0,
    size: _int(map['size']) ?? RdsoRevisionQuery.defaultSize,
    currentFiles: _int(map['currentFiles']) ?? 0,
    archivedFiles: _int(map['archivedFiles']) ?? 0,
  );
}

String formatRdsoFileSize(int? bytes) {
  if (bytes == null || bytes < 0) {
    return '—';
  }
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1048576) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / 1048576).toStringAsFixed(2)} MB';
}

RdsoDrawingRow? _row(Map<String, dynamic> json) {
  final String drawingKey = _display(json['drawingKey']);
  final String id = _display(json['id']);
  if (drawingKey.isEmpty && id.isEmpty) {
    return null;
  }
  return RdsoDrawingRow(
    id: id.isEmpty ? drawingKey : id,
    subheadId: _display(json['subheadId']),
    subheadName: _display(json['subheadName']),
    drawingKey: drawingKey,
    name: _display(json['name']),
    description: _display(json['description']),
    sourceUrl: _display(json['sourceUrl']),
    fileSize: _int(json['fileSize']),
    fileId: _nullableText(json['fileId']),
    status: _display(json['status']),
    department: _display(json['department']),
    revision: _display(
      json['revision'] ?? json['rev'] ?? json['revisionNo'],
    ),
    revisionDate: _display(
      json['revisionDate'] ??
          json['revDate'] ??
          json['revision_date'] ??
          json['modifiedDate'],
    ),
  );
}

Map<String, dynamic> _asMap(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  return <String, dynamic>{};
}

Iterable<Map<String, dynamic>> _maps(dynamic data) sync* {
  final dynamic list = data is Map ? (data['items'] ?? data['data'] ?? data) : data;
  if (list is! List) {
    return;
  }
  for (final dynamic item in list) {
    if (item is Map<String, dynamic>) {
      yield item;
    } else if (item is Map) {
      yield Map<String, dynamic>.from(item);
    }
  }
}

String _display(dynamic value) {
  return _nullableText(value) ?? '';
}

String? _nullableText(dynamic value) {
  if (value == null) {
    return null;
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return text;
}

int? _int(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString().trim());
}
