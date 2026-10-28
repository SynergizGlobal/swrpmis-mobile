import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/structure_form/data/datasources/structure_form_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/structure_form/domain/structure_form_detail.dart';

final structureFormEditProvider = FutureProvider.autoDispose
    .family<StructureFormMaster, String>((ref, String structureId) {
      return ref
          .watch(structureFormRemoteDataSourceProvider)
          .fetchStructureForm(structureId: structureId);
    });
