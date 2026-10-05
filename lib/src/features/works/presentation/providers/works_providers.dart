import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/works/data/datasources/works_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/execution_progress_segment.dart';
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
