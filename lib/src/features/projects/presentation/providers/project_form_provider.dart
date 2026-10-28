import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/projects/data/datasources/project_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/projects/domain/project_form.dart';

final projectFormMasterProvider =
    FutureProvider.autoDispose<ProjectFormMaster>((ref) {
      return ref.watch(projectRemoteDataSourceProvider).fetchFormMaster();
    });
