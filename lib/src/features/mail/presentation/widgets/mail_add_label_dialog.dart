import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/providers/mail_providers.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_ui_helpers.dart';

const List<String> kMailLabelColors = <String>[
  '#2563EB',
  '#8B5CF6',
  '#16A34A',
  '#F59E0B',
  '#DC2626',
  '#0EA5E9',
  '#DB2777',
  '#6B7280',
];

Future<void> showMailAddLabelDialog(BuildContext context, WidgetRef ref) async {
  final TextEditingController name = TextEditingController();
  String color = kMailLabelColors.first;
  bool saving = false;

  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (BuildContext context, void Function(void Function()) setLocal) {
          return AlertDialog(
            title: const Text('Add Label'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Create a label for organizing mails.',
                  style: MailTheme.mutedStyle(context),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Label Name'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Label Color',
                  style: MailTheme.mutedStyle(
                    context,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: kMailLabelColors.map((String hex) {
                    final Color c = parseLabelColor(hex);
                    final bool selected = color == hex;
                    return InkWell(
                      onTap: () => setLocal(() => color = hex),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(growable: false),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final String trimmed = name.text.trim();
                        if (trimmed.isEmpty) {
                          await AppDialog.show(
                            context,
                            variant: AppDialogVariant.info,
                            title: 'Required',
                            message: 'Enter a label name.',
                          );
                          return;
                        }
                        setLocal(() => saving = true);
                        try {
                          await mailCreateLabel(
                            ref,
                            name: trimmed,
                            color: color,
                          );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        } on Object catch (error) {
                          setLocal(() => saving = false);
                          if (!context.mounted) {
                            return;
                          }
                          await AppDialog.show(
                            context,
                            variant: AppDialogVariant.error,
                            title: 'Add Label',
                            message: error is DioException
                                ? userFriendlyErrorMessage(error)
                                : error.toString(),
                          );
                        }
                      },
                child: const Text('Add Label'),
              ),
            ],
          );
        },
      );
    },
  );
  name.dispose();
}
