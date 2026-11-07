import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:swr_pmis_mobile/src/core/constants/app_assets.dart';

/// Stroke color for compact button Lottie animations.
enum AppButtonLottieTone {
  /// White strokes — filled / primary / dark buttons.
  white,

  /// Navy strokes — outlined / secondary / light buttons.
  navy,
}

/// Visual phase for async submit buttons.
enum AppButtonPhase {
  idle,
  loading,
  success,
}

/// Shared timings for button Lottie success hold-before-navigate.
abstract final class AppButtonLottie {
  /// Matches [loader-success-*.json] (~0.9s) with a short tail.
  static const Duration successHold = Duration(milliseconds: 950);
}

/// Looping compact loader for button children.
class AppButtonLoader extends StatelessWidget {
  const AppButtonLoader({
    super.key,
    required this.tone,
    this.height = 22,
  });

  const AppButtonLoader.white({super.key, this.height = 22})
    : tone = AppButtonLottieTone.white;

  const AppButtonLoader.navy({super.key, this.height = 22})
    : tone = AppButtonLottieTone.navy;

  final AppButtonLottieTone tone;
  final double height;

  String get _asset => switch (tone) {
    AppButtonLottieTone.white => AppAssets.loaderButtonWhiteLottie,
    AppButtonLottieTone.navy => AppAssets.loaderButtonNavyLottie,
  };

  Color get _fallbackColor => switch (tone) {
    AppButtonLottieTone.white => Colors.white,
    AppButtonLottieTone.navy => const Color(0xFF0B2F63),
  };

  @override
  Widget build(BuildContext context) {
    final double width = height * 3;
    return SizedBox(
      width: width,
      height: height,
      child: Lottie.asset(
        _asset,
        width: width,
        height: height,
        fit: BoxFit.contain,
        repeat: true,
        frameRate: FrameRate.max,
        addRepaintBoundary: true,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
          debugPrint('Button loader Lottie failed: $error\n$stackTrace');
          return Center(
            child: SizedBox(
              width: height,
              height: height,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: _fallbackColor,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One-shot success flash for button children (does not loop).
class AppButtonSuccess extends StatelessWidget {
  const AppButtonSuccess({
    super.key,
    required this.tone,
    this.height = 22,
  });

  const AppButtonSuccess.white({super.key, this.height = 22})
    : tone = AppButtonLottieTone.white;

  const AppButtonSuccess.navy({super.key, this.height = 22})
    : tone = AppButtonLottieTone.navy;

  final AppButtonLottieTone tone;
  final double height;

  String get _asset => switch (tone) {
    AppButtonLottieTone.white => AppAssets.loaderSuccessWhiteLottie,
    AppButtonLottieTone.navy => AppAssets.loaderSuccessNavyLottie,
  };

  Color get _fallbackColor => switch (tone) {
    AppButtonLottieTone.white => Colors.white,
    AppButtonLottieTone.navy => const Color(0xFF0B2F63),
  };

  @override
  Widget build(BuildContext context) {
    final double width = height * 3;
    return SizedBox(
      width: width,
      height: height,
      child: Lottie.asset(
        _asset,
        width: width,
        height: height,
        fit: BoxFit.contain,
        repeat: false,
        frameRate: FrameRate.max,
        addRepaintBoundary: true,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
          debugPrint('Button success Lottie failed: $error\n$stackTrace');
          return Icon(Icons.check_rounded, size: height, color: _fallbackColor);
        },
      ),
    );
  }
}

/// Switches a button child between [label], loader, and success Lottie.
class AppAsyncButtonChild extends StatelessWidget {
  const AppAsyncButtonChild({
    super.key,
    required this.phase,
    required this.tone,
    required this.child,
    this.height = 22,
  });

  final AppButtonPhase phase;
  final AppButtonLottieTone tone;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return switch (phase) {
      AppButtonPhase.idle => child,
      AppButtonPhase.loading => AppButtonLoader(tone: tone, height: height),
      AppButtonPhase.success => AppButtonSuccess(tone: tone, height: height),
    };
  }
}
