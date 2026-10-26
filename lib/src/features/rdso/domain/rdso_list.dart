/// Placeholder shown in RDSO filter dropdowns when nothing is selected.
const String rdsoFilterEmptyLabel = 'Select';

class RdsoCategory {
  const RdsoCategory({
    required this.id,
    required this.name,
    this.sourceUrl = '',
  });

  final String id;
  final String name;
  final String sourceUrl;
}

class RdsoSubhead {
  const RdsoSubhead({
    required this.id,
    required this.categoryId,
    required this.name,
    this.sourceUrl = '',
  });

  final String id;
  final String categoryId;
  final String name;
  final String sourceUrl;
}

class RdsoDrawingFile {
  const RdsoDrawingFile({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.size,
  });

  final String id;
  final String name;
  final String type;
  final String status;
  final int? size;

  bool get hasFile => id.trim().isNotEmpty;
}

class RdsoPost {
  const RdsoPost({
    required this.id,
    required this.drawingId,
    required this.postType,
    required this.content,
    required this.author,
    required this.createdAt,
  });

  final String id;
  final String drawingId;
  final String postType;
  final String content;
  final String author;
  final String createdAt;

  bool get isFeedback => postType.toLowerCase() == 'feedback';
}

class RdsoCrawlRun {
  const RdsoCrawlRun({
    required this.id,
    required this.status,
    required this.phase,
    this.categoriesCount,
    this.subheadsCount,
    this.drawingsCount,
    this.filesCount,
    this.startedAt,
    this.finishedAt,
    this.logTail = '',
  });

  final String id;
  final String status;
  final String phase;
  final int? categoriesCount;
  final int? subheadsCount;
  final int? drawingsCount;
  final int? filesCount;
  final String? startedAt;
  final String? finishedAt;
  final String logTail;

  bool get isRunning {
    final String normalized =
        status.trim().toLowerCase().replaceAll('-', '_');
    return normalized == 'running' || normalized == 'in_progress';
  }
}

enum RdsoLibraryListMode { tree, search }

class RdsoLibraryQuery {
  const RdsoLibraryQuery({
    this.q = '',
    this.categoryId = '',
    this.status = '',
    this.page = 1,
    this.size = RdsoRevisionQuery.defaultSize,
  });

  final String q;
  final String categoryId;
  final String status;
  final int page;
  final int size;

  int get apiPage {
    final int safe = page < 1 ? 1 : page;
    return safe - 1;
  }

  bool get hasSearchFilters {
    return q.trim().isNotEmpty ||
        categoryId.trim().isNotEmpty ||
        status.trim().isNotEmpty;
  }

  Map<String, dynamic> queryParameters() {
    final Map<String, dynamic> params = <String, dynamic>{
      'page': apiPage,
      'size': size < 1 ? RdsoRevisionQuery.defaultSize : size,
    };
    final String search = q.trim();
    if (search.isNotEmpty) {
      params['q'] = search;
    }
    final String category = categoryId.trim();
    if (category.isNotEmpty) {
      params['categoryId'] = category;
    }
    final String statusValue = status.trim();
    if (statusValue.isNotEmpty) {
      params['status'] = statusValue;
    }
    return params;
  }

  /// Web `/api/rdso/drawings/search` accepts only `q` (no pagination or filters).
  Map<String, dynamic> drawingSearchQueryParameters() {
    final String search = q.trim();
    if (search.isEmpty) {
      return const <String, dynamic>{};
    }
    return <String, dynamic>{'q': search};
  }

  bool get usesDrawingSearchEndpoint => q.trim().isNotEmpty;

  RdsoLibraryQuery copyWith({
    String? q,
    String? categoryId,
    String? status,
    int? page,
    int? size,
  }) {
    return RdsoLibraryQuery(
      q: q ?? this.q,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      page: page ?? this.page,
      size: size ?? this.size,
    );
  }
}

class RdsoDrawingRow {
  const RdsoDrawingRow({
    required this.id,
    required this.subheadId,
    required this.subheadName,
    required this.drawingKey,
    required this.name,
    required this.description,
    required this.sourceUrl,
    required this.fileSize,
    required this.fileId,
    required this.status,
    required this.department,
    required this.revision,
    required this.revisionDate,
  });

  final String id;
  final String subheadId;
  final String subheadName;
  final String drawingKey;
  final String name;
  final String description;
  final String sourceUrl;
  final int? fileSize;
  final String? fileId;
  final String status;
  final String department;
  final String revision;
  final String revisionDate;

  String get title {
    final String desc = description.trim();
    if (desc.isNotEmpty) {
      return desc;
    }
    return name.trim();
  }

  bool get hasFile {
    final String? id = fileId?.trim();
    return id != null && id.isNotEmpty;
  }
}

/// Matches [rowStatus] to a filter value such as `Current` or `Archived`.
bool rdsoDrawingMatchesStatus(String rowStatus, String statusFilter) {
  final String filter = statusFilter.trim();
  if (filter.isEmpty) {
    return true;
  }
  final String normalized = rowStatus.trim();
  if (normalized.isEmpty) {
    return false;
  }
  return normalized.toLowerCase() == filter.toLowerCase();
}

List<RdsoDrawingRow> filterRdsoDrawingsByStatus(
  List<RdsoDrawingRow> rows,
  String statusFilter,
) {
  final String filter = statusFilter.trim();
  if (filter.isEmpty) {
    return rows;
  }
  return rows
      .where(
        (RdsoDrawingRow row) =>
            rdsoDrawingMatchesStatus(row.status, statusFilter),
      )
      .toList(growable: false);
}

List<RdsoDrawingRow> paginateRdsoDrawings(
  List<RdsoDrawingRow> rows, {
  required int page,
  required int size,
}) {
  if (rows.isEmpty) {
    return rows;
  }
  final int pageSize = size < 1 ? RdsoRevisionQuery.defaultSize : size;
  final int safePage = page < 1 ? 1 : page;
  final int start = (safePage - 1) * pageSize;
  if (start >= rows.length) {
    return const <RdsoDrawingRow>[];
  }
  final int end = start + pageSize;
  return rows.sublist(start, end > rows.length ? rows.length : end);
}

class RdsoRevisionQuery {
  const RdsoRevisionQuery({
    this.q = '',
    this.categoryId = '',
    this.status = '',
    this.date = '',
    this.page = 1,
    this.size = defaultSize,
  });

  static const int defaultSize = 8;

  final String q;
  final String categoryId;
  final String status;
  final String date;
  final int page;
  final int size;

  /// Web register API uses 0-based `page`.
  int get apiPage {
    final int safe = page < 1 ? 1 : page;
    return safe - 1;
  }

  Map<String, dynamic> queryParameters() {
    final Map<String, dynamic> params = <String, dynamic>{
      'page': apiPage,
      'size': size < 1 ? defaultSize : size,
    };
    final String search = q.trim();
    if (search.isNotEmpty) {
      params['q'] = search;
    }
    final String category = categoryId.trim();
    if (category.isNotEmpty) {
      params['categoryId'] = category;
    }
    final String statusValue = status.trim();
    if (statusValue.isNotEmpty) {
      params['status'] = statusValue;
    }
    final String dateValue = date.trim();
    if (dateValue.isNotEmpty) {
      params['date'] = dateValue;
    }
    return params;
  }

  RdsoRevisionQuery copyWith({
    String? q,
    String? categoryId,
    String? status,
    String? date,
    int? page,
    int? size,
  }) {
    return RdsoRevisionQuery(
      q: q ?? this.q,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      date: date ?? this.date,
      page: page ?? this.page,
      size: size ?? this.size,
    );
  }
}

class RdsoRevisionSnapshot {
  const RdsoRevisionSnapshot({
    this.categories = const <RdsoCategory>[],
    this.items = const <RdsoDrawingRow>[],
    this.total = 0,
    this.page = 0,
    this.size = RdsoRevisionQuery.defaultSize,
    this.currentFiles = 0,
    this.archivedFiles = 0,
  });

  static const RdsoRevisionSnapshot empty = RdsoRevisionSnapshot();

  final List<RdsoCategory> categories;
  final List<RdsoDrawingRow> items;
  final int total;
  final int page;
  final int size;
  final int currentFiles;
  final int archivedFiles;

  RdsoRevisionSnapshot copyWith({
    List<RdsoCategory>? categories,
    List<RdsoDrawingRow>? items,
    int? total,
    int? page,
    int? size,
    int? currentFiles,
    int? archivedFiles,
  }) {
    return RdsoRevisionSnapshot(
      categories: categories ?? this.categories,
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      size: size ?? this.size,
      currentFiles: currentFiles ?? this.currentFiles,
      archivedFiles: archivedFiles ?? this.archivedFiles,
    );
  }
}
