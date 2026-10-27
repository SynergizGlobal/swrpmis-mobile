import 'package:flutter/foundation.dart';

@immutable
class RepositoryItem {
  const RepositoryItem({
    required this.id,
    required this.documentName,
    required this.fileName,
    required this.filePath,
    required this.category,
    required this.parentId,
    required this.isFolder,
    required this.fileSize,
    required this.mimeType,
  });

  final int id;
  final String documentName;
  final String? fileName;
  final String? filePath;
  final String category;
  final int? parentId;
  final bool isFolder;
  final int? fileSize;
  final String? mimeType;

  String get displayName {
    final String name = documentName.trim();
    if (name.isNotEmpty) {
      return name;
    }
    return (fileName ?? '').trim().isEmpty ? 'Untitled' : fileName!.trim();
  }

  String get sizeLabel {
    final int? bytes = fileSize;
    if (bytes == null || bytes <= 0) {
      return isFolder ? 'Folder' : '—';
    }
    if (bytes < 1024) {
      return '$bytes B';
    }
    final double kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(2)} KB';
    }
    return '${(kb / 1024).toStringAsFixed(2)} MB';
  }
}
