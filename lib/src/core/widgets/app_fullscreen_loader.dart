import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:swr_pmis_mobile/src/core/constants/app_assets.dart';

/// Full-page or blocking overlay loader powered by
/// [AppAssets.loaderFullscreenLottie].
///
/// Use as a page/body loading state, or as a [Stack] child for a blocking
/// scrim while work is in progress. Falls back to [CircularProgressIndicator]
/// if the Lottie asset fails to load.
class AppFullscreenLoader extends StatelessWidget {
  const AppFullscreenLoader({
    super.key,
    this.scrimColor,
    this.size = 220,
  }) : _expand = false;

  /// Blocking overlay with a default dim scrim (for [Stack] usage).
  ///
  /// Expands to fill the parent so the scrim covers the whole surface.
  const AppFullscreenLoader.blocking({
    super.key,
    this.scrimColor = const Color(0x66000000),
    this.size = 220,
  }) : _expand = true;

  /// Optional fill color behind the animation (e.g. dim scrim).
  final Color? scrimColor;

  /// Rendered width/height of the Lottie (or fallback spinner box).
  final double size;

  final bool _expand;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Widget indicator = Lottie.asset(
      AppAssets.loaderFullscreenLottie,
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: true,
      frameRate: FrameRate.max,
      addRepaintBoundary: true,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
        debugPrint('Fullscreen loader Lottie failed: $error\n$stackTrace');
        return SizedBox(
          width: size * 0.28,
          height: size * 0.28,
          child: CircularProgressIndicator(color: primary),
        );
      },
    );

    Widget child = Center(child: indicator);

    final Color? scrim = scrimColor;
    if (scrim != null) {
      child = ColoredBox(color: scrim, child: child);
    }

    if (_expand) {
      return SizedBox.expand(
        child: AbsorbPointer(child: child),
      );
    }

    // Page/body usage: [Center] fills finite constraints without breaking
    // scroll views that pass unbounded max height.
    return child;
  }
}
