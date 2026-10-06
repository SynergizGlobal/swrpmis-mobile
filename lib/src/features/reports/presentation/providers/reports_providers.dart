import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/reports/data/datasources/reports_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/reports_tree.dart';

final reportsTreeProvider = FutureProvider<ReportsTree>((ref) {
  return ref.watch(reportsRemoteDataSourceProvider).fetchReportForms();
});
