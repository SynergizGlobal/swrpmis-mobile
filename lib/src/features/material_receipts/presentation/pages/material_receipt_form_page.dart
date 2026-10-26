import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/data/datasources/material_receipt_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/data/material_receipt_excel_import.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_detail.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_form.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_list.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_parse.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_field.dart';

class MaterialReceiptFormPage extends ConsumerStatefulWidget {
  const MaterialReceiptFormPage({super.key, this.receiptId = ''});

  final String receiptId;

  static const String routeNameAdd = 'forms-quality-add';
  static const String routePathAdd = '/module/quality/material-receipts/add';
  static const String routeNameEdit = 'forms-quality-detail';

  static String locationAdd() => routePathAdd;

  static String locationFor(String receiptId) {
    return '/module/quality/material-receipts/receipt/'
        '${Uri.encodeComponent(receiptId.trim())}';
  }

  @override
  ConsumerState<MaterialReceiptFormPage> createState() =>
      _MaterialReceiptFormPageState();
}

class _MaterialReceiptFormPageState
    extends ConsumerState<MaterialReceiptFormPage> {
  final TextEditingController _supplier = TextEditingController();
  final TextEditingController _batch = TextEditingController();
  final TextEditingController _invoice = TextEditingController();
  final TextEditingController _vehicle = TextEditingController();
  final TextEditingController _remarks = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _busyTemplate = false;
  bool _busyImport = false;
  Object? _error;

  String _receiptId = '';
  String _status = '';
  String _projectId = '';
  String _sectionId = '';
  String _contractId = '';
  DateTime? _deliveryDate;

  MaterialReceiptFormCatalog _catalog = const MaterialReceiptFormCatalog();
  List<MaterialReceiptFormItemDraft> _items = <MaterialReceiptFormItemDraft>[
    MaterialReceiptFormItemDraft(),
  ];
  List<MaterialReceiptChecklistDoc> _docs = <MaterialReceiptChecklistDoc>[];
  String _docsHint = 'Select a material to load its document checklist.';

  MaterialReceiptRemoteDataSource get _source =>
      ref.read(materialReceiptRemoteDataSourceProvider);

  MaterialReceiptFormMode get _mode =>
      materialReceiptFormModeForStatus(_status.isEmpty && _receiptId.isEmpty
          ? null
          : _status);

  bool get _readOnly => _mode == MaterialReceiptFormMode.view;

  bool get _lockProject =>
      _readOnly || materialReceiptLocksProjectFields(_status);

  bool get _showEngrColumns =>
      _status.trim().toUpperCase() == 'PENDING_REVIEW' ||
      _status.trim().toUpperCase() == 'ACCEPTED';

  @override
  void initState() {
    super.initState();
    _receiptId = widget.receiptId.trim();
    Future<void>.microtask(_bootstrap);
  }

  @override
  void dispose() {
    _supplier.dispose();
    _batch.dispose();
    _invoice.dispose();
    _vehicle.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<MaterialReceiptOption> projects = await _source
          .fetchDropdownProjects();
      final List<MaterialReceiptOption> materials = await _source
          .fetchDropdownMaterials();
      MaterialReceiptDetail? detail;
      if (_receiptId.isNotEmpty) {
        detail = await _source.fetchDetail(_receiptId);
      }
      List<MaterialReceiptOption> sections = const <MaterialReceiptOption>[];
      List<MaterialReceiptOption> contracts = const <MaterialReceiptOption>[];
      if ((detail?.projectId ?? '').isNotEmpty) {
        sections = await _source.fetchDropdownSections(detail!.projectId);
        contracts = await _source.fetchDropdownContracts(detail.projectId);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _catalog = MaterialReceiptFormCatalog(
          projects: projects,
          materials: materials,
          sections: sections,
          contracts: contracts,
        );
        if (detail != null) {
          _seedFromDetail(detail);
        }
        _loading = false;
      });
      if (detail != null) {
        await _refreshChecklist(mergeExisting: detail.documents);
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  void _seedFromDetail(MaterialReceiptDetail detail) {
    _receiptId = detail.receiptId;
    _status = detail.status;
    _projectId = detail.projectId;
    _sectionId = detail.sectionId;
    _contractId = detail.contractId;
    _supplier.text = detail.sourceSupplier;
    _batch.text = detail.batchLotNo;
    _invoice.text = detail.invoiceNo;
    _vehicle.text = detail.vehicleChallanNo;
    _remarks.text = detail.remarks;
    _deliveryDate = _parseUiDate(materialReceiptUiDateFromApi(detail.deliveryDate));
    _items = detail.items.isEmpty
        ? <MaterialReceiptFormItemDraft>[MaterialReceiptFormItemDraft()]
        : detail.items
              .map(MaterialReceiptFormItemDraft.fromDetail)
              .toList(growable: true);
  }

  Future<void> _onProjectChanged(String? projectId) async {
    final String next = (projectId ?? '').trim();
    setState(() {
      _projectId = next;
      _sectionId = '';
      _contractId = '';
      _catalog = _catalog.copyWith(
        sections: const <MaterialReceiptOption>[],
        contracts: const <MaterialReceiptOption>[],
      );
    });
    if (next.isEmpty) {
      return;
    }
    try {
      final List<List<MaterialReceiptOption>> loaded =
          await Future.wait<List<MaterialReceiptOption>>(
            <Future<List<MaterialReceiptOption>>>[
              _source.fetchDropdownSections(next),
              _source.fetchDropdownContracts(next),
            ],
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _catalog = _catalog.copyWith(
          sections: loaded[0],
          contracts: loaded[1],
        );
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Filters',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : 'Unable to load sections/contracts.',
      );
    }
  }

  Future<void> _refreshChecklist({
    List<MaterialReceiptDocument> mergeExisting =
        const <MaterialReceiptDocument>[],
  }) async {
    final List<String> names = _items
        .map((MaterialReceiptFormItemDraft item) => item.materialName.trim())
        .where((String name) => name.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (names.isEmpty) {
      setState(() {
        _docs = <MaterialReceiptChecklistDoc>[];
        _docsHint = 'Select a material to load its document checklist.';
      });
      return;
    }
    try {
      final List<MaterialReceiptChecklistDoc> checklist = await _source
          .fetchDocumentsByMaterial(names);
      final Map<String, MaterialReceiptDocument> existingByType =
          <String, MaterialReceiptDocument>{
            for (final MaterialReceiptDocument doc in mergeExisting)
              if (doc.docType.trim().isNotEmpty)
                doc.docType.trim().toLowerCase(): doc,
          };
      // Keep locally uploaded files across refreshes.
      final Map<String, MaterialReceiptChecklistDoc> previous =
          <String, MaterialReceiptChecklistDoc>{
            for (final MaterialReceiptChecklistDoc doc in _docs)
              doc.documentName.trim().toLowerCase(): doc,
          };
      final List<MaterialReceiptChecklistDoc> next =
          <MaterialReceiptChecklistDoc>[];
      if (checklist.isEmpty && existingByType.isNotEmpty) {
        for (final MaterialReceiptDocument doc in mergeExisting) {
          final MaterialReceiptChecklistDoc? prev =
              previous[doc.docType.trim().toLowerCase()];
          next.add(
            MaterialReceiptChecklistDoc(
              documentName: doc.docType,
              mandatory: true,
              docId: doc.docId,
              existingFileName: doc.fileName,
              localPath: prev?.localPath,
              localFileName: prev?.localFileName ?? '',
            ),
          );
        }
      } else {
        for (final MaterialReceiptChecklistDoc doc in checklist) {
          final String key = doc.documentName.trim().toLowerCase();
          final MaterialReceiptDocument? existing = existingByType[key];
          final MaterialReceiptChecklistDoc? prev = previous[key];
          next.add(
            MaterialReceiptChecklistDoc(
              documentId: doc.documentId,
              documentName: doc.documentName,
              mandatory: doc.mandatory,
              docId: existing?.docId ?? prev?.docId,
              existingFileName: existing?.fileName ?? prev?.existingFileName ?? '',
              localPath: prev?.localPath,
              localFileName: prev?.localFileName ?? '',
            ),
          );
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _docs = next;
        _docsHint = next.isEmpty
            ? 'No checklist documents are configured for the selected materials.'
            : '';
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _docsHint = error is DioException
            ? userFriendlyErrorMessage(error)
            : 'Unable to load document checklist.';
      });
    }
  }

  String? _validate({required bool forSubmit}) {
    if (_projectId.trim().isEmpty) {
      return 'Please select a project.';
    }
    if (_contractId.trim().isEmpty) {
      return 'Please select a contract.';
    }
    if (_supplier.text.trim().isEmpty) {
      return 'Please enter Source / Supplier.';
    }
    if (_batch.text.trim().isEmpty) {
      return 'Please enter Batch / Lot No.';
    }
    if (_invoice.text.trim().isEmpty) {
      return 'Please enter Invoice No.';
    }
    if (_deliveryDate == null) {
      return 'Please select Date of Delivery.';
    }
    if (_items.isEmpty) {
      return 'Please add at least one material item.';
    }
    for (int i = 0; i < _items.length; i++) {
      final MaterialReceiptFormItemDraft item = _items[i];
      if (item.materialCode.trim().isEmpty) {
        return 'Please select Material for row ${i + 1}.';
      }
      if (item.unit.trim().isEmpty) {
        return 'Please select Unit for row ${i + 1}.';
      }
      final double? qty = double.tryParse(item.quantity.trim());
      if (qty == null || qty <= 0) {
        return 'Please enter a valid Quantity for row ${i + 1}.';
      }
    }
    if (forSubmit) {
      for (final MaterialReceiptChecklistDoc doc in _docs) {
        if (doc.mandatory && !doc.hasFile) {
          return 'Please upload mandatory document: ${doc.documentName}.';
        }
      }
    }
    return null;
  }

  Map<String, dynamic> _buildPayload(String status) {
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[
      for (final MaterialReceiptFormItemDraft item in _items)
        <String, dynamic>{
          'itemId': item.itemId,
          'materialCode': item.materialCode.trim(),
          'gradeSpec': _emptyToNull(item.gradeSpec),
          'sizeType': _emptyToNull(item.sizeType),
          'unit': item.unit.trim(),
          'quantity': double.tryParse(item.quantity.trim()) ?? 0,
          'itemBatchLotNo': null,
          'remarks': _emptyToNull(item.remarks),
        },
    ];
    final List<Map<String, dynamic>> documents = <Map<String, dynamic>>[
      for (final MaterialReceiptChecklistDoc doc in _docs)
        <String, dynamic>{
          'docId': doc.docId,
          'itemId': null,
          'docType': doc.documentName,
          'filePath': null,
          'mandatory': doc.mandatory,
          'hasNewFile': doc.hasNewFile,
        },
    ];
    return <String, dynamic>{
      'receiptId': _receiptId.isEmpty ? null : _receiptId,
      'projectId': _projectId.trim(),
      'sectionId': materialReceiptSectionIdForSave(_sectionId),
      'contractId': _contractId.trim(),
      'vehicleChallanNo': _emptyToNull(_vehicle.text),
      'sourceSupplier': _supplier.text.trim(),
      'batchLotNo': _batch.text.trim(),
      'invoiceNo': _invoice.text.trim(),
      'placeChainage': null,
      'remarks': _emptyToNull(_remarks.text),
      'deliveryDate': DateFormat('yyyy-MM-dd').format(_deliveryDate!),
      'status': status,
      'items': items,
      'documents': documents,
    };
  }

  Future<void> _save(MaterialReceiptSaveAction action) async {
    if (_saving || _readOnly) {
      return;
    }
    final bool forSubmit = action == MaterialReceiptSaveAction.submit;
    final String? message = _validate(forSubmit: forSubmit);
    if (message != null) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Required',
        message: message,
      );
      return;
    }
    final String status = forSubmit
        ? materialReceiptSubmitStatus(_status)
        : materialReceiptDraftStatus(_status);
    final List<({String path, String fileName})> files =
        <({String path, String fileName})>[
          for (final MaterialReceiptChecklistDoc doc in _docs)
            if (doc.hasNewFile)
              (
                path: doc.localPath!,
                fileName: doc.localFileName.trim().isEmpty
                    ? p.basename(doc.localPath!)
                    : doc.localFileName,
              ),
        ];
    setState(() => _saving = true);
    try {
      final ({String receiptId, String status, String message}) result =
          await _source.saveReceipt(
            payload: _buildPayload(status),
            newFiles: files,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        if (result.receiptId.isNotEmpty) {
          _receiptId = result.receiptId;
        }
        if (result.status.isNotEmpty) {
          _status = result.status;
        } else {
          _status = status;
        }
        _saving = false;
      });
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: forSubmit ? 'Submit' : 'Save as Draft',
        message: result.message,
      );
      if (!mounted) {
        return;
      }
      if (forSubmit || result.receiptId.isNotEmpty) {
        context.pop(true);
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: forSubmit ? 'Submit' : 'Save as Draft',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error is StateError
            ? error.message
            : 'Unable to save material receipt.',
      );
    }
  }

  Future<void> _downloadTemplate() async {
    if (_busyTemplate) {
      return;
    }
    setState(() => _busyTemplate = true);
    try {
      Uint8List bytes;
      String fileName = 'material-receipt-template.xlsx';
      try {
        final ({Uint8List bytes, String fileName}) file = await _source
            .downloadTemplate();
        bytes = file.bytes;
        fileName = file.fileName;
      } on Object {
        bytes = buildMaterialReceiptItemsTemplateBytes();
      }
      if (!mounted) {
        return;
      }
      final Directory dir = await getTemporaryDirectory();
      final String safe = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final File local = File('${dir.path}/$safe');
      await local.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[
            XFile(
              local.path,
              name: safe,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          ],
        ),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Download Template',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : 'Unable to download template.',
      );
    } finally {
      if (mounted) {
        setState(() => _busyTemplate = false);
      }
    }
  }

  Future<void> _importExcel() async {
    if (_readOnly || _busyImport) {
      return;
    }
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['xlsx', 'xls'],
      withData: false,
    );
    final String? path = picked?.files.single.path;
    if (path == null || path.isEmpty) {
      return;
    }
    setState(() => _busyImport = true);
    try {
      final List<MaterialReceiptFormItemDraft> imported =
          await parseMaterialReceiptItemsExcelFile(
            path: path,
            materials: _catalog.materials,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = imported;
        _busyImport = false;
      });
      await _refreshChecklist();
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Import',
        message: 'Imported ${imported.length} item(s) from Excel.',
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busyImport = false);
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Import',
        message: error is StateError
            ? error.message
            : 'Unable to import Excel items.',
      );
    }
  }

  Future<void> _pickDocFile(int index) async {
    if (_readOnly) {
      return;
    }
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: false,
    );
    final String? path = picked?.files.single.path;
    if (path == null || path.isEmpty) {
      return;
    }
    final String name = picked!.files.single.name.trim().isEmpty
        ? p.basename(path)
        : picked.files.single.name;
    setState(() {
      _docs[index].localPath = path;
      _docs[index].localFileName = name;
    });
  }

  Future<void> _pickDeliveryDate() async {
    if (_readOnly) {
      return;
    }
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked == null) {
      return;
    }
    setState(() => _deliveryDate = picked);
  }

  void _addItem() {
    if (_readOnly) {
      return;
    }
    setState(() => _items.add(MaterialReceiptFormItemDraft()));
  }

  Future<void> _removeItem(int index) async {
    if (_readOnly) {
      return;
    }
    setState(() {
      if (_items.length == 1) {
        _items[0] = MaterialReceiptFormItemDraft();
      } else {
        _items.removeAt(index);
      }
    });
    await _refreshChecklist();
  }

  Future<void> _onMaterialPicked(int index, RfiFilterOption option) async {
    final String code = option.id;
    final String name = _materialNameFromOption(option);
    setState(() {
      _items[index].materialCode = code;
      _items[index].materialName = name;
    });
    await _refreshChecklist();
  }

  String _materialNameFromOption(RfiFilterOption option) {
    final String label = option.label.trim();
    final String id = option.id.trim();
    if (label.startsWith('$id - ')) {
      return label.substring(id.length + 3).trim();
    }
    if (label.contains(' - ')) {
      return label.split(' - ').skip(1).join(' - ').trim();
    }
    return label;
  }

  double get _totalQty => _items.fold<double>(
    0,
    (double sum, MaterialReceiptFormItemDraft item) => sum + item.quantityValue,
  );

  @override
  Widget build(BuildContext context) {
    final String title = _mode == MaterialReceiptFormMode.create
        ? 'Material Receipt Form'
        : _mode == MaterialReceiptFormMode.view
        ? 'Material Receipt'
        : 'Edit Material Receipt';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: <Widget>[
          RfiContentLoader(
            loading: _loading || _saving || _busyTemplate || _busyImport,
          ),
          Expanded(
            child: _error != null
                ? _centeredError()
                : _loading
                ? const SizedBox.shrink()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: <Widget>[
                      _sectionCard(
                        title: 'Receipt Details',
                        child: _receiptDetails(),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        title: 'Material Details',
                        child: _materialDetails(),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        title: 'Document Checklist',
                        child: _documentChecklist(),
                      ),
                      const SizedBox(height: 20),
                      _footerActions(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _centeredError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              _error is DioException
                  ? userFriendlyErrorMessage(_error! as DioException)
                  : _error.toString(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _bootstrap, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _receiptDetails() {
    return Column(
      children: <Widget>[
        _dropdown(
          label: 'Project',
          required: true,
          enabled: !_lockProject,
          options: _catalog.projects,
          selected: _projectId,
          onChanged: _onProjectChanged,
        ),
        const SizedBox(height: 10),
        _dropdown(
          label: 'Section',
          enabled: !_lockProject,
          options: _catalog.sections,
          selected: _sectionId,
          onChanged: (String? value) =>
              setState(() => _sectionId = value ?? ''),
        ),
        const SizedBox(height: 10),
        _dropdown(
          label: 'Contract',
          required: true,
          enabled: !_lockProject,
          options: _catalog.contracts,
          selected: _contractId,
          onChanged: (String? value) =>
              setState(() => _contractId = value ?? ''),
        ),
        const SizedBox(height: 10),
        _textField(
          label: 'Source / Supplier',
          required: true,
          controller: _supplier,
        ),
        const SizedBox(height: 10),
        _textField(
          label: 'Batch / Lot No.',
          required: true,
          controller: _batch,
        ),
        const SizedBox(height: 10),
        _textField(
          label: 'Invoice No.',
          required: true,
          controller: _invoice,
        ),
        const SizedBox(height: 10),
        _textField(label: 'Vehicle / Challan No.', controller: _vehicle),
        const SizedBox(height: 10),
        _dateField(),
        const SizedBox(height: 10),
        _textField(
          label: 'Remarks',
          controller: _remarks,
          maxLines: 3,
          hint: 'Enter Remarks (Optional)',
        ),
      ],
    );
  }

  Widget _materialDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!_readOnly)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Item'),
              ),
              if (_status.trim().toUpperCase() != 'PENDING_REVIEW')
                OutlinedButton.icon(
                  onPressed: _busyImport ? null : _importExcel,
                  icon: const Icon(Icons.table_view_outlined, size: 18),
                  label: const Text('Import from Excel'),
                ),
              OutlinedButton.icon(
                onPressed: _busyTemplate ? null : _downloadTemplate,
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Download Template'),
              ),
            ],
          ),
        if (!_readOnly) const SizedBox(height: 12),
        for (int i = 0; i < _items.length; i++) ...<Widget>[
          _itemCard(i),
          const SizedBox(height: 10),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Total Quantity (All Items): '
            '${_totalQty == 0 ? '—' : _formatQty(_totalQty)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _itemCard(int index) {
    final MaterialReceiptFormItemDraft item = _items[index];
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppPalette.of(context).fieldFill,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'Sr. No. ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const Spacer(),
                if (!_readOnly)
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () => _removeItem(index),
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
            _dropdown(
              label: 'Material',
              required: true,
              enabled: !_readOnly,
              options: _catalog.materials,
              selected: item.materialCode,
              onChanged: (String? value) async {
                if (value == null || value.isEmpty) {
                  setState(() {
                    item.materialCode = '';
                    item.materialName = '';
                  });
                  await _refreshChecklist();
                  return;
                }
                MaterialReceiptOption? option;
                for (final MaterialReceiptOption candidate
                    in _catalog.materials) {
                  if (candidate.value == value) {
                    option = candidate;
                    break;
                  }
                }
                if (option == null) {
                  return;
                }
                await _onMaterialPicked(
                  index,
                  RfiFilterOption(id: option.value, label: option.label),
                );
              },
            ),
            const SizedBox(height: 8),
            _plainField(
              fieldKey: ValueKey<String>('item-$index-grade'),
              label: 'Specification / Grade',
              value: item.gradeSpec,
              enabled: !_readOnly,
              onChanged: (String value) => item.gradeSpec = value,
            ),
            const SizedBox(height: 8),
            _plainField(
              fieldKey: ValueKey<String>('item-$index-size'),
              label: 'Size / Type',
              value: item.sizeType,
              enabled: !_readOnly,
              onChanged: (String value) => item.sizeType = value,
            ),
            const SizedBox(height: 8),
            _unitDropdown(item),
            const SizedBox(height: 8),
            _plainField(
              fieldKey: ValueKey<String>('item-$index-qty'),
              label: 'Quantity',
              required: true,
              value: item.quantity,
              enabled: !_readOnly,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (String value) {
                item.quantity = value;
                setState(() {});
              },
            ),
            const SizedBox(height: 8),
            _plainField(
              fieldKey: ValueKey<String>('item-$index-remarks'),
              label: 'Remarks',
              value: item.remarks,
              enabled: !_readOnly,
              onChanged: (String value) => item.remarks = value,
            ),
            if (_showEngrColumns) ...<Widget>[
              const SizedBox(height: 8),
              _plainField(
                fieldKey: ValueKey<String>('item-$index-engr-decision'),
                label: "Engr's Decision",
                value: item.itemDecision.trim().isEmpty
                    ? '—'
                    : formatMaterialReceiptStatus(item.itemDecision),
                enabled: false,
                onChanged: (_) {},
              ),
              const SizedBox(height: 8),
              _plainField(
                fieldKey: ValueKey<String>('item-$index-engr-remarks'),
                label: "Engr's Remarks (Item Wise)",
                value: item.engineerItemRemarks.trim().isEmpty
                    ? '—'
                    : item.engineerItemRemarks,
                enabled: false,
                onChanged: (_) {},
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _documentChecklist() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Upload all required documents for this material receipt. '
          '(Document requirement is as per Material Master configuration)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppPalette.of(context).mutedText,
          ),
        ),
        const SizedBox(height: 12),
        if (_docs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppPalette.of(context).fieldFill,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            ),
            child: Text(
              _docsHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppPalette.of(context).mutedText,
              ),
            ),
          )
        else
          for (int i = 0; i < _docs.length; i++) _docRow(i),
      ],
    );
  }

  Widget _docRow(int index) {
    final MaterialReceiptChecklistDoc doc = _docs[index];
    final String fileLabel = doc.hasNewFile
        ? doc.localFileName
        : (doc.existingFileName.isEmpty ? 'No file' : doc.existingFileName);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.fieldFill,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: ListTile(
          leading: Icon(
            doc.hasFile ? Icons.insert_drive_file_outlined : Icons.attach_file,
            color: doc.hasFile ? palette.success : colors.primary,
          ),
          title: Text(
            '${doc.documentName}${doc.mandatory ? ' *' : ''}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          subtitle: Text(
            fileLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: doc.hasFile ? palette.success : palette.mutedText,
            ),
          ),
          trailing: _readOnly
              ? (doc.hasFile
                    ? Icon(Icons.check_circle, color: palette.success)
                    : null)
              : IconButton(
                  tooltip: 'Upload',
                  onPressed: () => _pickDocFile(index),
                  icon: Icon(Icons.attach_file, color: colors.primary),
                ),
        ),
      ),
    );
  }

  Widget _footerActions() {
    final bool canDraft = !_readOnly && materialReceiptCanSaveDraft(_status);
    final bool canSubmit = !_readOnly && materialReceiptCanSubmit(_status);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        if (canDraft)
          FilledButton(
            onPressed: _saving
                ? null
                : () => _save(MaterialReceiptSaveAction.draft),
            child: const Text('SAVE AS DRAFT'),
          ),
        if (canSubmit)
          FilledButton(
            onPressed: _saving
                ? null
                : () => _save(MaterialReceiptSaveAction.submit),
            child: const Text('SUBMIT'),
          ),
        OutlinedButton(
          onPressed: _saving ? null : () => context.pop(),
          child: const Text('CANCEL'),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required List<MaterialReceiptOption> options,
    required String selected,
    required ValueChanged<String?> onChanged,
    bool required = false,
    bool enabled = true,
  }) {
    final String? selectedId = selected.isEmpty ? null : selected;
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        // Keep disabled fields readable in dark mode (avoid washing out text).
        opacity: enabled ? 1 : 0.72,
        child: RfiFilterField(
          label: required ? '$label *' : label,
          emptyLabel: 'Select',
          value: _optionLabel(options, selectedId),
          options: <RfiFilterOption>[
            for (final MaterialReceiptOption option in options)
              RfiFilterOption(id: option.value, label: option.label),
          ],
          selectedId: selectedId,
          onClear: selectedId == null || !enabled
              ? null
              : () => onChanged(null),
          onPick: (RfiFilterOption option) => onChanged(option.id),
        ),
      ),
    );
  }

  Widget _unitDropdown(MaterialReceiptFormItemDraft item) {
    return _dropdown(
      label: 'Unit',
      required: true,
      enabled: !_readOnly,
      options: <MaterialReceiptOption>[
        for (final String unit in MaterialReceiptUnit.values)
          MaterialReceiptOption(value: unit, label: unit),
      ],
      selected: item.unit,
      onChanged: (String? value) => setState(() => item.unit = value ?? ''),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    int maxLines = 1,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      enabled: !_readOnly,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
      ),
    );
  }

  Widget _plainField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    Key? fieldKey,
    bool required = false,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      key: fieldKey,
      initialValue: value,
      enabled: enabled,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
      ),
    );
  }

  Widget _dateField() {
    final String text = _deliveryDate == null
        ? ''
        : DateFormat('dd/MM/yyyy').format(_deliveryDate!);
    return InkWell(
      onTap: _readOnly ? null : _pickDeliveryDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date of Delivery *',
          suffixIcon: Icon(Icons.calendar_month_outlined),
        ),
        child: Text(
          text.isEmpty ? 'dd/mm/yyyy' : text,
          style: TextStyle(
            color: text.isEmpty
                ? AppPalette.of(context).mutedText
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

String? _optionLabel(List<MaterialReceiptOption> options, String? id) {
  if (id == null) {
    return null;
  }
  for (final MaterialReceiptOption option in options) {
    if (option.value == id) {
      return option.label;
    }
  }
  return id;
}

Object? _emptyToNull(String value) {
  final String text = value.trim();
  return text.isEmpty ? null : text;
}

DateTime? _parseUiDate(String value) {
  final String text = value.trim();
  if (text.isEmpty) {
    return null;
  }
  final RegExpMatch? match = RegExp(
    r'^(\d{2})[-/](\d{2})[-/](\d{4})$',
  ).firstMatch(text);
  if (match != null) {
    return DateTime(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
    );
  }
  return DateTime.tryParse(text);
}

String _formatQty(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toString();
}
