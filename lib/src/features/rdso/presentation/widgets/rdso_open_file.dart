import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/rdso/data/datasources/rdso_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rdso/data/rdso_file_actions.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_stored_file.dart';

Future<void> openRdsoFile({
  required WidgetRef ref,
  required BuildContext context,
  required String fileId,
  required String fallbackName,
  required bool preview,
  Rect? shareOrigin,
}) async {
  try {
    final ({Uint8List bytes, String fileName}) file = await ref
        .read(rdsoRemoteDataSourceProvider)
        .downloadFile(
          fileId: fileId,
          preview: preview,
          fallbackName: fallbackName,
        );
    if (!context.mounted) {
      return;
    }
    if (preview) {
      if (RfiStoredFile.looksLikeImage(file.bytes)) {
        await showDialog<void>(
          context: context,
          builder: (BuildContext dialogContext) {
            return Dialog(
              child: InteractiveViewer(
                child: Image.memory(file.bytes),
              ),
            );
          },
        );
        return;
      }
      await presentRdsoPreview(bytes: file.bytes, fileName: file.fileName);
      return;
    }
    await shareRdsoFile(
      bytes: file.bytes,
      fileName: file.fileName,
      sharePositionOrigin: shareOrigin,
    );
  } on Object catch (error) {
    if (!context.mounted) {
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: preview ? 'Preview' : 'Download',
      message: error is DioException
          ? userFriendlyErrorMessage(error)
          : error is StateError
          ? error.message
          : preview
          ? 'Unable to preview this file.'
          : 'Unable to download this file.',
    );
  }
}

Rect rdsoShareOrigin(BuildContext origin) {
  final RenderObject? box = origin.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    final Offset topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }
  final Size size = MediaQuery.sizeOf(origin);
  return Rect.fromLTWH(0, 0, size.width, size.height / 2);
}
