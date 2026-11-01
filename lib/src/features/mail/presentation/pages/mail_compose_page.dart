import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/mail/data/datasources/mail_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/document_repository.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_compose.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_parse.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/pages/mail_module_page.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/providers/mail_providers.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_attach_repository_dialog.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_message_actions.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_ui_helpers.dart';

class MailComposePage extends ConsumerStatefulWidget {
  const MailComposePage({super.key, this.draftId});

  final int? draftId;

  static const String routeName = 'mail-compose';
  static const String routePath = '/module/mail/compose';

  static String draftPath(int draftId) => '$routePath?draftId=$draftId';

  @override
  ConsumerState<MailComposePage> createState() => _MailComposePageState();
}

class _MailComposePageState extends ConsumerState<MailComposePage> {
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _message = TextEditingController();
  final TextEditingController _correspondence = TextEditingController();
  final TextEditingController _targetDateDisplay = TextEditingController();
  final GlobalKey<_RecipientFieldState> _toFieldKey =
      GlobalKey<_RecipientFieldState>();
  final GlobalKey<_RecipientFieldState> _ccFieldKey =
      GlobalKey<_RecipientFieldState>();
  final GlobalKey<_RecipientFieldState> _bccFieldKey =
      GlobalKey<_RecipientFieldState>();

  final List<String> _to = <String>[];
  final List<String> _cc = <String>[];
  final List<String> _bcc = <String>[];
  final List<String> _tags = <String>[];
  final List<MailComposeAttachment> _localAttachments =
      <MailComposeAttachment>[];
  final List<RepositoryItem> _repoAttachments = <RepositoryItem>[];

  String _category = 'Inspection';
  bool _requiredResponse = true;
  DateTime? _targetDate;
  String _priority = 'NORMAL';
  String _referenceId = '';
  bool _draftApplied = false;
  bool _referenceLoaded = false;
  bool _busy = false;
  int? _threadId;

  static const List<String> _categories = <String>[
    'Inspection',
    'Finance',
    'HR',
    'Projects',
    'Contracts',
  ];

  static const List<String> _suggestedTags = <String>[
    '#Urgent',
    '#Inspection',
    '#Finance',
    '#HR',
    '#Project',
    '#Contract',
    '#Approval',
    '#FollowUp',
    '#Important',
    '#Pending',
    '#Completed',
    '#ActionRequired',
  ];

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadReference());
    });
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    _correspondence.dispose();
    _targetDateDisplay.dispose();
    super.dispose();
  }

  Future<void> _loadReference() async {
    if (_referenceLoaded || widget.draftId != null) {
      return;
    }
    try {
      final String reference =
          await ref.read(mailRemoteDataSourceProvider).generateReference();
      if (!mounted || reference.isEmpty) {
        return;
      }
      setState(() {
        _referenceId = reference;
        _referenceLoaded = true;
      });
    } catch (_) {
      // Keep empty; user can still draft/send if backend accepts blank.
    }
  }

  void _applyDraft(List<MailMessage> items) {
    if (_draftApplied || widget.draftId == null) {
      return;
    }
    MailMessage? match;
    for (final MailMessage item in items) {
      if (item.mailId == widget.draftId) {
        match = item;
        break;
      }
    }
    if (match == null) {
      return;
    }
    _draftApplied = true;
    final MailMessage item = match;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _to
          ..clear()
          ..addAll(item.to);
        _cc
          ..clear()
          ..addAll(item.cc);
        _bcc
          ..clear()
          ..addAll(item.bcc);
        _subject.text = item.subject;
        _message.text = item.body;
        _category = _categories.contains(item.category)
            ? item.category
            : _category;
        _requiredResponse = item.requiredResponse;
        _targetDate = item.targetResponseDate;
        _targetDateDisplay.text = formatMailDatePicker(_targetDate);
        _priority = item.priority.isEmpty ? _priority : item.priority;
        _referenceId = item.referenceId;
        _threadId = item.threadId;
        _tags
          ..clear()
          ..addAll(item.tags.map(_normalizeTag));
        _referenceLoaded = true;
      });
    });
  }

  String _normalizeTag(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    return trimmed.startsWith('#') ? trimmed : '#$trimmed';
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() {
        _targetDate = picked;
        _targetDateDisplay.text = formatMailDatePicker(picked);
      });
    }
  }

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

  Future<void> _attachFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _uploadExtensions,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || !mounted) {
      return;
    }
    for (final PlatformFile file in result.files) {
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
          title: 'Attach File',
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
          title: 'Attach File',
          message: 'Could not read "$name".',
        );
        continue;
      }
      setState(() {
        _localAttachments.add(
          MailComposeAttachment(name: name, path: file.path, bytes: bytes),
        );
      });
    }
  }

  Future<void> _attachFromRepository() async {
    final List<RepositoryItem>? selected =
        await showMailAttachRepositoryDialog(context);
    if (selected == null || selected.isEmpty || !mounted) {
      return;
    }
    setState(() {
      for (final RepositoryItem item in selected) {
        if (_repoAttachments.any((RepositoryItem e) => e.id == item.id)) {
          continue;
        }
        _repoAttachments.add(item);
      }
    });
  }

  MailComposePayload _buildPayload() {
    return MailComposePayload(
      to: List<String>.from(_to),
      cc: List<String>.from(_cc),
      bcc: List<String>.from(_bcc),
      subject: _subject.text.trim(),
      body: _message.text.trim(),
      referenceId: _referenceId.trim(),
      category: _category,
      requiredResponse: _requiredResponse,
      targetResponseDate: _requiredResponse ? _targetDate : null,
      correspondenceLetterNo: _correspondence.text.trim(),
      priority: _priority,
      tags: List<String>.from(_tags),
      repositoryDocumentIds:
          _repoAttachments.map((RepositoryItem e) => e.id).toList(),
      parentMailId: null,
      threadId: _threadId,
    );
  }

  void _commitPendingRecipients() {
    _toFieldKey.currentState?.commitPending();
    _ccFieldKey.currentState?.commitPending();
    _bccFieldKey.currentState?.commitPending();
  }

  String? _validate({required bool forSend}) {
    if (_to.isEmpty) {
      return 'Please add at least one recipient in To.';
    }
    if (_subject.text.trim().isEmpty) {
      return 'Subject is required.';
    }
    if (forSend && _message.text.trim().isEmpty) {
      return 'Message is required.';
    }
    if (_requiredResponse && _targetDate == null) {
      return 'Target response date is required when response is required.';
    }
    return null;
  }

  Future<List<MailComposeAttachment>> _resolvedLocalFiles() async {
    final List<MailComposeAttachment> out = <MailComposeAttachment>[];
    for (final MailComposeAttachment file in _localAttachments) {
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        out.add(file);
        continue;
      }
      final String? path = file.path;
      if (path == null || path.isEmpty) {
        continue;
      }
      final Uint8List bytes = await File(path).readAsBytes();
      if (bytes.isEmpty) {
        continue;
      }
      out.add(MailComposeAttachment(name: file.name, path: path, bytes: bytes));
    }
    return out;
  }

  Future<void> _saveDraft() async {
    _commitPendingRecipients();
    final String? error = _validate(forSend: false);
    if (error != null) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Save Draft',
        message: error,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final List<MailComposeAttachment> files = await _resolvedLocalFiles();
      final String message = await mailSaveDraft(
        ref,
        payload: _buildPayload(),
        files: files,
      );
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Save Draft',
        message: message,
      );
      if (!mounted) {
        return;
      }
      context.go(MailModulePage.folderPath(MailFolder.drafts));
    } catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Save Draft',
        message: mailActionErrorMessage(error),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _send() async {
    _commitPendingRecipients();
    final String? error = _validate(forSend: true);
    if (error != null) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Send',
        message: error,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final List<MailComposeAttachment> files = await _resolvedLocalFiles();
      final String message = await mailSend(
        ref,
        payload: _buildPayload(),
        files: files,
      );
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Send',
        message: message,
      );
      if (!mounted) {
        return;
      }
      // Replace compose with Sent so the new mail is fetched and visible.
      context.go(MailModulePage.folderPath(MailFolder.sent));
    } catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Send',
        message: mailActionErrorMessage(error),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(mailDraftsProvider).whenData(_applyDraft);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose Mail'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: _busy ? null : _saveDraft,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Draft'),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _RecipientField(
                        key: _toFieldKey,
                        label: 'To *',
                        hint: 'Search users or type an email...',
                        helper: 'Example: user1@gmail.com, user2@gmail.com',
                        selected: _to,
                        onChanged: (List<String> value) =>
                            setState(() {
                              _to
                                ..clear()
                                ..addAll(value);
                            }),
                      ),
                      const SizedBox(height: 8),
                      _RecipientField(
                        key: _ccFieldKey,
                        label: 'CC',
                        hint: 'Search users or type an email...',
                        selected: _cc,
                        onChanged: (List<String> value) =>
                            setState(() {
                              _cc
                                ..clear()
                                ..addAll(value);
                            }),
                      ),
                      const SizedBox(height: 8),
                      _RecipientField(
                        key: _bccFieldKey,
                        label: 'BCC',
                        hint: 'Search users or type an email...',
                        selected: _bcc,
                        onChanged: (List<String> value) =>
                            setState(() {
                              _bcc
                                ..clear()
                                ..addAll(value);
                            }),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _subject,
                        decoration: _composeDecoration(
                          label: 'Subject *',
                          hint: 'Enter subject...',
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                          final bool narrow = constraints.maxWidth < 720;
                          final Widget reference = _referenceCard();
                          final Widget correspondence = TextField(
                            controller: _correspondence,
                            decoration: _composeDecoration(
                              label: 'Correspondence Letter No',
                            ),
                          );
                          if (narrow) {
                            return Column(
                              children: <Widget>[
                                reference,
                                const SizedBox(height: 8),
                                correspondence,
                              ],
                            );
                          }
                          return Row(
                            children: <Widget>[
                              Expanded(child: reference),
                              const SizedBox(width: 12),
                              Expanded(child: correspondence),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                          final bool narrow = constraints.maxWidth < 720;
                          if (narrow) {
                            return Column(
                              children: <Widget>[
                                _categoryBlock(),
                                const SizedBox(height: 8),
                                _requiredBlock(),
                                const SizedBox(height: 8),
                                _dateBlock(),
                                const SizedBox(height: 8),
                                _priorityBlock(),
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(child: _categoryBlock()),
                              const SizedBox(width: 12),
                              Expanded(child: _requiredBlock()),
                              const SizedBox(width: 12),
                              Expanded(child: _dateBlock()),
                              const SizedBox(width: 12),
                              Expanded(child: _priorityBlock()),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          FilledButton.icon(
                            onPressed: _busy ? null : _attachFile,
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Attach File'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _attachFromRepository,
                            icon: const Icon(Icons.folder_open_outlined),
                            label: const Text('From Repository'),
                          ),
                        ],
                      ),
                      for (final MailComposeAttachment file
                          in _localAttachments)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading:
                              const Icon(Icons.insert_drive_file_outlined),
                          title: Text(file.name),
                          subtitle: const Text('Local file'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(
                              () => _localAttachments.remove(file),
                            ),
                          ),
                        ),
                      for (final RepositoryItem item in _repoAttachments)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.folder_outlined),
                          title: Text(item.displayName),
                          subtitle: const Text('From repository'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(
                              () => _repoAttachments.remove(item),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: TextField(
                          controller: _message,
                          minLines: 4,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: _composeDecoration(
                            label: 'Message *',
                            hint: 'Type your message here...',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tags / Labels',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: MailTheme.heading(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          for (final String tag in _tags)
                            _composeTagChip(
                              context: context,
                              label: tag,
                              selected: true,
                              onDeleted: () =>
                                  setState(() => _tags.remove(tag)),
                            ),
                          ActionChip(
                            avatar: Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: MailTheme.pillForeground(context),
                            ),
                            label: Text(
                              'Add tag',
                              style: TextStyle(
                                color: MailTheme.pillForeground(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor:
                                MailTheme.tagUnselectedBackground(context),
                            side: BorderSide(
                              color: MailTheme.pillForeground(context)
                                  .withValues(alpha: 0.55),
                            ),
                            onPressed: _busy ? null : _openAddTagSheet,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _composeSendBar(
                busy: _busy,
                onSend: _send,
              ),
            ],
          ),
          if (_busy)
            const ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _composeSendBar({
    required bool busy,
    required VoidCallback onSend,
  }) {
    final AppPalette palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: palette.borderSubtle),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: MailTheme.composePrimaryButton(context),
                foregroundColor: Colors.white,
                // Hug width: theme Size.fromHeight is infinite min width.
                minimumSize: const Size(0, AppTheme.fieldHeight),
              ),
              onPressed: busy ? null : onSend,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Send'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAddTagSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: _ComposeAddTagSheet(
            suggestedTags: _suggestedTags,
            selectedTags: _tags,
            normalizeTag: _normalizeTag,
            onSelectionChanged: () {
              if (mounted) {
                setState(() {});
              }
            },
          ),
        );
      },
    );
  }

  InputDecoration _composeDecoration({
    String? label,
    String? hint,
    Widget? suffixIcon,
    bool alignLabelWithHint = false,
    bool isDense = false,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final BorderRadius radius = BorderRadius.circular(12);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      isDense: isDense,
      filled: true,
      fillColor: palette.fieldFill,
      suffixIcon: suffixIcon,
      floatingLabelBehavior:
          label == null ? FloatingLabelBehavior.never : FloatingLabelBehavior.auto,
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.75),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: isDense ? 12 : 14,
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: MailTheme.muted(context),
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _referenceCard() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: MailTheme.referencePanelBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.tag_rounded, size: 18, color: MailTheme.muted(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Reference / Mail ID (Auto)',
              style: TextStyle(
                color: MailTheme.muted(context),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            _referenceId.isEmpty ? '—' : _referenceId,
            style: TextStyle(
              color: MailTheme.pillForeground(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCategory() async {
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  'Select category',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              for (final String category in _categories)
                ListTile(
                  title: Text(category),
                  trailing: category == _category
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(category),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _category = picked);
    }
  }

  Widget _categoryBlock() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _fieldLabel('Category *'),
        Material(
          color: palette.fieldFill,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _pickCategory,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.75),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _categories.contains(_category)
                          ? _category
                          : _categories.first,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: MailTheme.muted(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _requiredBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _fieldLabel('Required Response *'),
        SegmentedButton<bool>(
          segments: const <ButtonSegment<bool>>[
            ButtonSegment<bool>(
              value: false,
              label: Text('No'),
              icon: Icon(Icons.close_rounded, size: 16),
            ),
            ButtonSegment<bool>(
              value: true,
              label: Text('Yes'),
              icon: Icon(Icons.check_rounded, size: 16),
            ),
          ],
          selected: <bool>{_requiredResponse},
          onSelectionChanged: (Set<bool> next) {
            setState(() => _requiredResponse = next.first);
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.comfortable,
            shape: WidgetStatePropertyAll<OutlinedBorder>(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _fieldLabel('Target Response Date *'),
        TextFormField(
          readOnly: true,
          enabled: _requiredResponse,
          controller: _targetDateDisplay,
          decoration: _composeDecoration(
            hint: 'dd/mm/yyyy',
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          ),
          onTap: _requiredResponse ? _pickDate : null,
        ),
        const SizedBox(height: 6),
        Text(
          'You will be reminded before due date.',
          style: MailTheme.mutedStyle(context, fontSize: 11),
        ),
      ],
    );
  }

  Widget _priorityBlock() {
    const List<String> priorities = <String>['LOW', 'NORMAL', 'HIGH', 'URGENT'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _fieldLabel('Priority'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: priorities.map((String priority) {
            final bool selected = _priority == priority;
            return ChoiceChip(
              label: Text(priority),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => setState(() => _priority = priority),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: selected
                    ? Theme.of(context).colorScheme.onPrimary
                    : MailTheme.heading(context),
              ),
              selectedColor: Theme.of(context).colorScheme.primary,
              backgroundColor: AppPalette.of(context).fieldFill,
              side: BorderSide(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.75),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}

class _RecipientField extends ConsumerStatefulWidget {
  const _RecipientField({
    super.key,
    required this.label,
    required this.hint,
    required this.selected,
    required this.onChanged,
    this.helper,
  });

  final String label;
  final String hint;
  final String? helper;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  ConsumerState<_RecipientField> createState() => _RecipientFieldState();
}

class _RecipientFieldState extends ConsumerState<_RecipientField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _debounce;
  List<MailRecipient> _results = const <MailRecipient>[];
  bool _searching = false;
  bool _showResults = false;
  String? _emptyMessage;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool _looksLikeEmail(String value) {
    final String email = value.trim();
    return email.contains('@') && email.contains('.');
  }

  void commitPending() => _commitTyped();

  void _commitTyped() {
    final String value = _controller.text.trim();
    if (value.isEmpty) {
      return;
    }
    if (!_looksLikeEmail(value)) {
      return;
    }
    _addEmail(value);
  }

  void _addEmail(String email) {
    final String normalized = email.trim();
    if (normalized.isEmpty) {
      return;
    }
    final List<String> next = List<String>.from(widget.selected);
    if (!next.contains(normalized)) {
      next.add(normalized);
      widget.onChanged(next);
    }
    _controller.clear();
    setState(() {
      _results = const <MailRecipient>[];
      _showResults = false;
      _emptyMessage = null;
    });
  }

  void _removeEmail(String email) {
    final List<String> next = List<String>.from(widget.selected)..remove(email);
    widget.onChanged(next);
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final String query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const <MailRecipient>[];
        _showResults = false;
        _emptyMessage = null;
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) {
        return;
      }
      setState(() {
        _searching = true;
        _showResults = true;
      });
      try {
        final List<MailRecipient> found =
            await ref.read(mailRemoteDataSourceProvider).searchRecipients(query);
        if (!mounted || _controller.text.trim() != query) {
          return;
        }
        setState(() {
          _results = found;
          _emptyMessage =
              found.isEmpty ? 'No matching users found' : null;
          _searching = false;
        });
      } catch (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _results = const <MailRecipient>[];
          _emptyMessage = 'No matching users found';
          _searching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final bool focused = _focus.hasFocus;
    final BorderRadius radius = BorderRadius.circular(12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: MailTheme.muted(context),
              letterSpacing: 0.1,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
          decoration: BoxDecoration(
            color: palette.fieldFill,
            borderRadius: radius,
            border: Border.all(
              color: focused
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.75),
              width: focused ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (widget.selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 2, right: 2),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.selected
                        .map(
                          (String email) => InputChip(
                            label: Text(email),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onDeleted: () => _removeEmail(email),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              TextField(
                controller: _controller,
                focusNode: _focus,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  suffixIcon: _looksLikeEmail(_controller.text)
                      ? IconButton(
                          tooltip: 'Add email',
                          icon: Icon(
                            Icons.add_circle_rounded,
                            color: scheme.primary,
                          ),
                          onPressed: _commitTyped,
                        )
                      : Icon(
                          Icons.person_search_rounded,
                          size: 20,
                          color: MailTheme.muted(context),
                        ),
                ),
                onChanged: (String value) {
                  setState(() {});
                  _onQueryChanged(value);
                },
                onSubmitted: (_) {
                  if (_looksLikeEmail(_controller.text)) {
                    _commitTyped();
                  }
                },
              ),
            ],
          ),
        ),
        if (widget.helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              widget.helper!,
              style: MailTheme.mutedStyle(context, fontSize: 11),
            ),
          ),
        if (_showResults) ...<Widget>[
          const SizedBox(height: 6),
          Material(
            elevation: 4,
            color: palette.cardSurface,
            shadowColor: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : _results.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            _emptyMessage ?? 'No matching users found',
                            style: MailTheme.mutedStyle(context),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _results.length,
                          separatorBuilder: (BuildContext context, int index) =>
                              Divider(
                            height: 1,
                            color: scheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            final MailRecipient recipient = _results[index];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: MailTheme.pillBackground(
                                  context,
                                ),
                                foregroundColor: MailTheme.pillForeground(
                                  context,
                                ),
                                child: Text(recipient.initial),
                              ),
                              title: Text(
                                recipient.username.isEmpty
                                    ? recipient.emailId
                                    : recipient.username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                <String>[
                                  if (recipient.userId.isNotEmpty)
                                    recipient.userId,
                                  recipient.emailId,
                                ].join('\n'),
                              ),
                              isThreeLine: recipient.userId.isNotEmpty,
                              onTap: () => _addEmail(recipient.emailId),
                            );
                          },
                        ),
            ),
          ),
        ],
      ],
    );
  }
}

Widget _composeTagChip({
  required BuildContext context,
  required String label,
  required bool selected,
  ValueChanged<bool>? onSelected,
  VoidCallback? onDeleted,
}) {
  final Color selectedBg = MailTheme.tagSelectedBackground(context);
  final Color selectedFg = MailTheme.tagSelectedForeground(context);
  final Color unselectedBg = MailTheme.tagUnselectedBackground(context);
  final Color unselectedFg = MailTheme.tagUnselectedForeground(context);
  final Color selectedBorder = MailTheme.tagSelectedBorder(context);
  final Color unselectedBorder = MailTheme.tagUnselectedBorder(context);

  final WidgetStateProperty<Color?> color =
      WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) {
      return selectedBg;
    }
    return unselectedBg;
  });
  final WidgetStateProperty<BorderSide?> side =
      WidgetStateProperty.resolveWith<BorderSide?>((Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) {
      return BorderSide(color: selectedBorder, width: 1.5);
    }
    return BorderSide(color: unselectedBorder);
  });

  if (onDeleted != null) {
    return InputChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      color: color,
      labelStyle: TextStyle(
        color: selected ? selectedFg : unselectedFg,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: selected
          ? BorderSide(color: selectedBorder, width: 1.5)
          : BorderSide(color: unselectedBorder),
      deleteIconColor: selected ? selectedFg : unselectedFg,
      onDeleted: onDeleted,
    );
  }

  return FilterChip(
    label: Text(label),
    selected: selected,
    showCheckmark: true,
    checkmarkColor: selectedFg,
    color: color,
    labelStyle: TextStyle(
      color: selected ? selectedFg : unselectedFg,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    ),
    side: side.resolve(selected ? <WidgetState>{WidgetState.selected} : const <WidgetState>{}),
    onSelected: onSelected,
  );
}

class _ComposeAddTagSheet extends StatefulWidget {
  const _ComposeAddTagSheet({
    required this.suggestedTags,
    required this.selectedTags,
    required this.normalizeTag,
    required this.onSelectionChanged,
  });

  final List<String> suggestedTags;
  final List<String> selectedTags;
  final String Function(String raw) normalizeTag;
  final VoidCallback onSelectionChanged;

  @override
  State<_ComposeAddTagSheet> createState() => _ComposeAddTagSheetState();
}

class _ComposeAddTagSheetState extends State<_ComposeAddTagSheet> {
  final TextEditingController _search = TextEditingController();
  final TextEditingController _custom = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    _custom.dispose();
    super.dispose();
  }

  void _toggle(String tag, bool selected) {
    setState(() {
      if (selected) {
        if (!widget.selectedTags.contains(tag)) {
          widget.selectedTags.add(tag);
        }
      } else {
        widget.selectedTags.remove(tag);
      }
    });
    widget.onSelectionChanged();
  }

  void _addCustom() {
    final String tag = widget.normalizeTag(_custom.text);
    if (tag.isEmpty || tag == '#') {
      return;
    }
    setState(() {
      if (!widget.selectedTags.contains(tag)) {
        widget.selectedTags.add(tag);
      }
      _custom.clear();
    });
    widget.onSelectionChanged();
  }

  @override
  Widget build(BuildContext context) {
    final String query = _search.text.trim().toLowerCase();
    final List<String> filtered = widget.suggestedTags
        .where(
          (String tag) =>
              query.isEmpty || tag.toLowerCase().contains(query),
        )
        .toList(growable: false);
    final List<String> customSelected = widget.selectedTags
        .where((String tag) => !widget.suggestedTags.contains(tag))
        .toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Add tags',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search tags...',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    for (final String tag in filtered)
                      _composeTagChip(
                        context: context,
                        label: tag,
                        selected: widget.selectedTags.contains(tag),
                        onSelected: (bool value) => _toggle(tag, value),
                      ),
                    for (final String tag in customSelected)
                      _composeTagChip(
                        context: context,
                        label: tag,
                        selected: true,
                        onDeleted: () => _toggle(tag, false),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _custom,
                    decoration: const InputDecoration(
                      hintText: 'Enter new tag...',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addCustom(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, AppTheme.fieldHeight),
                  ),
                  onPressed: _addCustom,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
