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

final rfiCategoryAccessProvider = FutureProvider.autoDispose
    .family<RfiCategoryAccess?, RfiListKind>((ref, RfiListKind kind) {
      final String? category = switch (kind) {
        RfiListKind.work => 'WORK',
        RfiListKind.material => null,
        RfiListKind.quality => 'QUALITY_OR_SAFETY',
      };
      if (category == null) {
        return Future<RfiCategoryAccess?>.value();
      }
      return ref
          .watch(rfiRemoteDataSourceProvider)
          .fetchCategoryAccess(category);
    });
