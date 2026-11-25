import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_button_lottie.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_fullscreen_loader.dart';
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

  final List<String> _toUserIds = <String>[];
  final List<String> _ccUserIds = <String>[];
  final List<String> _bccUserIds = <String>[];
  final Map<String, MailRecipient> _recipientDirectory =
      <String, MailRecipient>{};
  final List<String> _tags = <String>[];
  final List<MailComposeAttachment> _localAttachments =
      <MailComposeAttachment>[];
  final List<RepositoryItem> _repoAttachments = <RepositoryItem>[];

  String? _projectId;
  String? _contractId;
  String _contractShortName = '';
  String _category = 'Inspection';
  bool _requiredResponse = true;
  DateTime? _targetDate;
  String _priority = 'NORMAL';
  String _referenceId = '';
  bool _draftApplied = false;
  bool _referenceLoaded = false;
  bool _busy = false;
  bool _sendSuccess = false;
  int? _savedDraftId;
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
        _savedDraftId = item.mailId;
        _rememberRecipientsFromIds(item.to);
        _rememberRecipientsFromIds(item.cc);
        _rememberRecipientsFromIds(item.bcc);
        _toUserIds
          ..clear()
          ..addAll(item.to);
        _ccUserIds
          ..clear()
          ..addAll(item.cc);
        _bccUserIds
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

  void _rememberRecipientsFromIds(List<String> ids) {
    for (final String id in ids) {
      final String trimmed = id.trim();
      if (trimmed.isEmpty || _recipientDirectory.containsKey(trimmed)) {
        continue;
      }
      _recipientDirectory[trimmed] = MailRecipient(
        userId: trimmed,
        username: trimmed,
        emailId: '',
      );
    }
  }

  void _rememberRecipient(MailRecipient recipient) {
    final String id = recipient.userId.trim();
    if (id.isEmpty) {
      return;
    }
    _recipientDirectory[id] = recipient;
  }

  void _onProjectChanged(String? projectId) {
    setState(() {
      _projectId = projectId;
      _contractId = null;
      _contractShortName = '';
      _toUserIds.clear();
      _ccUserIds.clear();
      _bccUserIds.clear();
    });
  }

  void _onContractChanged(MailComposeContract? contract) {
    setState(() {
      _contractId = contract?.contractId;
      _contractShortName = contract?.contractShortName.trim() ?? '';
      _toUserIds.clear();
      _ccUserIds.clear();
      _bccUserIds.clear();
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
      toUserIds: List<String>.from(_toUserIds),
      ccUserIds: List<String>.from(_ccUserIds),
      bccUserIds: List<String>.from(_bccUserIds),
      subject: _subject.text.trim(),
      body: _message.text.trim(),
      projectId: (_projectId ?? '').trim(),
      contractId: (_contractId ?? '').trim(),
      contractShortName: _contractShortName.trim(),
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
    if ((_projectId ?? '').trim().isEmpty) {
      return 'Project is required.';
    }
    if ((_contractId ?? '').trim().isEmpty ||
        _contractShortName.trim().isEmpty) {
      return 'Contract is required.';
    }
    if (_toUserIds.isEmpty) {
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
      final MailDraftSaveResult result = await mailSaveDraft(
        ref,
        payload: _buildPayload(),
        files: files,
      );
      if (!mounted) {
        return;
      }
      if (result.draftId != null) {
        _savedDraftId = result.draftId;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Save Draft',
        message: result.message,
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
    setState(() {
      _busy = true;
      _sendSuccess = false;
    });
    try {
      final List<MailComposeAttachment> files = await _resolvedLocalFiles();
      final String message = await mailSend(
        ref,
        payload: _buildPayload(),
        files: files,
        draftId: _savedDraftId ?? widget.draftId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _sendSuccess = true;
      });
      await Future<void>.delayed(AppButtonLottie.successHold);
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
        setState(() {
          _busy = false;
          _sendSuccess = false;
        });
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
                      _projectContractRow(),
                      const SizedBox(height: 8),
                      _RecipientField(
                        key: _toFieldKey,
                        label: 'To *',
                        hint: 'Enter name or email address...',
                        helper:
                            'Select recipients for the chosen contract (user IDs).',
                        selectedUserIds: _toUserIds,
                        directory: _recipientDirectory,
                        contractShortName: _contractShortName,
                        enabled: _contractShortName.isNotEmpty,
                        onChanged: (List<String> value) => setState(() {
                          _toUserIds
                            ..clear()
                            ..addAll(value);
                        }),
                        onRecipientPicked: _rememberRecipient,
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                          final bool narrow = constraints.maxWidth < 520;
                          final Widget cc = _RecipientField(
                            key: _ccFieldKey,
                            label: 'CC',
                            hint: 'Enter CC name or email address...',
                            selectedUserIds: _ccUserIds,
                            directory: _recipientDirectory,
                            contractShortName: _contractShortName,
                            enabled: _contractShortName.isNotEmpty,
                            onChanged: (List<String> value) => setState(() {
                              _ccUserIds
                                ..clear()
                                ..addAll(value);
                            }),
                            onRecipientPicked: _rememberRecipient,
                          );
                          final Widget bcc = _RecipientField(
                            key: _bccFieldKey,
                            label: 'BCC',
                            hint: 'Enter BCC name or email address...',
                            selectedUserIds: _bccUserIds,
                            directory: _recipientDirectory,
                            contractShortName: _contractShortName,
                            enabled: _contractShortName.isNotEmpty,
                            onChanged: (List<String> value) => setState(() {
                              _bccUserIds
                                ..clear()
                                ..addAll(value);
                            }),
                            onRecipientPicked: _rememberRecipient,
                          );
                          if (narrow) {
                            return Column(
                              children: <Widget>[
                                cc,
                                const SizedBox(height: 8),
                                bcc,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(child: cc),
                              const SizedBox(width: 8),
                              Expanded(child: bcc),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _subject,
                        decoration: _composeDecoration(
                          label: 'Subject *',
                          hint: 'Enter subject...',
                        ),
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                          final bool narrow = constraints.maxWidth < 520;
                          final Widget correspondence = TextField(
                            controller: _correspondence,
                            decoration: _composeDecoration(
                              label: 'Correspondence Letter No',
                              hint: 'Search or enter letter number...',
                            ),
                          );
                          if (narrow) {
                            return Column(
                              children: <Widget>[
                                _referenceCard(),
                                const SizedBox(height: 8),
                                correspondence,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(child: _referenceCard()),
                              const SizedBox(width: 8),
                              Expanded(child: correspondence),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                          final bool narrow = constraints.maxWidth < 520;
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
                          return Column(
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(child: _categoryBlock()),
                                  const SizedBox(width: 8),
                                  Expanded(child: _requiredBlock()),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(child: _dateBlock()),
                                  const SizedBox(width: 8),
                                  Expanded(child: _priorityBlock()),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _busy ? null : _attachFile,
                              icon: const Icon(Icons.attach_file, size: 18),
                              label: const Text('Attach File'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  _busy ? null : _attachFromRepository,
                              icon: const Icon(
                                Icons.folder_open_outlined,
                                size: 18,
                              ),
                              label: const Text('From Repository'),
                            ),
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
                success: _sendSuccess,
                onSaveDraft: _saveDraft,
                onSend: _send,
              ),
            ],
          ),
          if (_busy)
            const AppFullscreenLoader.blocking(
              scrimColor: Color(0x33000000),
            ),
        ],
      ),
    );
  }

  Widget _composeSendBar({
    required bool busy,
    required bool success,
    required VoidCallback onSaveDraft,
    required VoidCallback onSend,
  }) {
    final AppPalette palette = AppPalette.of(context);
    final AppButtonPhase phase = success
        ? AppButtonPhase.success
        : busy
        ? AppButtonPhase.loading
        : AppButtonPhase.idle;
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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy || success ? null : onSaveDraft,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save Draft'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: MailTheme.composePrimaryButton(context),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, AppTheme.fieldHeight),
                  ),
                  onPressed: busy || success ? null : onSend,
                  child: AppAsyncButtonChild(
                    phase: phase,
                    tone: AppButtonLottieTone.white,
                    height: 20,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.send_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Send'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
      padding: const EdgeInsets.only(bottom: 6),
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

  Widget _projectContractRow() {
    final AsyncValue<List<MailComposeProject>> projectsAsync =
        ref.watch(mailComposeProjectsProvider);
    final AsyncValue<List<MailComposeContract>> contractsAsync =
        ref.watch(mailComposeContractsProvider(_projectId ?? ''));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: projectsAsync.when(
            loading: () => _dropdownShell(
              label: 'Project *',
              child: const LinearProgressIndicator(minHeight: 2),
            ),
            error: (Object error, StackTrace _) => _dropdownShell(
              label: 'Project *',
              child: Text(
                mailActionErrorMessage(error),
                style: MailTheme.mutedStyle(context, fontSize: 12),
              ),
            ),
            data: (List<MailComposeProject> projects) {
              return _dropdownShell(
                label: 'Project *',
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: projects.any(
                      (MailComposeProject p) => p.projectId == _projectId,
                    )
                        ? _projectId
                        : null,
                    hint: Text(
                      'Select Project',
                      style: MailTheme.mutedStyle(context),
                    ),
                    items: <DropdownMenuItem<String>>[
                      for (final MailComposeProject project in projects)
                        DropdownMenuItem<String>(
                          value: project.projectId,
                          child: Text(
                            project.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _busy ? null : _onProjectChanged,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: contractsAsync.when(
            loading: () => _dropdownShell(
              label: 'Contract *',
              child: const LinearProgressIndicator(minHeight: 2),
            ),
            error: (Object error, StackTrace _) => _dropdownShell(
              label: 'Contract *',
              child: Text(
                mailActionErrorMessage(error),
                style: MailTheme.mutedStyle(context, fontSize: 12),
              ),
            ),
            data: (List<MailComposeContract> contracts) {
              MailComposeContract? selected;
              for (final MailComposeContract contract in contracts) {
                if (contract.contractId == _contractId) {
                  selected = contract;
                  break;
                }
              }
              return _dropdownShell(
                label: 'Contract *',
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selected?.contractId,
                    hint: Text(
                      (_projectId ?? '').isEmpty
                          ? 'Select Project first'
                          : 'Select Contract',
                      style: MailTheme.mutedStyle(context),
                    ),
                    items: <DropdownMenuItem<String>>[
                      for (final MailComposeContract contract in contracts)
                        DropdownMenuItem<String>(
                          value: contract.contractId,
                          child: Text(
                            contract.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _busy || (_projectId ?? '').isEmpty
                        ? null
                        : (String? id) {
                            MailComposeContract? match;
                            for (final MailComposeContract c in contracts) {
                              if (c.contractId == id) {
                                match = c;
                                break;
                              }
                            }
                            _onContractChanged(match);
                          },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _dropdownShell({required String label, required Widget child}) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _fieldLabel(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: palette.fieldFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.75),
            ),
          ),
          child: child,
        ),
      ],
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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Reference / Mail ID (Auto)',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: MailTheme.muted(context),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _referenceId.isEmpty ? '—' : _referenceId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: MailTheme.pillForeground(context),
                fontWeight: FontWeight.w800,
              ),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            ButtonSegment<bool>(value: false, label: Text('No')),
            ButtonSegment<bool>(value: true, label: Text('Yes')),
          ],
          selected: <bool>{_requiredResponse},
          onSelectionChanged: (Set<bool> next) {
            setState(() => _requiredResponse = next.first);
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
    required this.selectedUserIds,
    required this.directory,
    required this.contractShortName,
    required this.onChanged,
    required this.onRecipientPicked,
    this.enabled = true,
    this.helper,
  });

  final String label;
  final String hint;
  final String? helper;
  final bool enabled;
  final List<String> selectedUserIds;
  final Map<String, MailRecipient> directory;
  final String contractShortName;
  final ValueChanged<List<String>> onChanged;
  final ValueChanged<MailRecipient> onRecipientPicked;

  @override
  ConsumerState<_RecipientField> createState() => _RecipientFieldState();
}

class _RecipientFieldState extends ConsumerState<_RecipientField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _showResults = _focus.hasFocus && widget.enabled;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void commitPending() {
    // Selection is from contract recipients only; nothing to commit from free text.
  }

  void _addRecipient(MailRecipient recipient) {
    final String id = recipient.userId.trim();
    if (id.isEmpty) {
      return;
    }
    widget.onRecipientPicked(recipient);
    final List<String> next = List<String>.from(widget.selectedUserIds);
    if (!next.contains(id)) {
      next.add(id);
      widget.onChanged(next);
    }
    _controller.clear();
    setState(() => _showResults = false);
    _focus.unfocus();
  }

  void _removeUserId(String userId) {
    final List<String> next = List<String>.from(widget.selectedUserIds)
      ..remove(userId);
    widget.onChanged(next);
  }

  String _chipLabel(String userId) {
    final MailRecipient? known = widget.directory[userId];
    if (known == null) {
      return userId;
    }
    return known.chipLabel;
  }

  List<MailRecipient> _filtered(List<MailRecipient> all) {
    final String query = _controller.text.trim().toLowerCase();
    final Iterable<MailRecipient> base = all.where(
      (MailRecipient r) => !widget.selectedUserIds.contains(r.userId),
    );
    if (query.isEmpty) {
      return base.toList(growable: false);
    }
    return base
        .where((MailRecipient r) {
          return r.displayName.toLowerCase().contains(query) ||
              r.userId.toLowerCase().contains(query) ||
              r.emailId.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final bool focused = _focus.hasFocus;
    final BorderRadius radius = BorderRadius.circular(12);
    final AsyncValue<List<MailRecipient>> recipientsAsync = ref.watch(
      mailComposeRecipientsProvider(widget.contractShortName),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
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
              if (widget.selectedUserIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 2, right: 2),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.selectedUserIds
                        .map(
                          (String userId) => InputChip(
                            label: Text(_chipLabel(userId)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onDeleted: () => _removeUserId(userId),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              TextField(
                controller: _controller,
                focusNode: _focus,
                enabled: widget.enabled,
                decoration: InputDecoration(
                  hintText: widget.enabled
                      ? widget.hint
                      : 'Select Contract first',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  suffixIcon: Icon(
                    Icons.person_search_rounded,
                    size: 20,
                    color: MailTheme.muted(context),
                  ),
                ),
                onChanged: (_) => setState(() => _showResults = true),
                onTap: () => setState(() => _showResults = widget.enabled),
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
        if (_showResults && widget.enabled) ...<Widget>[
          const SizedBox(height: 6),
          Material(
            elevation: 4,
            color: palette.cardSurface,
            shadowColor: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: recipientsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (Object error, StackTrace _) => Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    mailActionErrorMessage(error),
                    style: MailTheme.mutedStyle(context),
                  ),
                ),
                data: (List<MailRecipient> all) {
                  final List<MailRecipient> results = _filtered(all);
                  if (results.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        all.isEmpty
                            ? 'No recipients for this contract'
                            : 'No matching users found',
                        style: MailTheme.mutedStyle(context),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: results.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        Divider(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final MailRecipient recipient = results[index];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: MailTheme.pillBackground(context),
                          foregroundColor: MailTheme.pillForeground(context),
                          child: Text(recipient.initial),
                        ),
                        title: Text(
                          recipient.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          <String>[
                            if (recipient.userId.isNotEmpty) recipient.userId,
                            if (recipient.emailId.isNotEmpty)
                              recipient.emailId,
                          ].join('\n'),
                        ),
                        isThreeLine: recipient.userId.isNotEmpty &&
                            recipient.emailId.isNotEmpty,
                        onTap: () => _addRecipient(recipient),
                      );
                    },
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
