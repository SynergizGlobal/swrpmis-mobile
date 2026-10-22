import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_parse.dart';

void main() {
  test('parses material receipt list and filters', () {
    final ({dynamic rows, int total}) list = parseMaterialReceiptList(
      <String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'receipt_id': 'KRC-RNFT-0001',
            'project_id': 'P01',
            'project_name': 'Tumkuru project',
            'section_id': null,
            'section_name': null,
            'contract_id': 'P01EN01',
            'contract_short_name': 'New Broad gauge',
            'material_name': 'Reinforcement',
            'quantity': 19.58,
            'unit': 'MT',
            'batch_lot_no': 'A008101',
            'invoice_no': 'ETPL/2026-27/91',
            'delivery_date': <int>[2026, 6, 11],
            'status': 'ACCEPTED',
            'created_on': '05-10-2026',
          },
        ],
        'totalRecords': 1,
      },
    );
    expect(list.total, 1);
    expect(list.rows.single.receiptId, 'KRC-RNFT-0001');
    expect(list.rows.single.deliveryDate, '11-06-2026');
    expect(list.rows.single.quantity, '19.58');

    final filters = parseMaterialReceiptFilterOptions(<String, dynamic>{
      'projects': <Map<String, dynamic>>[
        <String, dynamic>{'id': 'P01', 'name': 'Tumkuru project'},
      ],
      'sections': <Map<String, dynamic>>[
        <String, dynamic>{'id': null, 'name': null},
      ],
      'contracts': <Map<String, dynamic>>[
        <String, dynamic>{'id': 'P01EN01', 'name': 'New Broad gauge'},
      ],
      'materials': <Map<String, dynamic>>[
        <String, dynamic>{'id': 'RNFT', 'name': 'Reinforcement'},
      ],
    });
    expect(filters.projects.single.value, 'P01');
    expect(filters.sections, isEmpty);
    expect(filters.materials.single.value, 'RNFT');
  });

  test('parses material receipt detail', () {
    final detail = parseMaterialReceiptDetail(<String, dynamic>{
      'success': true,
      'data': <String, dynamic>{
        'receiptId': 'KRC-RNFT-0001',
        'projectId': 'P01',
        'projectName': 'Tumkuru project',
        'contractId': 'P01EN01',
        'contractShortName': 'New Broad gauge',
        'sourceSupplier': 'Ecoforge',
        'batchLotNo': 'A008101',
        'invoiceNo': 'INV-1',
        'deliveryDate': <int>[2026, 6, 11],
        'status': 'ACCEPTED',
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'itemId': 1,
            'materialName': 'Reinforcement',
            'gradeSpec': 'IS 1786',
            'sizeType': '20mm',
            'unit': 'MT',
            'quantity': 3.932,
            'verifiedQuantity': 3.932,
            'itemDecision': 'ACCEPTED',
            'remarks': 'Bundle 1',
            'engineerItemRemarks': 'ok',
          },
        ],
        'documents': <Map<String, dynamic>>[
          <String, dynamic>{
            'docId': 1,
            'docType': 'Tax Invoice',
            'fileName': 'invoice.pdf',
            'downloadUrl': '/material-receipt/download-document/1',
          },
        ],
      },
    });
    expect(detail.receiptId, 'KRC-RNFT-0001');
    expect(detail.items, hasLength(1));
    expect(detail.documents.single.docId, 1);
    expect(formatMaterialReceiptStatus('ACCEPTED'), 'Accepted');
  });
}
