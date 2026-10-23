import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/presentation/pages/material_receipt_form_page.dart';

/// Compatibility alias — edit/view now share [MaterialReceiptFormPage].
class MaterialReceiptDetailPage extends StatelessWidget {
  const MaterialReceiptDetailPage({super.key, required this.receiptId});

  static const String routeName = MaterialReceiptFormPage.routeNameEdit;
  static const String routePath =
      '/module/quality/material-receipts/receipt/:receiptId';

  static String locationFor(String receiptId) =>
      MaterialReceiptFormPage.locationFor(receiptId);

  final String receiptId;

  @override
  Widget build(BuildContext context) {
    return MaterialReceiptFormPage(receiptId: receiptId);
  }
}
