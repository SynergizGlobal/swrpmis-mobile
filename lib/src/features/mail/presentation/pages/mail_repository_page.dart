import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_list_scaffold.dart';
import 'package:swr_pmis_mobile/src/features/mail/data/datasources/document_repository_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/document_repository.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/providers/mail_providers.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_ui_helpers.dart';

class _RepoBreadcrumb {
  const _RepoBreadcrumb({required this.id, required this.name});

  final int? id;
  final String name;
}

class MailRepositoryPage extends ConsumerStatefulWidget {
  const MailRepositoryPage({
    super.key,
    this.folderId,
    this.folderName,
    this.embedded = false,
  });

  final int? folderId;
  final String? folderName;
  final bool embedded;

  static const String routeName = 'mail-repository';
  static const String routePath = '/module/mail/repository';

  @override
  ConsumerState<MailRepositoryPage> createState() => _MailRepositoryPageState();
}

class _MailRepositoryPageState extends ConsumerState<MailRepositoryPage> {
  final TextEditingController _search = TextEditingController();
  late List<_RepoBreadcrumb> _trail;
  bool _busy = false;

  int? get _folderId => _trail.last.id;

  String get _title {
    final String name = _trail.last.name.trim();
    return name.isEmpty ? 'My Repository' : name;
  }

  @override
  void initState() {
    super.initState();
    _trail = <_RepoBreadcrumb>[
      const _RepoBreadcrumb(id: null, name: 'My Repository'),
    ];
    if (widget.folderId != null) {
      _trail.add(
        _RepoBreadcrumb(
          id: widget.folderId,
          name: (widget.folderName ?? 'Folder').trim(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    ref.invalidate(repositoryItemsProvider(_folderId));
  }

  Future<String?> _promptName({
    required String title,
    required String subtitle,
    required String label,
    String initial = '',
    required String confirmLabel,
    required IconData confirmIcon,
  }) async {
    final TextEditingController name = TextEditingController(text: initial);
    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(subtitle, style: MailTheme.mutedStyle(context)),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                autofocus: true,
                decoration: InputDecoration(labelText: label),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, name.text.trim()),
              icon: Icon(confirmIcon, size: 18),
              label: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    name.dispose();
    return value;
  }

  Future<void> _createFolder() async {
    final String parentName = _title;
    final String? value = await _promptName(
      title: 'New Folder',
      subtitle: _folderId == null
          ? 'Create a folder in My Repository'
          : 'Create a folder in $parentName',
      label: 'Folder Name',
      confirmLabel: 'Create Folder',
      confirmIcon: Icons.create_new_folder_outlined,
    );
    if (value == null || value.isEmpty || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(documentRepositoryRemoteDataSourceProvider).createFolder(
        folderName: value,
        parentId: _folderId,
      );
      await _reload();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'New Folder',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  static const List<String> _uploadExtensions = <String>[
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'csv',
    'rtf',
    'odt',
    'ods',
    'zip',
  ];

  Future<Uint8List?> _fileBytes(PlatformFile file) async {
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return file.bytes;
    }
    final String? path = file.path;
    if (path == null || path.isEmpty) {
      return null;
    }
    return File(path).readAsBytes();
  }

  Future<void> _upload() async {
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _uploadExtensions,
      withData: true,
      allowMultiple: true,
    );
    if (picked == null || picked.files.isEmpty || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      for (final PlatformFile file in picked.files) {
        final String name = file.name.trim();
        if (name.isEmpty) {
          continue;
        }
        final String ext = name.contains('.')
            ? name.split('.').last.toLowerCase()
            : '';
        if (ext.isEmpty || !_uploadExtensions.contains(ext)) {
          if (!mounted) {
            return;
          }
          await AppDialog.show(
            context,
            variant: AppDialogVariant.warning,
            title: 'Upload',
            message:
                'Unsupported file type for "$name". Allowed: PDF, images, Word, Excel, PowerPoint, text, and ZIP.',
          );
          continue;
        }
        final Uint8List? bytes = await _fileBytes(file);
        if (bytes == null || bytes.isEmpty) {
          if (!mounted) {
            return;
          }
          await AppDialog.show(
            context,
            variant: AppDialogVariant.error,
            title: 'Upload',
            message: 'Could not read "$name".',
          );
          continue;
        }
        await ref.read(documentRepositoryRemoteDataSourceProvider).uploadFile(
          fileName: name,
          bytes: bytes,
          parentId: _folderId,
        );
      }
      await _reload();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Upload',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _rename(RepositoryItem item) async {
    final String? value = await _promptName(
      title: 'Rename',
      subtitle: 'Enter the new name',
      label: 'Name',
      initial: item.displayName,
      confirmLabel: 'Rename',
      confirmIcon: Icons.edit_outlined,
    );
    if (value == null ||
        value.isEmpty ||
        value == item.displayName ||
        !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(documentRepositoryRemoteDataSourceProvider)
          .rename(id: item.id, newName: value);
      if (item.isFolder) {
        setState(() {
          _trail = _trail
              .map(
                (_RepoBreadcrumb crumb) => crumb.id == item.id
                    ? _RepoBreadcrumb(id: crumb.id, name: value)
                    : crumb,
              )
              .toList(growable: false);
        });
      }
      await _reload();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Rename',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _delete(RepositoryItem item) async {
    final bool ok = await AppDialog.confirm(
      context,
      title: 'Delete Item',
      message: 'Are you sure you want to delete ${item.displayName}?',
      primaryLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(documentRepositoryRemoteDataSourceProvider)
          .delete(id: item.id);
      await _reload();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Delete',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _download(RepositoryItem item) async {
    setState(() => _busy = true);
    try {
      final Uint8List bytes = await ref
          .read(documentRepositoryRemoteDataSourceProvider)
          .download(id: item.id);
      if (!mounted || bytes.isEmpty) {
        return;
      }
      final Directory dir = await getTemporaryDirectory();
      final String safe = item.displayName.replaceAll(
        RegExp(r'[^A-Za-z0-9._-]'),
        '_',
      );
      final File file = File('${dir.path}/$safe');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) {
        return;
      }
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      final Rect? origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path, name: item.displayName)],
          sharePositionOrigin: origin,
        ),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Download',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _openFolder(RepositoryItem item) {
    setState(() {
      _search.clear();
      _trail = <_RepoBreadcrumb>[
        ..._trail,
        _RepoBreadcrumb(id: item.id, name: item.displayName),
      ];
    });
  }

  void _goBreadcrumb(int index) {
    if (index < 0 || index >= _trail.length || index == _trail.length - 1) {
      return;
    }
    setState(() {
      _search.clear();
      _trail = _trail.sublist(0, index + 1);
    });
  }

  Widget _body(AsyncValue<List<RepositoryItem>> async) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_busy) const LinearProgressIndicator(minHeight: 2),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (!widget.embedded)
                Text(
                  _title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: MailTheme.heading(context),
                  ),
                ),
              Text(
                'Store and manage your documents and files.',
                style: MailTheme.mutedStyle(context),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _createFolder,
                    icon: const Icon(Icons.create_new_folder_outlined),
                    label: const Text('New Folder'),
                  ),
                  FilledButton.icon(
                    onPressed: _busy ? null : _upload,
                    icon: const Icon(Icons.upload_rounded),
                    label: const Text('Upload Files'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    for (int i = 0; i < _trail.length; i++) ...<Widget>[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: MailTheme.mutedStyle(context).color,
                          ),
                        ),
                      InkWell(
                        onTap: i == _trail.length - 1
                            ? null
                            : () => _goBreadcrumb(i),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Row(
                            children: <Widget>[
                              if (i == 0)
                                Icon(
                                  Icons.home_outlined,
                                  size: 16,
                                  color: MailTheme.navIcon(context),
                                ),
                              if (i == 0) const SizedBox(width: 4),
                              Text(
                                _trail[i].name,
                                style: TextStyle(
                                  fontWeight: i == _trail.length - 1
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: MailTheme.navLabel(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _search,
                      decoration: mailSearchDecoration(
                        context: context,
                        hint: 'Search files and folders...',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    async.maybeWhen(
                      data: (List<RepositoryItem> items) {
                        final String q = _search.text.trim().toLowerCase();
                        final int count = items
                            .where(
                              (RepositoryItem item) =>
                                  q.isEmpty ||
                                  item.displayName.toLowerCase().contains(q),
                            )
                            .length;
                        return count == 1 ? '1 item' : '$count items';
                      },
                      orElse: () => '',
                    ),
                    style: MailTheme.mutedStyle(context, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      error is DioException
                          ? userFriendlyErrorMessage(error)
                          : error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (List<RepositoryItem> items) {
              final String q = _search.text.trim().toLowerCase();
              final List<RepositoryItem> visible = items
                  .where(
                    (RepositoryItem item) =>
                        q.isEmpty ||
                        item.displayName.toLowerCase().contains(q),
                  )
                  .toList(growable: false);
              if (visible.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.folder_open_outlined,
                          size: 56,
                          color: MailTheme.pillForeground(context),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'This folder is empty',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Upload files or create a folder to get started.',
                          style: MailTheme.mutedStyle(context),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: <Widget>[
                            OutlinedButton.icon(
                              onPressed: _busy ? null : _createFolder,
                              icon: const Icon(Icons.create_new_folder_outlined),
                              label: const Text('New Folder'),
                            ),
                            FilledButton.icon(
                              onPressed: _busy ? null : _upload,
                              icon: const Icon(Icons.upload_rounded),
                              label: const Text('Upload Files'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _reload,
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (BuildContext context, int index) {
                    final RepositoryItem item = visible[index];
                    return _RepoCard(
                      item: item,
                      onOpen: item.isFolder ? () => _openFolder(item) : null,
                      onDownload:
                          item.isFolder ? null : () => _download(item),
                      onRename: () => _rename(item),
                      onDelete: () => _delete(item),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<RepositoryItem>> async = ref.watch(
      repositoryItemsProvider(_folderId),
    );
    if (widget.embedded) {
      return _body(async);
    }
    return AppListScaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            onPressed: _busy ? null : _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _body(async),
    );
  }
}

class _RepoCard extends StatelessWidget {
  const _RepoCard({
    required this.item,
    required this.onRename,
    required this.onDelete,
    this.onOpen,
    this.onDownload,
  });

  final RepositoryItem item;
  final VoidCallback? onOpen;
  final VoidCallback? onDownload;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: CircleAvatar(
                      backgroundColor: MailTheme.pillBackground(context),
                      child: Icon(
                        item.isFolder
                            ? Icons.folder_rounded
                            : Icons.insert_drive_file_outlined,
                        color: MailTheme.pillForeground(context),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (String value) {
                      switch (value) {
                        case 'download':
                          onDownload?.call();
                        case 'rename':
                          onRename();
                        case 'delete':
                          onDelete();
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      if (onDownload != null)
                        const PopupMenuItem<String>(
                          value: 'download',
                          child: Text('Download'),
                        ),
                      const PopupMenuItem<String>(
                        value: 'rename',
                        child: Text('Rename'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Text(
                item.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                item.sizeLabel,
                style: MailTheme.mutedStyle(context, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
