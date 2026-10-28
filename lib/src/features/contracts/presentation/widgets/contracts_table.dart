import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/features/contracts/domain/contract_list.dart';

class ContractsTableColumn {
  const ContractsTableColumn({
    required this.label,
    required this.minWidth,
    required this.read,
    this.buildCell,
  });

  final String label;
  final double minWidth;
  final String Function(ContractRow row) read;
  final Widget Function(BuildContext context, ContractRow row)? buildCell;
}

List<ContractsTableColumn> contractsTableColumns() {
  return const <ContractsTableColumn>[
    ContractsTableColumn(label: 'Project', minWidth: 140, read: _project),
    ContractsTableColumn(
      label: 'Contract ID',
      minWidth: 110,
      read: _contractId,
    ),
    ContractsTableColumn(
      label: 'Contract Name',
      minWidth: 200,
      read: _contractName,
    ),
    ContractsTableColumn(
      label: 'Contractor Name',
      minWidth: 180,
      read: _contractor,
    ),
    ContractsTableColumn(
      label: 'Department',
      minWidth: 120,
      read: _department,
    ),
    ContractsTableColumn(label: 'HOD', minWidth: 120, read: _hod),
    ContractsTableColumn(label: 'Dy HOD', minWidth: 120, read: _dyHod),
    ContractsTableColumn(
      label: 'Last Update',
      minWidth: 110,
      read: _lastUpdate,
    ),
  ];
}

String _project(ContractRow row) => row.projectDisplay;

String _contractId(ContractRow row) => row.contractId;

String _contractName(ContractRow row) => row.nameDisplay;

String _contractor(ContractRow row) => row.contractorName;

String _department(ContractRow row) => row.department;

String _hod(ContractRow row) => row.hod;

String _dyHod(ContractRow row) => row.dyHod;

String _lastUpdate(ContractRow row) => row.lastUpdate;

class ContractsTable extends StatelessWidget {
  const ContractsTable({super.key, required this.rows});

  final List<ContractRow> rows;

  @override
  Widget build(BuildContext context) {
    final List<ContractsTableColumn> columns = contractsTableColumns();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewport = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 0;
        final _ColumnLayout layout = _ColumnLayout.fit(columns, viewport);
        return TableScrollFrame(
          width: math.max(layout.total, viewport),
          header: _TableHeaderRow(columns: columns, widths: layout.widths),
          itemCount: rows.length,
          itemBuilder: (BuildContext context, int index) {
            return _DataRow(
              row: rows[index],
              columns: columns,
              widths: layout.widths,
              index: index,
            );
          },
        );
      },
    );
  }
}

class _ColumnLayout {
  const _ColumnLayout({required this.widths, required this.total});

  final List<double> widths;
  final double total;

  factory _ColumnLayout.fit(
    List<ContractsTableColumn> columns,
    double viewport,
  ) {
    final List<double> widths = columns
        .map((ContractsTableColumn c) => c.minWidth)
        .toList(growable: false);
    double total = widths.fold<double>(0, (double a, double b) => a + b);
    if (viewport > total && columns.isNotEmpty) {
      final double extra = viewport - total;
      final double bump = extra / columns.length;
      for (int i = 0; i < widths.length; i++) {
        widths[i] += bump;
      }
      total = viewport;
    }
    return _ColumnLayout(widths: widths, total: total);
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({required this.columns, required this.widths});

  final List<ContractsTableColumn> columns;
  final List<double> widths;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.brandPrimary,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < columns.length; i++)
            SizedBox(
              width: widths[i],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                child: Text(
                  columns[i].label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.row,
    required this.columns,
    required this.widths,
    required this.index,
  });

  final ContractRow row;
  final List<ContractsTableColumn> columns;
  final List<double> widths;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool stripe = index.isOdd;
    return ColoredBox(
      color: stripe
          ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
          : scheme.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < columns.length; i++)
            SizedBox(
              width: widths[i],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                child: columns[i].buildCell?.call(context, row) ??
                    Text(
                      columns[i].read(row),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
