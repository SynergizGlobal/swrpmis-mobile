import 'package:flutter/material.dart';

/// Web-style broken / missing site photo placeholder ("Site" + image icon).
class SitePhotoBrokenPlaceholder extends StatelessWidget {
  const SitePhotoBrokenPlaceholder({
    super.key,
    this.label = 'Site',
    this.message = 'Image unavailable',
  });

  final String label;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: cs.onSurfaceVariant.withValues(alpha: 0.75),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
