import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/pages/mail_compose_page.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/pages/mail_module_page.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/providers/mail_providers.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_ui_helpers.dart';

class MailSidebar extends ConsumerWidget {
  const MailSidebar({
    super.key,
    required this.selected,
    this.labelName,
    this.onNavigate,
  });

  final MailFolder selected;
  final String? labelName;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<MailBadgeCounts> badges = ref.watch(mailBadgeCountsProvider);
    final AsyncValue<List<MailLabel>> labels = ref.watch(mailLabelsProvider);
    final int unread = badges.valueOrNull?.unreadInbox ?? 0;
    final int drafts = badges.valueOrNull?.drafts ?? 0;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
        children: <Widget>[
          FilledButton.icon(
            onPressed: () {
              onNavigate?.call();
              context.push(MailComposePage.routePath);
            },
            style: FilledButton.styleFrom(
              backgroundColor: MailColors.composeRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            icon: const Icon(Icons.edit_outlined, size: 20),
            label: const Text('Compose Mail'),
          ),
          const SizedBox(height: 20),
          _sectionTitle('MAILBOX'),
          _NavTile(
            icon: Icons.inbox_rounded,
            label: 'Inbox',
            badge: unread,
            selected: selected == MailFolder.inbox,
            onTap: () => _goFolder(context, MailFolder.inbox),
          ),
          _NavTile(
            icon: Icons.send_rounded,
            label: 'Sent Mail',
            selected: selected == MailFolder.sent,
            onTap: () => _goFolder(context, MailFolder.sent),
          ),
          _NavTile(
            icon: Icons.description_outlined,
            label: 'Drafts',
            badge: drafts,
            selected: selected == MailFolder.drafts,
            onTap: () => _goFolder(context, MailFolder.drafts),
          ),
          _NavTile(
            icon: Icons.delete_outline_rounded,
            label: 'Trash',
            selected: selected == MailFolder.trash,
            onTap: () => _goFolder(context, MailFolder.trash),
          ),
          _NavTile(
            icon: Icons.star_outline_rounded,
            label: 'Important',
            selected: selected == MailFolder.important,
            onTap: () => _goFolder(context, MailFolder.important),
          ),
          const SizedBox(height: 16),
          _sectionTitle('STORAGE'),
          _NavTile(
            icon: Icons.inventory_2_outlined,
            label: 'My Repository',
            onTap: () async {
              await AppDialog.show(
                context,
                variant: AppDialogVariant.info,
                title: 'My Repository',
                message: 'Repository integration is coming soon.',
              );
            },
          ),
          const SizedBox(height: 16),
          _sectionTitle('VIEWS'),
          _NavTile(
            icon: Icons.flag_outlined,
            label: 'Flagged',
            selected: selected == MailFolder.starred,
            onTap: () => _goFolder(context, MailFolder.starred),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(child: _sectionTitle('LABELS')),
              IconButton(
                tooltip: 'Add label',
                icon: const Icon(Icons.add, size: 18, color: MailColors.pillBlueText),
                onPressed: () async {
                  await AppDialog.show(
                    context,
                    variant: AppDialogVariant.info,
                    title: 'New label',
                    message: 'Creating labels is coming soon.',
                  );
                },
              ),
            ],
          ),
          labels.when(
            data: (List<MailLabel> items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No labels',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                );
              }
              return Column(
                children: items.map((MailLabel label) {
                  final bool active =
                      selected == MailFolder.label && labelName == label.name;
                  return _NavTile(
                    icon: Icons.circle,
                    iconColor: parseLabelColor(label.colorHex),
                    iconSize: 10,
                    label: label.name,
                    selected: active,
                    onTap: () {
                      onNavigate?.call();
                      context.go(MailModulePage.labelPath(label.name));
                    },
                  );
                }).toList(growable: false),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _goFolder(BuildContext context, MailFolder folder) {
    onNavigate?.call();
    context.go(MailModulePage.folderPath(folder));
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.badge,
    this.selected = false,
    this.iconColor,
    this.iconSize,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final int? badge;
  final bool selected;
  final Color? iconColor;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final Color bg = selected
        ? MailColors.pillBlue.withValues(alpha: 0.65)
        : Colors.transparent;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: <Widget>[
              Icon(icon, size: iconSize ?? 20, color: iconColor ?? MailColors.navy),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: MailColors.navy,
                  ),
                ),
              ),
              if (badge != null && badge! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: MailColors.pillBlueText,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
