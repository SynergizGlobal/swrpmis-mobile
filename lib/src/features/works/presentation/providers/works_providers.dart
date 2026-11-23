import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/works/data/datasources/works_remote_data_source.dart';
import 'package:intl/intl.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/daily_progress_query.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/daily_progress_row.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/exception_report.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/exception_report_detail.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/execution_progress_segment.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/site_photo_row.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/works_tree.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/execution_chart_data.dart';

final worksTreeProvider = FutureProvider<WorksTree>((ref) {
  return ref.watch(worksRemoteDataSourceProvider).fetchWorksTree();
});

final executionProgressProvider =
    FutureProvider.family<ExecutionChartData, String>((
      ref,
      String projectId,
    ) async {
      final List<ExecutionProgressSegment> segments = await ref
          .watch(worksRemoteDataSourceProvider)
          .fetchExecutionProgress(projectId);
      return ExecutionChartData.fromSegments(segments);
    });

final sitePhotosProvider =
    FutureProvider.family<List<SitePhotoRow>, String>((
      ref,
      String projectId,
    ) async {
      final List<Map<String, dynamic>> rows = await ref
          .watch(worksRemoteDataSourceProvider)
          .fetchSitePhotos(projectId: projectId);
      return rows.map(SitePhotoRow.fromMap).toList(growable: false);
    });

final dailyProgressProvider =
    FutureProvider.family<List<DailyProgressRow>, DailyProgressQuery>((
      ref,
      DailyProgressQuery query,
    ) async {
      final DateFormat apiDate = DateFormat('yyyy-MM-dd');
      final List<Map<String, dynamic>> rows = await ref
          .watch(worksRemoteDataSourceProvider)
          .fetchDailyProgress(
            projectId: query.projectId,
            fromDate: apiDate.format(query.fromDate),
            toDate: apiDate.format(query.toDate),
            date: apiDate.format(query.date),
          );
      return rows.map(DailyProgressRow.fromMap).toList(growable: false);
    });

final structurePhotoBytesProvider =
    FutureProvider.family<Uint8List, String>((ref, String fileName) async {
      return ref
          .watch(worksRemoteDataSourceProvider)
          .fetchStructurePhotoBytes(fileName);
    });

final exceptionReportProvider =
    FutureProvider.family<ExceptionReportData, String>((
      ref,
      String projectId,
    ) async {
      return ref
          .watch(worksRemoteDataSourceProvider)
          .fetchExceptionReport(projectId: projectId);
    });

final exceptionReportDetailProvider =
    FutureProvider.family<ExceptionReportDetail, int>((
      ref,
      int structureId,
    ) async {
      return ref
          .watch(worksRemoteDataSourceProvider)
          .fetchExceptionReportStructure(structureId: structureId);
    });
