import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/update_forms/data/datasources/update_forms_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/update_forms/domain/entities/update_forms_tree.dart';

final updateFormsTreeProvider = FutureProvider<UpdateFormsTree>((ref) {
  return ref.watch(updateFormsRemoteDataSourceProvider).fetchUpdateForms();
});
