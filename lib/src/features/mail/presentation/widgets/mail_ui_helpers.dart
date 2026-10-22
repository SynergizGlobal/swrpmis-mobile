import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';

class MailColors {
  static const Color composeRed = Color(0xFFC1121F);
  static const Color navy = Color(0xFF0B2F63);
  static const Color pillBlue = Color(0xFFE8F0FE);
  static const Color pillBlueText = Color(0xFF1E4F8A);
  static const Color unreadDot = Color(0xFFC1121F);
}

/// Theme-aware tokens for mail UI (light keeps existing SWR mail look).
class MailTheme {
  const MailTheme._();

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static ColorScheme _scheme(BuildContext context) =>
      Theme.of(context).colorScheme;

  static AppPalette _palette(BuildContext context) => AppPalette.of(context);

  static Color heading(BuildContext context) {
    final ColorScheme scheme = _scheme(context);
    return _isDark(context) ? scheme.onSurface : MailColors.navy;
  }

  static Color navIcon(BuildContext context) {
    final ColorScheme scheme = _scheme(context);
    return _isDark(context) ? scheme.primary : MailColors.navy;
  }

  static Color navLabel(BuildContext context) => heading(context);

  static Color selectedNavBackground(BuildContext context) {
    final ColorScheme scheme = _scheme(context);
    return _isDark(context)
        ? scheme.primary.withValues(alpha: 0.14)
        : MailColors.pillBlue.withValues(alpha: 0.65);
  }

  static Color muted(BuildContext context) => _palette(context).mutedText;

  static TextStyle mutedStyle(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return TextStyle(
      color: muted(context),
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  static Color subtleIcon(BuildContext context) =>
      _scheme(context).onSurface.withValues(alpha: 0.55);

  static Color pillBackground(BuildContext context) {
    final ColorScheme scheme = _scheme(context);
    return _isDark(context)
        ? scheme.primary.withValues(alpha: 0.14)
        : MailColors.pillBlue;
  }

  static Color pillForeground(BuildContext context) {
    final ColorScheme scheme = _scheme(context);
    return _isDark(context) ? scheme.primary : MailColors.pillBlueText;
  }

  static Color linkAccent(BuildContext context) => pillForeground(context);

  static Color unreadIndicator(BuildContext context) => _scheme(context).tertiary;

  static Color countBadgeBackground(BuildContext context) {
    final ColorScheme scheme = _scheme(context);
    return _isDark(context) ? scheme.secondary : MailColors.pillBlueText;
  }

  static Color sentBadgeBackground(BuildContext context) =>
      _palette(context).success.withValues(alpha: 0.15);

  static Color sentBadgeForeground(BuildContext context) =>
      _palette(context).success;

  static Color referencePanelBackground(BuildContext context) =>
      _scheme(context).surfaceContainerHighest.withValues(alpha: 0.55);

  static Color borderSubtle(BuildContext context) =>
      _scheme(context).outlineVariant;

  static Color composeSecondaryButton(BuildContext context) {
    final ColorScheme scheme = _scheme(context);
    return _isDark(context) ? scheme.secondary : MailColors.navy;
  }

  static Color composePrimaryButton(BuildContext context) {
    final ColorScheme scheme = _scheme(context);
    return _isDark(context) ? scheme.tertiary : MailColors.composeRed;
  }
}

Widget mailMetaPill(BuildContext context, String label) {
  if (label.trim().isEmpty) {
    return const SizedBox.shrink();
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: MailTheme.pillBackground(context),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: MailTheme.pillForeground(context),
      ),
    ),
  );
}

Widget mailReferencePill(BuildContext context, String referenceId) {
  if (referenceId.trim().isEmpty) {
    return const SizedBox.shrink();
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: MailTheme.pillBackground(context),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      referenceId,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: MailTheme.pillForeground(context),
      ),
    ),
  );
}

Widget mailSentStatusBadge(BuildContext context) {
  final Color fg = MailTheme.sentBadgeForeground(context);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: MailTheme.sentBadgeBackground(context),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.check_circle_outline, size: 14, color: fg),
        const SizedBox(width: 4),
        Text(
          'Sent',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ],
    ),
  );
}

Color parseLabelColor(String hex, {Color? fallback}) {
  final Color resolvedFallback = fallback ?? MailColors.pillBlueText;
  final String raw = hex.trim();
  if (raw.isEmpty) {
    return resolvedFallback;
  }
  final String normalized = raw.startsWith('#') ? raw.substring(1) : raw;
  if (normalized.length == 6) {
    final int? value = int.tryParse('FF$normalized', radix: 16);
    if (value != null) {
      return Color(value);
    }
  }
  return resolvedFallback;
}

InputDecoration mailSearchDecoration({
  required BuildContext context,
  required String hint,
  Widget? suffix,
}) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  final bool isDark = scheme.brightness == Brightness.dark;
  return InputDecoration(
    hintText: hint,
    prefixIcon: const Icon(Icons.search_rounded, size: 20),
    suffixIcon: suffix,
    isDense: true,
    filled: true,
    fillColor: isDark ? AppTheme.cardDark : AppTheme.surfaceLight,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide(color: scheme.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide(color: scheme.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide(color: scheme.primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );
}
