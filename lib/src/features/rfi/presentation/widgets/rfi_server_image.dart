import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_log_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_stored_file.dart';

/// Bytes of a file stored on the server (e.g.
/// `/home/.../Rfi-Storage/uploads/siteImages/x.jpg`), fetched once per path
/// through the same preview endpoint the RFI Log uses.
final rfiServerFileProvider = FutureProvider.autoDispose
    .family<Uint8List, String>((ref, String path) {
      ref.keepAlive();
      return ref.read(rfiLogRemoteDataSourceProvider).previewFile(path);
    });

/// A grid of server images as tappable thumbnails; tapping opens a zoomable
/// full-screen preview.
class RfiServerImageGrid extends StatelessWidget {
  const RfiServerImageGrid({super.key, required this.paths, this.onDelete});

  final List<String> paths;

  /// When set, each thumbnail gets a delete badge that calls this with the
  /// image's server path.
  final ValueChanged<String>? onDelete;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        for (int i = 0; i < paths.length; i++)
          RfiServerImageThumbnail(
            path: paths[i],
            index: i + 1,
            onDelete: onDelete == null ? null : () => onDelete!(paths[i]),
          ),
      ],
    );
  }
}

class RfiServerImageThumbnail extends ConsumerWidget {
  const RfiServerImageThumbnail({
    super.key,
    required this.path,
    required this.index,
    this.size = 84,
    this.onDelete,
  });

  final String path;
  final int index;
  final double size;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AsyncValue<Uint8List> image = ref.watch(rfiServerFileProvider(path));
    final Uint8List? bytes =
        image.hasValue && RfiStoredFile.looksLikeImage(image.requireValue)
        ? image.requireValue
        : null;
    final Widget content = image.isLoading
        ? const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : bytes != null
        ? Image.memory(
            bytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            // Decode at thumbnail size, not the photo's full 12 MP.
            cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
            frameBuilder: _fadeIn,
          )
        : Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: scheme.onSurfaceVariant,
            ),
          );
    final Widget thumbnail = Semantics(
      button: true,
      label: 'Site image $index',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: image.isLoading
            ? null
            : bytes == null
            ? () => ref.invalidate(rfiServerFileProvider(path))
            : () => _openFullScreen(context, bytes),
        child: Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: content,
        ),
      ),
    );
    if (onDelete == null) {
      return thumbnail;
    }
    return Stack(
      children: <Widget>[
        thumbnail,
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: const Color(0xFFC1121F),
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onDelete,
              child: Semantics(
                button: true,
                label: 'Delete site image $index',
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openFullScreen(BuildContext context, Uint8List bytes) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (BuildContext dialogContext) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: InteractiveViewer(
                  maxScale: 5,
                  child: Center(
                    child: Image.memory(
                      bytes,
                      gaplessPlayback: true,
                      // Twice the screen width keeps zoom sharp without
                      // decoding the full camera resolution.
                      cacheWidth: _previewDecodeWidth(dialogContext),
                      frameBuilder: _fadeIn,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    tooltip: 'Close',
                    color: Colors.white,
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

int _previewDecodeWidth(BuildContext context) {
  final double width =
      MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context);
  return (width * 2).clamp(800, 3000).round();
}

/// Shows a spinner until the decoded frame is ready, then fades it in.
Widget _fadeIn(
  BuildContext context,
  Widget child,
  int? frame,
  bool wasSynchronouslyLoaded,
) {
  if (wasSynchronouslyLoaded) {
    return child;
  }
  return Stack(
    alignment: Alignment.center,
    children: <Widget>[
      if (frame == null)
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      AnimatedOpacity(
        opacity: frame == null ? 0 : 1,
        duration: const Duration(milliseconds: 200),
        child: child,
      ),
    ],
  );
}
