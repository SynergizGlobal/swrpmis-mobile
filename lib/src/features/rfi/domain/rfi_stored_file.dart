class RfiStoredFile {
  const RfiStoredFile._();

  static bool isWindowsPath(String? raw) {
    final String value = _trim(raw);
    if (value.isEmpty) {
      return false;
    }
    final String lower = value.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return false;
    }
    return value.contains(':\\') ||
        RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value);
  }

  static bool isHttpUrl(String? raw) {
    if (isWindowsPath(raw)) {
      return false;
    }
    final String value = _trim(raw).toLowerCase();
    return value.startsWith('http://') || value.startsWith('https://');
  }

  static String fileName(String? raw) {
    final String value = _trim(raw);
    if (value.isEmpty) {
      return '';
    }
    final String normalized = value.replaceAll('\\', '/');
    final int slash = normalized.lastIndexOf('/');
    if (slash < 0 || slash == normalized.length - 1) {
      return value;
    }
    return normalized.substring(slash + 1);
  }

  static bool looksLikePdf(List<int> bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46;
  }

  static bool looksLikeImage(List<int> bytes) {
    if (bytes.length < 4) {
      return false;
    }
    final bool png =
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
    final bool jpeg = bytes[0] == 0xFF && bytes[1] == 0xD8;
    return png || jpeg;
  }

  static String _trim(String? raw) {
    if (raw == null) {
      return '';
    }
    final String text = raw.trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '';
    }
    return text;
  }
}
