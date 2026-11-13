import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_category_access.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_list_item.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_list_kind.dart';

final rfiListProvider = FutureProvider.family<List<RfiListItem>, RfiListKind>((
  ref,
  RfiListKind kind,
) {
  return ref.watch(rfiRemoteDataSourceProvider).fetchList(kind);
});

/// Server access for a list kind. Only Work RFI is checked against the
/// server today (the web calls these APIs with `rfiCategory=WORK`).
final rfiCategoryAccessProvider = FutureProvider.autoDispose
    .family<RfiCategoryAccess?, RfiListKind>((ref, RfiListKind kind) {
      if (kind != RfiListKind.work) {
        return Future<RfiCategoryAccess?>.value();
      }
      return ref.watch(rfiRemoteDataSourceProvider).fetchCategoryAccess('WORK');
    });
