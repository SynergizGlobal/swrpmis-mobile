import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/features/contractors/domain/contractor_list.dart';

class ContractorsTableColumn {
  const ContractorsTableColumn({
    required this.label,
    required this.minWidth,
    required this.read,
    this.buildCell,
  });

  final String label;
  final double minWidth;
  final String Function(ContractorRow row) read;
  final Widget Function(BuildContext context, ContractorRow row)? buildCell;
}

List<ContractorsTableColumn> contractorsTableColumns({
  required void Function(ContractorRow row) onEdit,
}) {
  return <ContractorsTableColumn>[
    const ContractorsTableColumn(
      label: 'Contractor ID',
      minWidth: 110,
      read: _id,
    ),
    const ContractorsTableColumn(
      label: 'Contractor Name',
      minWidth: 200,
      read: _name,
    ),
    const ContractorsTableColumn(
      label: 'PAN Number',
      minWidth: 120,
      read: _pan,
    ),
    const ContractorsTableColumn(
      label: 'Specialization',
      minWidth: 150,
      read: _specialization,
    ),
    const ContractorsTableColumn(
      label: 'Address',
      minWidth: 180,
      read: _address,
    ),
    const ContractorsTableColumn(
      label: 'Primary Contact',
      minWidth: 120,
      read: _primary,
    ),
    const ContractorsTableColumn(
      label: 'Phone Number',
      minWidth: 120,
      read: _phone,
    ),
    const ContractorsTableColumn(label: 'Email', minWidth: 180, read: _email),
    ContractorsTableColumn(
      label: 'Actions',
      minWidth: 72,
      read: _blank,
      buildCell: (BuildContext context, ContractorRow row) {
        return Center(
          child: IconButton(
            tooltip: 'Edit',
            onPressed: () => onEdit(row),
            icon: const Icon(Icons.edit_document, size: 20),
          ),
        );
      },
    ),
  ];
}

String _id(ContractorRow row) => row.contractorId;
String _name(ContractorRow row) => row.contractorName;
String _pan(ContractorRow row) => row.panNumber;
String _specialization(ContractorRow row) => row.specialization;
String _address(ContractorRow row) => row.address;
String _primary(ContractorRow row) => row.primaryContact;
String _phone(ContractorRow row) => row.phoneNumber;
String _email(ContractorRow row) => row.email;
String _blank(ContractorRow row) => '';

class ContractorsTable extends StatelessWidget {
  const ContractorsTable({
    super.key,
    required this.rows,
    required this.onEdit,
  });

  final List<ContractorRow> rows;
  final void Function(ContractorRow row) onEdit;

  @override
  Widget build(BuildContext context) {
    final List<ContractorsTableColumn> columns = contractorsTableColumns(
      onEdit: onEdit,
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewport = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 0;
        final double natural = columns.fold<double>(
          0,
          (double sum, ContractorsTableColumn column) => sum + column.minWidth,
        );
        final double scale = viewport > natural && natural > 0
            ? viewport / natural
            : 1;
        final List<double> widths = <double>[
          for (final ContractorsTableColumn column in columns)
            column.minWidth * scale,
        ];
        final double total = widths.fold<double>(0, (double a, double b) => a + b);
        return TableScrollFrame(
          width: math.max(total, viewport),
          header: _HeaderRow(columns: columns, widths: widths),
          itemCount: rows.length,
          itemBuilder: (BuildContext context, int index) {
            return _DataRow(
              row: rows[index],
              index: index,
              columns: columns,
              widths: widths,
            );
          },
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.columns, required this.widths});

  final List<ContractorsTableColumn> columns;
  final List<double> widths;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
    );
    return Container(
      color: AppTheme.brandPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < columns.length; i++)
            SizedBox(
              width: widths[i],
              child: Text(columns[i].label, style: style),
            ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.row,
    required this.index,
    required this.columns,
    required this.widths,
  });

  final ContractorRow row;
  final int index;
  final List<ContractorsTableColumn> columns;
  final List<double> widths;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool alt = index.isOdd;
    final Color background = alt
        ? AppTheme.brandPrimary.withValues(alpha: 0.04)
        : palette.cardSurface;
    final TextStyle? style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (int i = 0; i < columns.length; i++)
              SizedBox(
                width: widths[i],
                child: columns[i].buildCell != null
                    ? columns[i].buildCell!(context, row)
                    : Text(
                        columns[i].read(row),
                        style: style,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
