import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/site_photo_row.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/providers/works_providers.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/widgets/site_photo_broken_placeholder.dart';

/// Opens View Photos as a fullscreen dialog route with an AppBar Close that
/// always works — even while loading or after a failed image fetch.
Future<void> showSitePhotosPreviewDialog({
  required BuildContext context,
  required SitePhotoRow row,
}) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (BuildContext context) => SitePhotosPreviewPage(row: row),
    ),
  );
}

class SitePhotosPreviewPage extends ConsumerStatefulWidget {
  const SitePhotosPreviewPage({super.key, required this.row});

  final SitePhotoRow row;

  @override
  ConsumerState<SitePhotosPreviewPage> createState() =>
      _SitePhotosPreviewPageState();
}

class _SitePhotosPreviewPageState extends ConsumerState<SitePhotosPreviewPage> {
  late int _photoIndex;

  @override
  void initState() {
    super.initState();
    _photoIndex = 0;
  }

  SitePhotoRow get row => widget.row;

  List<String> get _photos => row.photos;

  void _close() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool hasPhotos = _photos.isNotEmpty;
    final bool canGoPrevious = hasPhotos && _photoIndex > 0;
    final bool canGoNext = hasPhotos && _photoIndex < _photos.length - 1;
    final String? currentFileName = hasPhotos ? _photos[_photoIndex] : null;

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('View Photos'),
          actions: <Widget>[
            IconButton(
              tooltip: 'Close',
              onPressed: _close,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    _MetaChip(label: 'Section', value: row.section),
                    _MetaChip(label: 'Structure', value: row.structure),
                    _MetaChip(
                      label: 'Component',
                      value: row.structureComponent,
                    ),
                    _MetaChip(label: 'Component ID', value: row.componentId),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.45),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: currentFileName == null
                          ? const SitePhotoBrokenPlaceholder(
                              message: 'No photo file on this row',
                            )
                          : StructurePhotoViewer(fileName: currentFileName),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Row(
                  children: <Widget>[
                    Flexible(
                      child: OutlinedButton.icon(
                        // Theme uses Size.fromHeight → infinite min width; Row
                        // children are horizontally unconstrained without this.
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, AppTheme.fieldHeight),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: canGoPrevious
                            ? () => setState(() => _photoIndex -= 1)
                            : null,
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: const Text('Previous'),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        hasPhotos
                            ? '${_photoIndex + 1} / ${_photos.length}'
                            : '0 / 0',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Flexible(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, AppTheme.fieldHeight),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: canGoNext
                            ? () => setState(() => _photoIndex += 1)
                            : null,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('Next'),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                child: OutlinedButton(
                  // Column stretch already gives a finite max width.
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppTheme.fieldHeight),
                  ),
                  onPressed: _close,
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});

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
          style: theme.textTheme.labelMedium?.copyWith(
            color: cs.onSurface,
            height: 1.2,
          ),
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

/// Loads `/STRUCTURE_FILES/{fileName}` with a UI watchdog so loading never
/// traps the user on a blank spinner.
class StructurePhotoViewer extends ConsumerStatefulWidget {
  const StructurePhotoViewer({
    super.key,
    required this.fileName,
    this.fit = BoxFit.contain,
  });

  final String fileName;
  final BoxFit fit;

  @override
  ConsumerState<StructurePhotoViewer> createState() =>
      _StructurePhotoViewerState();
}

class _StructurePhotoViewerState extends ConsumerState<StructurePhotoViewer> {
  static const Duration _watchdog = Duration(seconds: 22);

  Timer? _watchdogTimer;
  bool _timedOut = false;
  bool _settled = false;

  @override
  void initState() {
    super.initState();
    _armWatchdog();
  }

  @override
  void didUpdateWidget(covariant StructurePhotoViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileName != widget.fileName) {
      _timedOut = false;
      _settled = false;
      _armWatchdog();
    }
  }

  @override
  void dispose() {
    _watchdogTimer?.cancel();
    super.dispose();
  }

  void _armWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(_watchdog, () {
      if (!mounted || _settled) {
        return;
      }
      setState(() => _timedOut = true);
    });
  }

  void _markSettled() {
    if (_settled) {
      return;
    }
    _settled = true;
    _watchdogTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final String trimmed = widget.fileName.trim();
    if (trimmed.isEmpty || _timedOut) {
      return const SitePhotoBrokenPlaceholder();
    }

    final AsyncValue<Uint8List> photoAsync = ref.watch(
      structurePhotoBytesProvider(trimmed),
    );

    ref.listen<AsyncValue<Uint8List>>(structurePhotoBytesProvider(trimmed), (
      AsyncValue<Uint8List>? previous,
      AsyncValue<Uint8List> next,
    ) {
      if (!next.isLoading) {
        _markSettled();
      }
    });

    return photoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) =>
          const SitePhotoBrokenPlaceholder(),
      data: (Uint8List bytes) {
        if (bytes.isEmpty) {
          return const SitePhotoBrokenPlaceholder();
        }
        return InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Center(
            child: Image.memory(
              bytes,
              fit: widget.fit,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? _) {
                return const SitePhotoBrokenPlaceholder(
                  message: 'Image unavailable',
                );
              },
            ),
          ),
        );
      },
    );
  }
}
