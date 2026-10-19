import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_inspection_flow_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_access.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_row.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/pages/rfi_inspection_flow_page.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_inspection_flow_provider.dart';

Future<void> startRfiInspectionFlow({
  required BuildContext context,
  required WidgetRef ref,
  required RfiInspectionRow row,
  required bool offline,
}) async {
  final int? rfiId = row.id;
  if (rfiId == null) {
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: 'Unable to start',
      message: 'RFI id is missing for this row.',
    );
    return;
  }

  final AuthSession? session = ref.read(authControllerProvider).valueOrNull;
  final String userId = session?.userId.trim() ?? '';
  if (userId.isEmpty) {
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: 'Unable to start',
      message: 'Logged-in user id is missing.',
    );
    return;
  }

  final String category = row.rfiCategory.trim();
  if (category.isEmpty) {
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: 'Unable to start',
      message: 'RFI category is missing for this row.',
    );
    return;
  }

  final RfiInspectionFlowRemoteDataSource source =
      ref.read(rfiInspectionFlowRemoteDataSourceProvider);

  try {
    final RfiInspectionAccess access = await source.fetchAccess(category);
    if (!context.mounted) {
      return;
    }
    if (!access.hasAccess) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Access denied',
        message: access.message.isEmpty
            ? 'You do not have access to start this inspection.'
            : access.message,
      );
      return;
    }

    final RfiUserSignature signature = await source.checkUserSignature(userId);
    if (!context.mounted) {
      return;
    }
    if (!signature.exists) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Signature required',
        message: 'Signature not found. Please upload signature first.',
      );
      return;
    }

    await source.fetchDetails(rfiId);
    if (!context.mounted) {
      return;
    }

    await context.pushNamed(
      RfiInspectionFlowPage.routeName,
      extra: RfiInspectionFlowArgs(
        rfiId: rfiId,
        rfiCategory: category,
        offline: offline,
      ),
    );
  } on Object catch (error) {
    if (!context.mounted) {
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: 'Unable to start inspection',
      message: error is DioException
          ? userFriendlyErrorMessage(error)
          : error.toString(),
    );
  }
}
