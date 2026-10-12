import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/work_rfi_export_file.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_list_item.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_list_kind.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/work_rfi_export.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_table.dart';

void main() {
  test('work sample maps to a sheet row', () {
    final RfiListItem item = RfiListItem.fromJson(<String, dynamic>{
      'id': 57,
      'rfiId': 'RFI_W_RUB_36838_EXCL_EXC_0001',
      'projectName': '4th Line between Itarsi - Bhopal - Bina',
      'structure': '43 (RCC Box)',
      'element': 'Excavation',
      'nameOfRepresentative': 'IT Test Contractor Rep',
      'assignedPersonClient': null,
      'dateOfSubmission': '01-10-2026',
      'dateOfInspection': '01-10-2026',
      'timeOfInspection': '14:30',
      'contractorSubmittedOn': '01-10-2026 16:40',
      'rfiStatus': 'AE_INSP_ONGOING',
    });

    expect(
      workRfiExportHeaders,
      rfiTableColumns(
        RfiListKind.work,
      ).map((RfiTableColumn column) => column.label).where((String label) {
        return label != 'Actions';
      }),
    );
    expect(workRfiExportCells(item), <String>[
      'RFI_W_RUB_36838_EXCL_EXC_0001',
      '4th Line between Itarsi - Bhopal - Bina',
      '43 (RCC Box)',
      'Excavation',
      'IT Test Contractor Rep',
      '',
      '01-10-2026',
      '01-10-2026 14:30',
      '01-10-2026 16:40',
      'AE INSP ONGOING',
    ]);
    expect(
      workRfiExportCells(item)[workRfiExportHeaders.indexOf('RFI ID')],
      'RFI_W_RUB_36838_EXCL_EXC_0001',
    );
    expect(
      workRfiExportCells(item)[workRfiExportHeaders.indexOf('Scheduled on')],
      '01-10-2026 14:30',
    );
  });

  test('workbook bytes are an xlsx zip', () {
    final RfiListItem item = RfiListItem.fromJson(<String, dynamic>{
      'rfiId': 'RFI_W_RUB_36838_EXCL_EXC_0001',
      'dateOfInspection': '01-10-2026',
      'timeOfInspection': '14:30',
      'rfiStatus': 'AE_INSP_ONGOING',
    });
    final bytes = buildWorkRfiXlsxBytes(<RfiListItem>[item]);
    expect(bytes.length, greaterThan(4));
    expect(bytes[0], 0x50);
    expect(bytes[1], 0x4B);
    expect(workRfiExportFileName, 'work_rfi.xlsx');

    final Sheet sheet = Excel.decodeBytes(bytes).tables.values.single;
    final List<List<Data?>> rows = sheet.rows;
    expect(rows.length, 2);
    expect(_cellText(rows[1][0]), 'RFI_W_RUB_36838_EXCL_EXC_0001');
    expect(_cellText(rows[1][7]), '01-10-2026 14:30');
    expect(_cellText(rows[1][9]), 'AE INSP ONGOING');
  });
}

String _cellText(Data? data) {
  final CellValue? value = data?.value;
  if (value is TextCellValue) {
    return value.value.text ?? '';
  }
  return '';
}
