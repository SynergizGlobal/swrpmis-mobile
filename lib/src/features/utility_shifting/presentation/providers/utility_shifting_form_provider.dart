import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/data/datasources/utility_shifting_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/domain/utility_shifting_form.dart';

final utilityShiftingFormMasterProvider =
    FutureProvider.autoDispose<UtilityShiftingFormMaster>((ref) {
      return ref
          .watch(utilityShiftingRemoteDataSourceProvider)
          .fetchAddFormMaster();
    });

final utilityShiftingDetailProvider = FutureProvider.autoDispose
    .family<UtilityShiftingDetail, String>((ref, String utilityShiftingId) {
      return ref
          .watch(utilityShiftingRemoteDataSourceProvider)
          .fetchUtilityShifting(utilityShiftingId: utilityShiftingId);
    });
