import 'dart:io';
import 'dart:typed_data';

import 'package:excel_plus/excel_plus.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_form.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_list.dart';

const List<String> materialReceiptTemplateHeaders = <String>[
  'Material Code',
  'Material Name',
  'Specification / Grade',
  'Size / Type',
  'Unit',
  'Quantity',
  'Remarks',
];

Uint8List buildMaterialReceiptItemsTemplateBytes() {
  final Excel workbook = Excel.createExcel();
  final String sheetName = workbook.getDefaultSheet() ?? 'Sheet1';
  final Sheet sheet = workbook[sheetName];
  sheet.appendRow(
    materialReceiptTemplateHeaders
        .map<CellValue?>((String value) => TextCellValue(value))
        .toList(growable: false),
  );
  sheet.appendRow(<CellValue?>[
    TextCellValue('RNFT'),
    TextCellValue('Reinforcement'),
    TextCellValue('IS 1786:2008'),
    TextCellValue('20mm'),
    TextCellValue('MT'),
    DoubleCellValue(1),
    TextCellValue('Sample row — replace or delete'),
  ]);
  final List<int>? encoded = workbook.encode();
  if (encoded == null || encoded.isEmpty) {
    throw StateError('Unable to build material receipt template.');
  }
  return Uint8List.fromList(encoded);
}

List<MaterialReceiptFormItemDraft> parseMaterialReceiptItemsExcel({
  required Uint8List bytes,
  required List<MaterialReceiptOption> materials,
}) {
  final Excel workbook = Excel.decodeBytes(bytes);
  final String sheetName = workbook.getDefaultSheet() ??
      (workbook.tables.keys.isEmpty ? '' : workbook.tables.keys.first);
  if (sheetName.isEmpty) {
    throw StateError('Excel file has no sheets.');
  }
  final Sheet? sheet = workbook.tables[sheetName];
  if (sheet == null || sheet.rows.isEmpty) {
    throw StateError('Excel sheet is empty.');
  }
  final List<List<Data?>> rows = sheet.rows;
  final Map<String, int> header = _headerMap(rows.first);
  final List<MaterialReceiptFormItemDraft> items =
      <MaterialReceiptFormItemDraft>[];
  for (int r = 1; r < rows.length; r++) {
    final List<Data?> row = rows[r];
    final String code = _cell(row, header, const <String>[
      'material code',
      'materialcode',
      'code',
    ]);
    final String name = _cell(row, header, const <String>[
      'material name',
      'materialname',
      'material',
    ]);
    final String grade = _cell(row, header, const <String>[
      'specification / grade',
      'specification/grade',
      'spec / grade',
      'grade',
      'specification',
    ]);
    final String size = _cell(row, header, const <String>[
      'size / type',
      'size/type',
      'size',
      'type',
    ]);
    final String unit = _cell(row, header, const <String>['unit']);
    final String qty = _cell(row, header, const <String>[
      'quantity',
      'qty',
      'qty received',
    ]);
    final String remarks = _cell(row, header, const <String>['remarks']);
    if (code.isEmpty &&
        name.isEmpty &&
        grade.isEmpty &&
        size.isEmpty &&
        unit.isEmpty &&
        qty.isEmpty &&
        remarks.isEmpty) {
      continue;
    }
    final MaterialReceiptOption? matched = _matchMaterial(
      materials,
      code: code,
      name: name,
    );
    items.add(
      MaterialReceiptFormItemDraft(
        materialCode: matched?.value ?? code,
        materialName: matched?.label.contains(' - ') == true
            ? matched!.label.split(' - ').skip(1).join(' - ')
            : (matched?.label.isNotEmpty == true ? matched!.label : name),
        gradeSpec: grade,
        sizeType: size,
        unit: _normalizeUnit(unit),
        quantity: qty,
        remarks: remarks,
      ),
    );
  }
  if (items.isEmpty) {
    throw StateError('No material rows found in the Excel file.');
  }
  return items;
}

Future<List<MaterialReceiptFormItemDraft>> parseMaterialReceiptItemsExcelFile({
  required String path,
  required List<MaterialReceiptOption> materials,
}) async {
  final Uint8List bytes = await File(path).readAsBytes();
  return parseMaterialReceiptItemsExcel(bytes: bytes, materials: materials);
}

Map<String, int> _headerMap(List<Data?> headerRow) {
  final Map<String, int> map = <String, int>{};
  for (int i = 0; i < headerRow.length; i++) {
    final String key = _normalizeHeader(_dataText(headerRow[i]));
    if (key.isNotEmpty) {
      map[key] = i;
    }
  }
  return map;
}

String _cell(List<Data?> row, Map<String, int> header, List<String> keys) {
  for (final String key in keys) {
    final int? index = header[_normalizeHeader(key)];
    if (index == null || index < 0 || index >= row.length) {
      continue;
    }
    final String value = _dataText(row[index]);
    if (value.isNotEmpty) {
      return value;
    }
  }
  return '';
}

String _dataText(Data? cell) {
  final CellValue? value = cell?.value;
  if (value == null) {
    return '';
  }
  if (value is TextCellValue) {
    return value.value.toString().trim();
  }
  if (value is IntCellValue) {
    return value.value.toString();
  }
  if (value is DoubleCellValue) {
    final double n = value.value;
    if (n == n.roundToDouble()) {
      return n.toInt().toString();
    }
    return n.toString();
  }
  return value.toString().trim();
}

String _normalizeHeader(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

String _normalizeUnit(String raw) {
  final String value = raw.trim();
  if (value.isEmpty) {
    return '';
  }
  for (final String unit in MaterialReceiptUnit.values) {
    if (unit.toLowerCase() == value.toLowerCase()) {
      return unit;
    }
  }
  return value;
}

MaterialReceiptOption? _matchMaterial(
  List<MaterialReceiptOption> materials, {
  required String code,
  required String name,
}) {
  final String codeKey = code.trim().toLowerCase();
  final String nameKey = name.trim().toLowerCase();
  for (final MaterialReceiptOption option in materials) {
    if (codeKey.isNotEmpty && option.value.toLowerCase() == codeKey) {
      return option;
    }
  }
  for (final MaterialReceiptOption option in materials) {
    final String label = option.label.toLowerCase();
    if (nameKey.isNotEmpty &&
        (label == nameKey || label.endsWith(' - $nameKey') || label == nameKey)) {
      return option;
    }
  }
  return null;
}
