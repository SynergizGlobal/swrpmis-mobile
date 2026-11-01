import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_dashboard.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_correspondence_table.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_ui_helpers.dart';

Future<void> showMailCorrespondenceDetailSheet(
  BuildContext context,
  MailCorrespondenceRow row,
) {
  final Size size = MediaQuery.sizeOf(context);
  final ColorScheme scheme = Theme.of(context).colorScheme;
  final AppPalette palette = AppPalette.of(context);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: palette.cardSurface,
    barrierColor: Colors.black54,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTheme.cardRadius),
      ),
    ),
    // Material 3 defaults to a centered maxWidth (~640) pillar on wide screens.
    constraints: BoxConstraints(
      maxWidth: size.width,
      maxHeight: size.height * 0.9,
    ),
    builder: (BuildContext sheetContext) {
      final double bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      final double maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.9;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          minWidth: double.infinity,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Correspondence details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: MailTheme.heading(sheetContext),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
                children: <Widget>[
                  _DetailRow(
                    label: 'Mail No.',
                    value: row.mailNo.trim().isEmpty ? '—' : row.mailNo,
                  ),
                  _DetailRow(
                    label: 'Reference',
                    value: row.reference.trim().isEmpty ? '—' : row.reference,
                  ),
                  _DetailRow(
                    label: 'Subject',
                    value: row.subject.trim().isEmpty ? '—' : row.subject,
                  ),
                  _DetailRow(
                    label: 'Contract',
                    value: row.contract.trim().isEmpty ? '—' : row.contract,
                  ),
                  _DetailRow(
                    label: 'Contractor',
                    value:
                        row.contractor.trim().isEmpty ? '—' : row.contractor,
                  ),
                  _DetailRow(
                    label: 'Date',
                    value: formatMailDashDate(row.date),
                  ),
                  _DetailRow(
                    label: 'Reply required',
                    value: row.replyRequired.trim().isEmpty
                        ? '—'
                        : row.replyRequired,
                  ),
                  _DetailRow(
                    label: 'Due date',
                    value: formatMailDashDate(row.dueDate),
                    valueColor:
                        mailDueDateIsOverdue(row) ? scheme.error : null,
                  ),
                  _DetailRow(
                    label: 'Person to reply',
                    value: row.person.trim().isEmpty ? '—' : row.person,
                  ),
                  _DetailRow(
                    label: 'Replied',
                    value: row.replied.trim().isEmpty ? '—' : row.replied,
                  ),
                  _DetailRow(
                    label: 'Reply mail no.',
                    value: row.replyMailNo.trim().isEmpty
                        ? '—'
                        : row.replyMailNo,
                  ),
                  _DetailRow(
                    label: 'Reply date',
                    value: formatMailDashDate(row.replyDate),
                  ),
                  if (row.status.trim().isNotEmpty)
                    _DetailRow(label: 'Status', value: row.status),
                  if (row.mailType.trim().isNotEmpty)
                    _DetailRow(label: 'Mail type', value: row.mailType),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: MailTheme.mutedStyle(context, fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
