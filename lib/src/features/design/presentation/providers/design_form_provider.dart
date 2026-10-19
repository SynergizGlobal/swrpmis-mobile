import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/design/data/datasources/design_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/design/domain/design_form.dart';

final designFormMasterProvider =
    FutureProvider.autoDispose<DesignFormMaster>((ref) {
      return ref.watch(designRemoteDataSourceProvider).fetchFormMaster();
    });
