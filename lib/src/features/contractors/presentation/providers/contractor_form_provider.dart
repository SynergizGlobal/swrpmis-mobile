import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/contractors/data/datasources/contractor_remote_data_source.dart';

final contractorSpecializationsProvider =
    FutureProvider.autoDispose<List<String>>((ref) {
      return ref.watch(contractorRemoteDataSourceProvider).fetchSpecializations();
    });
