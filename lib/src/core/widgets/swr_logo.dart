import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/core/constants/app_assets.dart';

class SwrLogo extends StatelessWidget {
  const SwrLogo({
    super.key,
    this.size = 72,
    this.circular = true,
  });

  final double size;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final Widget image = Image.asset(
      AppAssets.logo,
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
      borderRadius: BorderRadius.circular(16),
      child: image,
    );
  }
}
