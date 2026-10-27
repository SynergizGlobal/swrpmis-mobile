import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_menu_access_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_menu_access.dart';

final rfiMenuAccessProvider = FutureProvider.autoDispose<RfiMenuAccess>((
  ref,
) async {
  final AuthSession? session = ref.watch(authControllerProvider).valueOrNull;
  if (session == null || session.userId.trim().isEmpty) {
    return RfiMenuAccess.allVisible;
  }
  return ref
      .watch(rfiMenuAccessRemoteDataSourceProvider)
      .fetch(
        userRole: session.userRoleNameFk,
        userType: session.userTypeFk,
        userId: session.userId,
      );
});
