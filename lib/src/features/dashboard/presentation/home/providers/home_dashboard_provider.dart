import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/dashboard/domain/entities/home_dashboard_data.dart';

final homeDashboardProvider = FutureProvider<HomeDashboardData>((ref) {
  return ref.watch(dashboardRemoteDataSourceProvider).fetchHome();
});
