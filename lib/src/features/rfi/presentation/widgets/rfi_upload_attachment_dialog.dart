import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_button_lottie.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_inspection_remote_data_source.dart';

Future<bool> showRfiUploadAttachmentDialog(
  BuildContext context, {
  required int rfiId,
}) async {
  final bool? uploaded = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => _RfiUploadAttachmentDialog(rfiId: rfiId),
  );
  return uploaded == true;
}

class _RfiUploadAttachmentDialog extends ConsumerStatefulWidget {
  const _RfiUploadAttachmentDialog({required this.rfiId});

  final int rfiId;

  @override
  ConsumerState<_RfiUploadAttachmentDialog> createState() =>
      _RfiUploadAttachmentDialogState();
}

class _RfiUploadAttachmentDialogState
    extends ConsumerState<_RfiUploadAttachmentDialog> {
  final TextEditingController _description = TextEditingController();
  PlatformFile? _file;
  bool _busy = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  bool get _canUpload =>
      !_busy &&
      _description.text.trim().isNotEmpty &&
      _file != null &&
      (_file!.path?.isNotEmpty ?? false);

  Future<void> _pick() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) {
      return;
    }
    setState(() => _file = result.files.single);
  }

  Future<void> _upload() async {
    final PlatformFile? file = _file;
    final String? path = file?.path;
    if (!_canUpload || file == null || path == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      final String message = await ref
          .read(rfiInspectionRemoteDataSourceProvider)
          .uploadAttachment(
            rfiId: widget.rfiId,
            description: _description.text.trim(),
            filePath: path,
            fileName: file.name,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Upload Attachment',
        message: message,
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Upload Attachment',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Upload Attachment'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _description,
              enabled: !_busy,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Enter description',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text(
              'Attach File *',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(_file == null ? 'Choose file' : 'Change file'),
            ),
            if (_file != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Selected File: ${_file!.name}',
                style: TextStyle(color: scheme.primary),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, AppTheme.fieldHeight),
          ),
          onPressed: _canUpload ? _upload : null,
          child: _busy
              ? const AppButtonLoader.white(height: 18)
              : const Text('Upload'),
        ),
      ],
    );
  }
}
