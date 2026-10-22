import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_parse.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/providers/mail_providers.dart';
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
  final TextEditingController _to = TextEditingController();
  final TextEditingController _cc = TextEditingController();
  final TextEditingController _bcc = TextEditingController();
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _message = TextEditingController();
  final TextEditingController _newTag = TextEditingController();

  String _category = 'Inspection';
  bool _requiredResponse = true;
  DateTime? _targetDate;
  String _priority = 'NORMAL';
  String _referenceId = '';
  final List<String> _tags = <String>[];
  final List<String> _localAttachments = <String>[];
  bool _draftApplied = false;
  late final TextEditingController _targetDateDisplay = TextEditingController();

  static const List<String> _categories = <String>[
    'Inspection',
    'Contracts',
    'Finance',
    'RDSO Drawing',
    'General',
  ];

  static const List<String> _suggestedTags = <String>[
    'Urgent',
    'Inspection',
    'Finance',
    'HR',
    'Project',
    'Contract',
    'Approval',
    'FollowUp',
    'Important',
    'Pending',
    'Completed',
    'ActionRequired',
  ];

  @override
  void dispose() {
    _to.dispose();
    _cc.dispose();
    _bcc.dispose();
    _subject.dispose();
    _message.dispose();
    _newTag.dispose();
    _targetDateDisplay.dispose();
    super.dispose();
  }

  void _applyDraft(List<MailMessage> items) {
    if (_draftApplied || widget.draftId == null) {
      return;
    }
    for (final MailMessage item in items) {
      if (item.mailId == widget.draftId) {
        _to.text = item.to.join(', ');
        _subject.text = item.subject;
        _message.text = item.body;
        _category = item.category.isEmpty ? _category : item.category;
        _requiredResponse = item.requiredResponse;
        _targetDate = item.targetResponseDate;
        _targetDateDisplay.text = formatMailDatePicker(_targetDate);
        _priority = item.priority.isEmpty ? _priority : item.priority;
        _referenceId = item.referenceId;
        _tags
          ..clear()
          ..addAll(item.tags);
        _draftApplied = true;
        break;
      }
    }
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

  Future<void> _attachFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );
    if (result == null) {
      return;
    }
    setState(() {
      for (final PlatformFile file in result.files) {
        final String name = file.name.trim();
        if (name.isNotEmpty && !_localAttachments.contains(name)) {
          _localAttachments.add(name);
        }
      }
    });
  }

  Future<void> _stubAction(String action) async {
    await AppDialog.show(
      context,
      variant: AppDialogVariant.info,
      title: action,
      message: 'API not available yet.',
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(mailDraftsProvider).whenData(_applyDraft);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose Mail'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () => _stubAction('Save Draft'),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Draft'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _field('To *', _to, hint: 'Enter email addresses separated by comma...'),
            const SizedBox(height: 8),
            _field('CC', _cc, hint: 'Enter CC email addresses...'),
            const SizedBox(height: 8),
            _field('BCC', _bcc, hint: 'Enter BCC email addresses...'),
            const SizedBox(height: 8),
            _field('Subject *', _subject, hint: 'Enter subject...'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: MailTheme.referencePanelBackground(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: <Widget>[
                  const Text('Reference / Mail ID (Auto)'),
                  const Spacer(),
                  Text(
                    _referenceId.isEmpty ? '#MAIL-2026-00268' : _referenceId,
                    style: TextStyle(
                      color: MailTheme.pillForeground(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool narrow = constraints.maxWidth < 720;
                if (narrow) {
                  return Column(
                    children: <Widget>[
                      _categoryBlock(),
                      _requiredBlock(),
                      _dateBlock(),
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
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _attachFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Attach File'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _stubAction('From Repository'),
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('From Repository'),
                ),
              ],
            ),
            for (final String file in _localAttachments)
              ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(file),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      setState(() => _localAttachments.remove(file)),
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
                  label: Text('#$tag'),
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
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final String tag = _newTag.text.trim();
                    if (tag.isEmpty) {
                      return;
                    }
                    setState(() {
                      _tags.add(tag);
                      _newTag.clear();
                    });
                  },
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
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () => _stubAction('Preview'),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Preview'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: MailTheme.composeSecondaryButton(context),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _stubAction('Save Draft'),
                  icon: const Icon(Icons.save),
                  label: const Text('Save Draft'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: MailTheme.composePrimaryButton(context),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _stubAction('Send'),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {String? hint}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
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
                (String c) => DropdownMenuItem<String>(value: c, child: Text(c)),
              )
              .toList(growable: false),
          onChanged: (String? value) {
            if (value != null) {
              setState(() => _category = value);
            }
          },
        ),
        TextButton(
          onPressed: () => _stubAction('New Category'),
          child: const Text('+ New Category'),
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
            title: const Text('No'),
            value: false,
            groupValue: _requiredResponse,
            onChanged: (bool? value) =>
                setState(() => _requiredResponse = value ?? false),
          ),
          RadioListTile<bool>(
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
