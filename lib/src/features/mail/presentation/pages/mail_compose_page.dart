import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/mail/data/datasources/mail_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/document_repository.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_compose.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_parse.dart';
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
  final TextEditingController _newTag = TextEditingController();
  final TextEditingController _correspondence = TextEditingController();
  final TextEditingController _targetDateDisplay = TextEditingController();

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
    _newTag.dispose();
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
      context.pop();
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
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _RecipientField(
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
                  decoration: const InputDecoration(
                    labelText: 'Subject *',
                    hintText: 'Enter subject...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool narrow = constraints.maxWidth < 720;
                    final Widget reference = Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: MailTheme.referencePanelBackground(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Expanded(
                            child: Text('Reference / Mail ID (Auto)'),
                          ),
                          Text(
                            _referenceId.isEmpty ? '—' : _referenceId,
                            style: TextStyle(
                              color: MailTheme.pillForeground(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                    final Widget correspondence = TextField(
                      controller: _correspondence,
                      decoration: const InputDecoration(
                        labelText: 'Correspondence Letter No',
                        border: OutlineInputBorder(),
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
                  builder: (BuildContext context, BoxConstraints constraints) {
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
                for (final MailComposeAttachment file in _localAttachments)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.insert_drive_file_outlined),
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
                TextField(
                  controller: _message,
                  minLines: 8,
                  maxLines: 16,
                  decoration: const InputDecoration(
                    labelText: 'Message *',
                    hintText: 'Type your message here...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tags / Labels',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _suggestedTags.map((String tag) {
                    final bool selected = _tags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: selected,
                      onSelected: (bool value) {
                        setState(() {
                          if (value) {
                            _tags.add(tag);
                          } else {
                            _tags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(growable: false),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _newTag,
                        decoration: const InputDecoration(
                          hintText: 'Enter new tag...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addCustomTag(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _addCustomTag,
                      child: const Text('+ Add Tag'),
                    ),
                  ],
                ),
                if (_tags.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'No tags added',
                      style: MailTheme.mutedStyle(context),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _tags
                          .where((String t) => !_suggestedTags.contains(t))
                          .map(
                            (String tag) => InputChip(
                              label: Text(tag),
                              onDeleted: () =>
                                  setState(() => _tags.remove(tag)),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            MailTheme.composeSecondaryButton(context),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _busy ? null : _saveDraft,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Draft'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            MailTheme.composePrimaryButton(context),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _busy ? null : _send,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Send'),
                    ),
                  ],
                ),
              ],
            ),
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

  void _addCustomTag() {
    final String tag = _normalizeTag(_newTag.text);
    if (tag.isEmpty || tag == '#') {
      return;
    }
    setState(() {
      if (!_tags.contains(tag)) {
        _tags.add(tag);
      }
      _newTag.clear();
    });
  }

  Widget _categoryBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DropdownButtonFormField<String>(
          value: _categories.contains(_category) ? _category : _categories.first,
          decoration: const InputDecoration(
            labelText: 'Category *',
            border: OutlineInputBorder(),
          ),
          items: _categories
              .map(
                (String c) =>
                    DropdownMenuItem<String>(value: c, child: Text(c)),
              )
              .toList(growable: false),
          onChanged: (String? value) {
            if (value != null) {
              setState(() => _category = value);
            }
          },
        ),
      ],
    );
  }

  Widget _requiredBlock() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Required Response *',
        border: OutlineInputBorder(),
      ),
      child: Column(
        children: <Widget>[
          RadioListTile<bool>(
            dense: true,
            title: const Text('No'),
            value: false,
            groupValue: _requiredResponse,
            onChanged: (bool? value) =>
                setState(() => _requiredResponse = value ?? false),
          ),
          RadioListTile<bool>(
            dense: true,
            title: const Text('Yes'),
            value: true,
            groupValue: _requiredResponse,
            onChanged: (bool? value) =>
                setState(() => _requiredResponse = value ?? true),
          ),
        ],
      ),
    );
  }

  Widget _dateBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextFormField(
          readOnly: true,
          controller: _targetDateDisplay,
          decoration: const InputDecoration(
            labelText: 'Target Response Date *',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today_outlined),
            hintText: 'dd/mm/yyyy',
          ),
          onTap: _requiredResponse ? _pickDate : null,
        ),
        Text(
          'You will be reminded before due date.',
          style: MailTheme.mutedStyle(context, fontSize: 11),
        ),
      ],
    );
  }

  Widget _priorityBlock() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Priority',
        border: OutlineInputBorder(),
      ),
      child: Column(
        children: <String>['LOW', 'NORMAL', 'HIGH', 'URGENT'].map((String p) {
          return RadioListTile<String>(
            dense: true,
            title: Text(p),
            value: p,
            groupValue: _priority,
            onChanged: (String? value) =>
                setState(() => _priority = value ?? 'NORMAL'),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _RecipientField extends ConsumerStatefulWidget {
  const _RecipientField({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InputDecorator(
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            helperText: widget.helper,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (widget.selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.selected
                        .map(
                          (String email) => InputChip(
                            label: Text(email),
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
                  isDense: true,
                  suffixIcon: _looksLikeEmail(_controller.text)
                      ? IconButton(
                          tooltip: 'Add email',
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _commitTyped,
                        )
                      : null,
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
        if (_showResults)
          Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(8),
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
                              const Divider(height: 1),
                          itemBuilder: (BuildContext context, int index) {
                            final MailRecipient recipient = _results[index];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
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
    );
  }
}
