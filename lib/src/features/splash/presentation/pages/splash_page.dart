import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/constants/app_assets.dart';
import 'package:swr_pmis_mobile/src/core/widgets/swr_logo.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/pages/login_page.dart';
import 'package:swr_pmis_mobile/src/features/dashboard/presentation/home/home_page.dart';

/// Flutter splash shown after the native launch screen.
///
/// Plays [AppAssets.splashLottie] for at least one full cycle while auth
/// bootstrap runs, then routes to login or home.
///
/// Important: do **not** show [SwrLogo] while the composition is still loading.
/// That PNG includes "SWR PMIS" text and is identical to the native splash mark,
/// so a loading/fallback-as-logo path looks like the Lottie never ran.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  static const String routeName = 'splash';
  static const String routePath = '/splash';

  /// Matches [train-check-logo.json] (240 frames @ 60fps).
  static const Duration animationDuration = Duration(seconds: 4);

  /// Used when Lottie fails so the splash still feels intentional.
  static const Duration fallbackMinDuration = Duration(milliseconds: 1200);

  /// Never block forever on a hung auth/network call.
  static const Duration authTimeout = Duration(seconds: 12);

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lottieController;
  LottieComposition? _composition;
  bool _lottieFailed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  Future<void> _bootstrap() async {
    final Future<void> authFuture = _runAuthBootstrap();
    final Future<void> visualFuture = _prepareAndPlayVisual();

    await Future.wait<void>(<Future<void>>[authFuture, visualFuture]);
    await _goNext();
  }

  Future<void> _runAuthBootstrap() async {
    try {
      await ref
          .read(authControllerProvider.notifier)
          .tryAutoLoginIfRemembered()
          .timeout(SplashPage.authTimeout);
    } catch (_) {
      // Splash must continue even if remember-me login fails or times out.
    }
  }

  Future<void> _prepareAndPlayVisual() async {
    try {
      final LottieComposition composition = await AssetLottie(
        AppAssets.splashLottie,
      ).load().timeout(const Duration(seconds: 5));
      if (!mounted) {
        return;
      }

      final Duration playDuration =
          composition.duration <= Duration.zero
          ? SplashPage.animationDuration
          : composition.duration;

      _lottieController.duration = playDuration;
      setState(() {
        _composition = composition;
        _lottieFailed = false;
      });

      // Ensure [Lottie] is mounted and listening before the controller moves.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }

      _lottieController.reset();
      await _lottieController.forward();
    } catch (error, stackTrace) {
      debugPrint('Splash Lottie failed: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      setState(() {
        _lottieFailed = true;
        _composition = null;
      });
      await Future<void>.delayed(SplashPage.fallbackMinDuration);
    }
  }

  Future<void> _goNext() async {
    if (!mounted || _navigated) {
      return;
    }
    _navigated = true;
    final bool loggedIn =
        ref.read(authControllerProvider).valueOrNull != null;
    if (loggedIn) {
      context.goNamed(HomePage.routeName);
    } else {
      context.goNamed(LoginPage.routeName);
    }
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppTheme.brandPrimary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppTheme.brandPrimary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.brandPrimary,
        body: ColoredBox(
          color: AppTheme.brandPrimary,
          child: Center(child: _buildSplashVisual()),
        ),
      ),
    );
  }

  Widget _buildSplashVisual() {
    if (_lottieFailed) {
      return const SwrLogo(size: 168, variant: SwrLogoVariant.full);
    }

    final LottieComposition? composition = _composition;
    if (composition == null) {
      // Hold solid navy while the asset parses — never flash the static PNG
      // that looks identical to the native launch mark.
      return const SizedBox(width: 280, height: 280);
    }

    return Lottie(
      composition: composition,
      controller: _lottieController,
      width: 280,
      height: 280,
      fit: BoxFit.contain,
      frameRate: FrameRate.max,
      addRepaintBoundary: true,
    );
  }
}
