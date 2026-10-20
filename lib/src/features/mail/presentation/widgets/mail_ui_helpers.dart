import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';

class MailColors {
  static const Color composeRed = Color(0xFFC1121F);
  static const Color navy = Color(0xFF0B2F63);
  static const Color pillBlue = Color(0xFFE8F0FE);
  static const Color pillBlueText = Color(0xFF1E4F8A);
  static const Color unreadDot = Color(0xFFC1121F);
}

Widget mailMetaPill(String label) {
  if (label.trim().isEmpty) {
    return const SizedBox.shrink();
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: MailColors.pillBlue,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: MailColors.pillBlueText,
      ),
    ),
  );
}

Widget mailReferencePill(String referenceId) {
  if (referenceId.trim().isEmpty) {
    return const SizedBox.shrink();
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: MailColors.pillBlue,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      referenceId,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: MailColors.pillBlueText,
      ),
    ),
  );
}

Widget mailSentStatusBadge() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFD1FAE5),
      borderRadius: BorderRadius.circular(999),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF047857)),
        SizedBox(width: 4),
        Text(
          'Sent',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF047857),
          ),
        ),
      ],
    ),
  );
}

Color parseLabelColor(String hex, {Color fallback = MailColors.pillBlueText}) {
  final String raw = hex.trim();
  if (raw.isEmpty) {
    return fallback;
  }
  final String normalized = raw.startsWith('#') ? raw.substring(1) : raw;
  if (normalized.length == 6) {
    final int? value = int.tryParse('FF$normalized', radix: 16);
    if (value != null) {
      return Color(value);
    }
  }
  return fallback;
}

InputDecoration mailSearchDecoration({
  required String hint,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: const Icon(Icons.search_rounded, size: 20),
    suffixIcon: suffix,
    isDense: true,
    filled: true,
    fillColor: AppTheme.surfaceLight,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide(color: MailColors.navy.withValues(alpha: 0.12)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide(color: MailColors.navy.withValues(alpha: 0.12)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );
}
