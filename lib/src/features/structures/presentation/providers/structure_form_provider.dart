import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/structures/data/datasources/structure_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/structures/domain/structure_form.dart';

final structureFormMasterProvider =
    FutureProvider.autoDispose<StructureFormMaster>((ref) {
      return ref.watch(structureRemoteDataSourceProvider).fetchFormMaster();
    });

final structureFullDetailProvider = FutureProvider.autoDispose
    .family<StructureFullDetail, String>((ref, String projectId) {
      return ref
          .watch(structureRemoteDataSourceProvider)
          .fetchFull(projectId);
    });

final structureProjectChainageProvider = FutureProvider.autoDispose
    .family<StructureProjectChainage, String>((ref, String projectId) {
      final String id = projectId.trim();
      if (id.isEmpty) {
        return Future<StructureProjectChainage>.value(
          StructureProjectChainage.empty,
        );
      }
      return ref
          .watch(structureRemoteDataSourceProvider)
          .fetchProjectChainage(id);
    });
