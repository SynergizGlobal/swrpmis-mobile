import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/document_repository.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/providers/mail_providers.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_ui_helpers.dart';

Future<List<RepositoryItem>?> showMailAttachRepositoryDialog(
  BuildContext context,
) {
  return showDialog<List<RepositoryItem>>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => const _AttachRepositoryDialog(),
  );
}

class _FolderCrumb {
  const _FolderCrumb({required this.id, required this.name});

  final int? id;
  final String name;
}

class _AttachRepositoryDialog extends ConsumerStatefulWidget {
  const _AttachRepositoryDialog();

  @override
  ConsumerState<_AttachRepositoryDialog> createState() =>
      _AttachRepositoryDialogState();
}

class _AttachRepositoryDialogState
    extends ConsumerState<_AttachRepositoryDialog> {
  final TextEditingController _search = TextEditingController();
  final List<_FolderCrumb> _crumbs = <_FolderCrumb>[
    const _FolderCrumb(id: null, name: 'My Repository'),
  ];
  final Set<int> _selectedIds = <int>{};
  final Map<int, RepositoryItem> _selectedItems = <int, RepositoryItem>{};

  int? get _folderId => _crumbs.last.id;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openFolder(RepositoryItem folder) {
    setState(() {
      _crumbs.add(_FolderCrumb(id: folder.id, name: folder.displayName));
      _search.clear();
    });
  }

  void _goToCrumb(int index) {
    setState(() {
      _crumbs.removeRange(index + 1, _crumbs.length);
      _search.clear();
    });
  }

  void _toggleFile(RepositoryItem item) {
    setState(() {
      if (_selectedIds.contains(item.id)) {
        _selectedIds.remove(item.id);
        _selectedItems.remove(item.id);
      } else {
        _selectedIds.add(item.id);
        _selectedItems[item.id] = item;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<RepositoryItem>> asyncItems = ref.watch(
      repositoryItemsProvider(_folderId),
    );
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.folder_outlined,
                    color: MailTheme.heading(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Attach from Repository',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: MailTheme.heading(context),
                          ),
                        ),
                        Text(
                          'Select files from your repository',
                          style: MailTheme.mutedStyle(context),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      for (int i = 0; i < _crumbs.length; i++) ...<Widget>[
                        if (i > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: MailTheme.muted(context),
                            ),
                          ),
                        InkWell(
                          onTap: i == _crumbs.length - 1
                              ? null
                              : () => _goToCrumb(i),
                          child: Row(
                            children: <Widget>[
                              if (i == 0)
                                Icon(
                                  Icons.home_outlined,
                                  size: 16,
                                  color: MailTheme.heading(context),
                                ),
                              if (i == 0) const SizedBox(width: 4),
                              Text(
                                _crumbs[i].name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: MailTheme.heading(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _search,
                decoration: mailSearchDecoration(
                  context: context,
                  hint: 'Search files...',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: asyncItems.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, StackTrace _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      error is DioException
                          ? userFriendlyErrorMessage(error)
                          : error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (List<RepositoryItem> items) {
                  final String q = _search.text.trim().toLowerCase();
                  final List<RepositoryItem> filtered = items
                      .where((RepositoryItem item) {
                        if (q.isEmpty) {
                          return true;
                        }
                        return item.displayName.toLowerCase().contains(q) ||
                            (item.fileName ?? '').toLowerCase().contains(q);
                      })
                      .toList(growable: false);
                  if (filtered.isEmpty) {
                    return const Center(child: Text('No files found'));
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (BuildContext context, int index) {
                      final RepositoryItem item = filtered[index];
                      final bool selected = _selectedIds.contains(item.id);
                      return _RepoCard(
                        item: item,
                        selected: selected,
                        onOpenFolder: () => _openFolder(item),
                        onToggle: () => _toggleFile(item),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _selectedIds.isEmpty
                          ? 'Select one or more files'
                          : '${_selectedIds.length} selected',
                      style: MailTheme.mutedStyle(context),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () {
                            Navigator.of(context).pop(
                              _selectedItems.values.toList(growable: false),
                            );
                          },
                    icon: const Icon(Icons.check),
                    label: const Text('Attach'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepoCard extends StatelessWidget {
  const _RepoCard({
    required this.item,
    required this.selected,
    required this.onOpenFolder,
    required this.onToggle,
  });

  final RepositoryItem item;
  final bool selected;
  final VoidCallback onOpenFolder;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: item.isFolder ? onOpenFolder : onToggle,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : MailTheme.borderSubtle(context),
              width: selected ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: MailTheme.borderSubtle(context)),
                    ),
                    child: Icon(
                      item.isFolder
                          ? Icons.folder_outlined
                          : Icons.insert_drive_file_outlined,
                      color: MailTheme.heading(context),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.isFolder ? 'Folder' : item.sizeLabel,
                    style: MailTheme.mutedStyle(context, fontSize: 12),
                  ),
                ],
              ),
              if (!item.isFolder)
                Positioned(
                  top: 0,
                  right: 0,
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: selected,
                      onChanged: (_) => onToggle(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
