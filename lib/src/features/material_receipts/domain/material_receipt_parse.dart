import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_detail.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_form.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_list.dart';

({List<MaterialReceiptRow> rows, int total}) parseMaterialReceiptList(
  dynamic data,
) {
  final Map<String, dynamic>? root = _map(data);
  if (root == null) {
    return (rows: const <MaterialReceiptRow>[], total: 0);
  }
  final List<MaterialReceiptRow> rows = <MaterialReceiptRow>[];
  for (final Map<String, dynamic> json in _listOfMaps(root['data'])) {
    final String receiptId = _text(json['receipt_id']);
    if (receiptId.isEmpty) {
      continue;
    }
    rows.add(
      MaterialReceiptRow(
        receiptId: receiptId,
        projectId: _text(json['project_id']),
        projectName: _text(json['project_name']),
        sectionId: _text(json['section_id']),
        sectionName: _text(json['section_name']),
        contractId: _text(json['contract_id']),
        contractShortName: _text(json['contract_short_name']),
        materialName: _text(json['material_name']),
        batchLotNo: _text(json['batch_lot_no']),
        quantity: _numberText(json['quantity']),
        unit: _text(json['unit']),
        deliveryDate: formatMaterialReceiptDate(json['delivery_date']),
        invoiceNo: _text(json['invoice_no']),
        status: _text(json['status']),
        createdOn: _text(json['created_on']),
      ),
    );
  }
  final int total = _int(root['totalRecords']) ??
      _int(root['total']) ??
      rows.length;
  return (rows: rows, total: total < 0 ? rows.length : total);
}

MaterialReceiptListSnapshot parseMaterialReceiptFilterOptions(dynamic data) {
  final Map<String, dynamic>? root = _map(data);
  if (root == null) {
    return MaterialReceiptListSnapshot.empty;
  }
  return MaterialReceiptListSnapshot(
    projects: _options(root['projects']),
    sections: _options(root['sections']),
    contracts: _options(root['contracts']),
    materials: _options(root['materials']),
  );
}

MaterialReceiptDetail parseMaterialReceiptDetail(dynamic data) {
  final Map<String, dynamic>? root = _map(data);
  if (root == null) {
    throw StateError('Empty material receipt response.');
  }
  final Map<String, dynamic>? payload =
      _map(root['data']) ?? (root.containsKey('receiptId') ? root : null);
  if (payload == null) {
    throw StateError('Material receipt details missing.');
  }
  final String receiptId = _text(payload['receiptId']);
  if (receiptId.isEmpty) {
    throw StateError('Material receipt id missing.');
  }
  return MaterialReceiptDetail(
    receiptId: receiptId,
    projectId: _text(payload['projectId']),
    projectName: _text(payload['projectName']),
    sectionId: _text(payload['sectionId']),
    sectionName: _text(payload['sectionName']),
    contractId: _text(payload['contractId']),
    contractShortName: _text(payload['contractShortName']),
    sourceSupplier: _text(payload['sourceSupplier']),
    batchLotNo: _text(payload['batchLotNo']),
    invoiceNo: _text(payload['invoiceNo']),
    deliveryDate: formatMaterialReceiptDate(payload['deliveryDate']),
    placeChainage: _text(payload['placeChainage']),
    remarks: _text(payload['remarks']),
    vehicleChallanNo: _text(payload['vehicleChallanNo']),
    status: _text(payload['status']),
    createdBy: _text(payload['createdBy']),
    createdOn: _text(payload['createdOn']),
    submittedBy: _text(payload['submittedBy']),
    submittedOn: _text(payload['submittedOn']),
    engineerId: _text(payload['engineerId']),
    engineerName: _text(payload['engineerName']),
    engineerDecision: _text(payload['engineerDecision']),
    engineerRemarks: _text(payload['engineerRemarks']),
    decisionOn: _text(payload['decisionOn']),
    contractorName: _text(payload['contractorName']),
    createdByName: _text(payload['createdByName']),
    revisionNo: _numberText(payload['revisionNo']),
    items: <MaterialReceiptItem>[
      for (final Map<String, dynamic> json in _listOfMaps(payload['items']))
        MaterialReceiptItem(
          itemId: _int(json['itemId']),
          materialCode: _text(json['materialCode']),
          materialName: _text(json['materialName']),
          gradeSpec: _text(json['gradeSpec']),
          sizeType: _text(json['sizeType']),
          unit: _text(json['unit']),
          quantity: _numberText(json['quantity']),
          itemBatchLotNo: _text(json['itemBatchLotNo']),
          remarks: _text(json['remarks']),
          verifiedQuantity: _numberText(json['verifiedQuantity']),
          engineerItemRemarks: _text(json['engineerItemRemarks']),
          itemDecision: _text(json['itemDecision']),
        ),
    ],
    documents: <MaterialReceiptDocument>[
      for (final Map<String, dynamic> json in _listOfMaps(payload['documents']))
        if (_int(json['docId']) != null)
          MaterialReceiptDocument(
            docId: _int(json['docId'])!,
            itemId: _int(json['itemId']),
            docType: _text(json['docType']),
            fileName: _text(json['fileName']),
            downloadUrl: _text(json['downloadUrl']),
            uploadedBy: _text(json['uploadedBy']),
            uploadedOn: _text(json['uploadedOn']),
          ),
    ],
  );
}

String formatMaterialReceiptDate(dynamic value) {
  if (value == null) {
    return '';
  }
  if (value is List && value.length >= 3) {
    final int? year = _int(value[0]);
    final int? month = _int(value[1]);
    final int? day = _int(value[2]);
    if (year == null || month == null || day == null) {
      return '';
    }
    return '${day.toString().padLeft(2, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '$year';
  }
  final String text = _text(value);
  final RegExpMatch? iso = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})',
  ).firstMatch(text);
  if (iso != null) {
    return '${iso.group(3)}-${iso.group(2)}-${iso.group(1)}';
  }
  return text;
}

String formatMaterialReceiptStatus(String? raw) {
  final String value = (raw ?? '').trim();
  if (value.isEmpty) {
    return '-';
  }
  return value
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((String part) => part.isNotEmpty)
      .map(
        (String part) =>
            '${part[0].toUpperCase()}${part.length > 1 ? part.substring(1) : ''}',
      )
      .join(' ');
}

String materialReceiptBlank(String? value) {
  final String text = (value ?? '').trim();
  return text.isEmpty ? '-' : text;
}

List<MaterialReceiptOption> _options(dynamic raw) {
  final List<MaterialReceiptOption> out = <MaterialReceiptOption>[];
  for (final Map<String, dynamic> json in _listOfMaps(raw)) {
    final String id = _text(json['id']);
    final String name = _text(json['name']);
    if (id.isEmpty && name.isEmpty) {
      continue;
    }
    final String value = id.isEmpty ? name : id;
    final String label = name.isEmpty
        ? id
        : id.isEmpty
        ? name
        : '$id - $name';
    out.add(MaterialReceiptOption(value: value, label: label));
  }
  return out;
}

List<Map<String, dynamic>> _listOfMaps(dynamic raw) {
  if (raw is! List) {
    return const <Map<String, dynamic>>[];
  }
  final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
  for (final dynamic item in raw) {
    final Map<String, dynamic>? map = _map(item);
    if (map != null) {
      out.add(map);
    }
  }
  return out;
}

Map<String, dynamic>? _map(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return raw.map(
      (dynamic key, dynamic value) =>
          MapEntry<String, dynamic>(key.toString(), value),
    );
  }
  return null;
}

String _text(dynamic value) {
  if (value == null) {
    return '';
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return '';
  }
  return text;
}

String _numberText(dynamic value) {
  if (value == null) {
    return '';
  }
  if (value is num) {
    if (value is int || value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    final String text = value.toString();
    if (text.contains('.') && text.endsWith('0')) {
      return text.replaceFirst(RegExp(r'\.?0+$'), '');
    }
    return text;
  }
  return _text(value);
}

int? _int(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(_text(value));
}

List<MaterialReceiptOption> parseMaterialReceiptDropdownProjects(dynamic data) {
  return _namedOptions(
    _envelopeList(data),
    idKeys: const <String>['projectIdFk', 'project_id', 'id'],
    nameKeys: const <String>['projectName', 'project_name', 'name'],
  );
}

List<MaterialReceiptOption> parseMaterialReceiptDropdownMaterials(dynamic data) {
  return _namedOptions(
    _envelopeList(data),
    idKeys: const <String>['materialCode', 'material_code', 'id'],
    nameKeys: const <String>['materialName', 'material_name', 'name'],
  );
}

List<MaterialReceiptOption> parseMaterialReceiptDropdownSections(dynamic data) {
  return _namedOptions(
    _envelopeList(data),
    idKeys: const <String>['section_id', 'sectionId', 'id'],
    nameKeys: const <String>['section_name', 'sectionName', 'name'],
  );
}

List<MaterialReceiptOption> parseMaterialReceiptDropdownContracts(dynamic data) {
  return _namedOptions(
    _envelopeList(data),
    idKeys: const <String>['id', 'contract_id', 'contractId'],
    nameKeys: const <String>['name', 'contract_name', 'contractShortName'],
  );
}

List<MaterialReceiptChecklistDoc> parseMaterialReceiptDocumentsByMaterial(
  dynamic data,
) {
  final List<MaterialReceiptChecklistDoc> out = <MaterialReceiptChecklistDoc>[];
  for (final Map<String, dynamic> json in _listOfMaps(_envelopeList(data))) {
    final String name = _firstText(json, const <String>[
      'documentName',
      'document_name',
      'docType',
      'name',
    ]);
    if (name.isEmpty) {
      continue;
    }
    out.add(
      MaterialReceiptChecklistDoc(
        documentId: _int(json['documentId'] ?? json['document_id']),
        documentName: name,
        mandatory: _bool(json['mandatory'] ?? json['checklist']),
      ),
    );
  }
  return out;
}

({String receiptId, String status, String message}) parseMaterialReceiptSaveResult(
  dynamic data,
) {
  final Map<String, dynamic>? root = _map(data);
  final Map<String, dynamic>? payload = _map(root?['data']) ?? root;
  final String message = _firstText(root ?? const <String, dynamic>{}, const <String>[
    'message',
    'success',
  ]);
  return (
    receiptId: _text(payload?['receiptId']),
    status: _text(payload?['status']),
    message: message.isEmpty ? 'Success' : message,
  );
}

/// Converts UI `dd-MM-yyyy` / `dd/MM/yyyy` to API `yyyy-MM-dd`.
String materialReceiptApiDate(String uiDate) {
  final String text = uiDate.trim();
  if (text.isEmpty) {
    return '';
  }
  final RegExpMatch? match = RegExp(
    r'^(\d{2})[-/](\d{2})[-/](\d{4})$',
  ).firstMatch(text);
  if (match != null) {
    return '${match.group(3)}-${match.group(2)}-${match.group(1)}';
  }
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
    return text;
  }
  return text;
}

String materialReceiptUiDateFromApi(String apiOrDisplay) {
  final String formatted = formatMaterialReceiptDate(apiOrDisplay);
  if (formatted.isEmpty) {
    return '';
  }
  return formatted.replaceAll('-', '/');
}

Object? materialReceiptSectionIdForSave(String sectionId) {
  final String text = sectionId.trim();
  if (text.isEmpty) {
    return null;
  }
  return int.tryParse(text) ?? text;
}

List<dynamic> _envelopeList(dynamic data) {
  final Map<String, dynamic>? root = _map(data);
  if (root != null) {
    final dynamic nested = root['data'] ?? root['items'] ?? root['results'];
    if (nested is List) {
      return nested;
    }
  }
  if (data is List) {
    return data;
  }
  return const <dynamic>[];
}

List<MaterialReceiptOption> _namedOptions(
  List<dynamic> raw, {
  required List<String> idKeys,
  required List<String> nameKeys,
}) {
  final List<MaterialReceiptOption> out = <MaterialReceiptOption>[];
  for (final Map<String, dynamic> json in _listOfMaps(raw)) {
    final String id = _firstText(json, idKeys);
    final String name = _firstText(json, nameKeys);
    if (id.isEmpty && name.isEmpty) {
      continue;
    }
    final String value = id.isEmpty ? name : id;
    final String label = name.isEmpty
        ? id
        : id.isEmpty
        ? name
        : '$id - $name';
    out.add(MaterialReceiptOption(value: value, label: label));
  }
  return out;
}

String _firstText(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final String value = _text(json[key]);
    if (value.isNotEmpty) {
      return value;
    }
  }
  return '';
}

bool _bool(dynamic value) {
  if (value is bool) {
    return value;
  }
  final String text = _text(value).toLowerCase();
  return text == 'true' || text == '1' || text == 'yes' || text == 'y';
}
