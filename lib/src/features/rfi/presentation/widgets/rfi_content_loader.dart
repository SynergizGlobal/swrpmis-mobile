import 'package:flutter/material.dart';

class RfiContentLoader extends StatelessWidget {
  const RfiContentLoader({super.key, required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 2,
      child: loading
          ? LinearProgressIndicator(
              minHeight: 2,
              color: primary,
              backgroundColor: primary.withValues(alpha: 0.12),
            )
          : const SizedBox.shrink(),
    );
  }
}
