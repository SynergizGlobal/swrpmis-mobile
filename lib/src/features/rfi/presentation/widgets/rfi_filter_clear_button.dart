import 'package:flutter/material.dart';

class RfiFilterClearButton extends StatelessWidget {
  const RfiFilterClearButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return OutlinedButton(
      style: ButtonStyle(
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const WidgetStatePropertyAll<Size>(Size(72, 40)),
        padding: const WidgetStatePropertyAll<EdgeInsets>(
          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return accent.withValues(alpha: 0.45);
          }
          return accent;
        }),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return accent.withValues(alpha: 0.06);
          }
          return accent.withValues(alpha: 0.14);
        }),
        side: WidgetStateProperty.resolveWith<BorderSide>((
          Set<WidgetState> states,
        ) {
          final Color color = states.contains(WidgetState.disabled)
              ? accent.withValues(alpha: 0.45)
              : accent;
          return BorderSide(color: color, width: 1.5);
        }),
        textStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        shape: const WidgetStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
      onPressed: onPressed,
      child: const Text('Clear'),
    );
  }
}
