import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_dashboard_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_dashboard_counts.dart';

final rfiDashboardProvider = FutureProvider.autoDispose<RfiDashboardCounts>((
  ref,
) {
  return ref.watch(rfiDashboardRemoteDataSourceProvider).fetchCounts();
});
