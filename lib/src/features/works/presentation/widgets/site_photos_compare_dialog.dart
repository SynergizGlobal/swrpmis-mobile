import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/site_photo_row.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/providers/works_providers.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/widgets/site_photo_broken_placeholder.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/widgets/site_photos_preview_dialog.dart';

Future<void> showSitePhotosCompareDialog({
  required BuildContext context,
  required SitePhotoRow left,
  required SitePhotoRow right,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return _SitePhotosCompareDialog(left: left, right: right);
    },
  );
}

class _SitePhotosCompareDialog extends ConsumerStatefulWidget {
  const _SitePhotosCompareDialog({required this.left, required this.right});

  final SitePhotoRow left;
  final SitePhotoRow right;

  @override
  ConsumerState<_SitePhotosCompareDialog> createState() =>
      _SitePhotosCompareDialogState();
}

class _SitePhotosCompareDialogState
    extends ConsumerState<_SitePhotosCompareDialog> {
  late SitePhotoRow _left;
  late SitePhotoRow _right;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _left = widget.left;
    _right = widget.right;
  }

  void _swap() {
    setState(() {
      final SitePhotoRow temp = _left;
      _left = _right;
      _right = temp;
    });
  }

  Future<void> _downloadBoth() async {
    if (_downloading) {
      return;
    }
    setState(() => _downloading = true);
    try {
      final List<XFile> files = <XFile>[];
      final Directory directory = await getTemporaryDirectory();
      for (final SitePhotoRow row in <SitePhotoRow>[_left, _right]) {
        if (row.photos.isEmpty) {
          continue;
        }
        final String fileName = row.photos.first;
        final Uint8List bytes = await ref.read(
          structurePhotoBytesProvider(fileName).future,
        );
        final File file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        files.add(XFile(file.path, name: fileName, mimeType: 'image/jpeg'));
      }
      if (!mounted) {
        return;
      }
      if (files.isEmpty) {
        await AppDialog.show(
          context,
          title: 'Download unavailable',
          message: 'No photos are available to download.',
          variant: AppDialogVariant.warning,
        );
        return;
      }
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      final Rect? origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;
      await SharePlus.instance.share(
        ShareParams(
          files: files,
          sharePositionOrigin: origin ?? const Rect.fromLTWH(0, 0, 1, 1),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        title: 'Download failed',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString(),
        variant: AppDialogVariant.error,
      );
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  Future<void> _openFullScreen(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext routeContext) {
          return _CompareFullScreenPage(left: _left, right: _right);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 980,
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: <Widget>[
                        _HeaderChip(label: 'Section', value: _left.section),
                        _HeaderChip(label: 'Structure', value: _left.structure),
                        _HeaderChip(
                          label: 'Component',
                          value: _left.structureComponent,
                        ),
                        _HeaderChip(
                          label: 'Component ID',
                          value: _left.componentId,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: cs.error.withValues(alpha: 0.12),
                      foregroundColor: cs.error,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool stacked = constraints.maxWidth < 720;
                  final Widget leftPane = _ComparePane(row: _left);
                  final Widget rightPane = _ComparePane(row: _right);
                  final Widget swapButton = Material(
                    color: cs.primary,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Swap',
                      onPressed: _swap,
                      icon: const Icon(Icons.swap_horiz_rounded),
                      color: cs.onPrimary,
                    ),
                  );

                  if (stacked) {
                    return ListView(
                      padding: const EdgeInsets.all(12),
                      children: <Widget>[
                        _ComparePane(row: _left, imageHeight: 220),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Center(child: swapButton),
                        ),
                        _ComparePane(row: _right, imageHeight: 220),
                      ],
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(child: leftPane),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Center(child: swapButton),
                        ),
                        Expanded(child: rightPane),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    // Avoid theme Size.fromHeight (infinite min width) in Wrap.
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, AppTheme.fieldHeight),
                    ),
                    onPressed: _downloading ? null : _downloadBoth,
                    icon: _downloading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download Both'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, AppTheme.fieldHeight),
                    ),
                    onPressed: () => _openFullScreen(context),
                    icon: const Icon(Icons.fullscreen_rounded, size: 18),
                    label: const Text('Full Screen'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparePane extends StatelessWidget {
  const _ComparePane({required this.row, this.imageHeight});

  final SitePhotoRow row;
  final double? imageHeight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? fileName = row.photos.isEmpty ? null : row.photos.first;

    final Widget imageBox = DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: fileName == null
            ? const SitePhotoBrokenPlaceholder()
            : StructurePhotoViewer(fileName: fileName),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.calendar_today_rounded, size: 14, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              'Date: ${row.displayDate}',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (imageHeight != null)
          SizedBox(height: imageHeight, child: imageBox)
        else
          Expanded(child: imageBox),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Photo Details',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                _DetailLine(label: 'Structure Type', value: row.structureType),
                _DetailLine(label: 'Structure', value: row.structure),
                _DetailLine(label: 'Component', value: row.structureComponent),
                _DetailLine(label: 'Component ID', value: row.componentId),
                _DetailLine(label: 'Location', value: row.location),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.35,
          ),
          children: <TextSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurface),
          children: <TextSpan>[
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareFullScreenPage extends StatelessWidget {
  const _CompareFullScreenPage({required this.left, required this.right});

  final SitePhotoRow left;
  final SitePhotoRow right;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Photos'),
        actions: <Widget>[
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool stacked = constraints.maxWidth < 700;
            final Widget leftPane = _FullPane(row: left);
            final Widget rightPane = _FullPane(row: right);
            if (stacked) {
              return ListView(
                padding: const EdgeInsets.all(12),
                children: <Widget>[
                  SizedBox(height: constraints.maxHeight * 0.45, child: leftPane),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: constraints.maxHeight * 0.45,
                    child: rightPane,
                  ),
                ],
              );
            }
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  Expanded(child: leftPane),
                  const SizedBox(width: 12),
                  Expanded(child: rightPane),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FullPane extends StatelessWidget {
  const _FullPane({required this.row});

  final SitePhotoRow row;

  @override
  Widget build(BuildContext context) {
    final String? fileName = row.photos.isEmpty ? null : row.photos.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Date: ${row.displayDate}',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: fileName == null
                  ? const SitePhotoBrokenPlaceholder()
                  : StructurePhotoViewer(fileName: fileName),
            ),
          ),
        ),
      ],
    );
  }
}
