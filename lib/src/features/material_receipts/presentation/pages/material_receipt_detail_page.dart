import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/data/datasources/material_receipt_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_detail.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_parse.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';

class MaterialReceiptDetailPage extends ConsumerStatefulWidget {
  const MaterialReceiptDetailPage({super.key, required this.receiptId});

  static const String routeName = 'forms-quality-detail';
  static const String routePath = '/module/quality/receipt/:receiptId';

  static String locationFor(String receiptId) {
    return '/module/quality/receipt/${Uri.encodeComponent(receiptId.trim())}';
  }

  final String receiptId;

  @override
  ConsumerState<MaterialReceiptDetailPage> createState() =>
      _MaterialReceiptDetailPageState();
}

class _MaterialReceiptDetailPageState
    extends ConsumerState<MaterialReceiptDetailPage> {
  bool _loading = true;
  Object? _error;
  MaterialReceiptDetail? _detail;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final MaterialReceiptDetail detail = await ref
          .read(materialReceiptRemoteDataSourceProvider)
          .fetchDetail(widget.receiptId);
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final MaterialReceiptDetail? detail = _detail;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.receiptId.trim().isEmpty
              ? 'Material Receipt'
              : widget.receiptId,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RfiContentLoader(loading: _loading),
          Expanded(
            child: _error != null
                ? _centered(
                    message: _error is DioException
                        ? userFriendlyErrorMessage(_error! as DioException)
                        : _error.toString(),
                    actionLabel: 'Retry',
                    onAction: _load,
                  )
                : detail == null
                ? (_loading
                      ? const SizedBox.shrink()
                      : _centered(message: 'Receipt not found.'))
                : _DetailBody(detail: detail),
          ),
        ],
      ),
    );
  }

  Widget _centered({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 12),
              FilledButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final MaterialReceiptDetail detail;

  @override
  Widget build(BuildContext context) {
    final TextStyle? body = Theme.of(context).textTheme.bodyMedium;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: AppTheme.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Read-only preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Full create/edit workflow will be added later. '
                  'Use Download on the list to get the merged PDF.',
                  style: body?.copyWith(
                    color: AppPalette.of(context).mutedText,
                  ),
                ),
                const SizedBox(height: 16),
                _row('Status', formatMaterialReceiptStatus(detail.status)),
                _row(
                  'Project',
                  [
                    detail.projectId,
                    detail.projectName,
                  ].where((String v) => v.trim().isNotEmpty).join(' - '),
                ),
                _row(
                  'Contract',
                  [
                    detail.contractId,
                    detail.contractShortName,
                  ].where((String v) => v.trim().isNotEmpty).join(' - '),
                ),
                _row('Supplier', detail.sourceSupplier),
                _row('Batch / Lot', detail.batchLotNo),
                _row('Invoice', detail.invoiceNo),
                _row('Delivery', detail.deliveryDate),
                _row('Items', '${detail.items.length}'),
                _row('Documents', '${detail.documents.length}'),
                if (detail.remarks.trim().isNotEmpty)
                  _row('Remarks', detail.remarks),
              ],
            ),
          ),
        ),
        if (detail.items.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            'Materials',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final MaterialReceiptItem item in detail.items)
            Card(
              child: ListTile(
                title: Text(
                  item.materialName.trim().isEmpty
                      ? item.materialCode
                      : item.materialName,
                ),
                subtitle: Text(
                  [
                    item.gradeSpec,
                    item.sizeType,
                    if (item.quantity.trim().isNotEmpty)
                      'Qty ${item.quantity} ${item.unit}'.trim(),
                    formatMaterialReceiptStatus(item.itemDecision),
                  ].where((String v) => v.trim().isNotEmpty).join(' · '),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(materialReceiptBlank(value))),
        ],
      ),
    );
  }
}
