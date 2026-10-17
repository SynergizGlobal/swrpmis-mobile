import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/core/constants/app_assets.dart';

enum SwrLogoVariant {
  /// Graphic + "SWR PMIS" text.
  full,

  /// Graphic only (no text).
  mark,
}

class SwrLogo extends StatelessWidget {
  const SwrLogo({
    super.key,
    this.size = 72,
    this.circular = false,
    this.variant = SwrLogoVariant.full,
  });

  final double size;

  /// Legacy circular crop for the old round emblem. The display mark is square.
  final bool circular;

  final SwrLogoVariant variant;

  @override
  Widget build(BuildContext context) {
    final String asset = variant == SwrLogoVariant.mark
        ? AppAssets.markLogo
        : AppAssets.logo;
    final Widget image = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Icon(
        Icons.account_balance_rounded,
        size: size * 0.55,
        color: Theme.of(context).colorScheme.primary,
      ),
    );

    if (circular) {
      return ClipOval(child: image);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: image,
    );
  }
}
