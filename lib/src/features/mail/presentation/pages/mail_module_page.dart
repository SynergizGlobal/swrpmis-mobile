import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_list_scaffold.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/providers/mail_providers.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_folder_views.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_notifications_menu.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_sidebar.dart';
class MailModulePage extends ConsumerStatefulWidget {
  const MailModulePage({
    super.key,
    required this.folder,
    this.labelName,
  });

  final MailFolder folder;
  final String? labelName;

  static const String routeName = 'more-mail';
  static const String routePath = '/module/mail';

  static String folderPath(MailFolder folder) {
    switch (folder) {
      case MailFolder.inbox:
        return '$routePath/inbox';
      case MailFolder.sent:
        return '$routePath/sent';
      case MailFolder.drafts:
        return '$routePath/drafts';
      case MailFolder.trash:
        return '$routePath/trash';
      case MailFolder.starred:
        return '$routePath/starred';
      case MailFolder.important:
        return '$routePath/important';
      case MailFolder.label:
        return routePath;
      case MailFolder.compose:
        return '$routePath/compose';
    }
  }

  static String labelPath(String name) => '$routePath/label/${Uri.encodeComponent(name)}';

  static MailModulePage fromLocation(GoRouterState state) {
    final List<String> segments = state.uri.pathSegments;
    if (segments.length >= 4 && segments[2] == 'label') {
      return MailModulePage(
        folder: MailFolder.label,
        labelName: Uri.decodeComponent(segments[3]),
      );
    }
    final String segment =
        segments.length >= 3 ? segments[2] : 'inbox';
    return MailModulePage(
      folder: _folderFromSegment(segment),
      labelName: null,
    );
  }

  static MailFolder _folderFromSegment(String segment) {
    switch (segment) {
      case 'sent':
        return MailFolder.sent;
      case 'drafts':
        return MailFolder.drafts;
      case 'trash':
        return MailFolder.trash;
      case 'starred':
        return MailFolder.starred;
      case 'important':
        return MailFolder.important;
      case 'inbox':
      default:
        return MailFolder.inbox;
    }
  }

  @override
  ConsumerState<MailModulePage> createState() => _MailModulePageState();
}

class _MailModulePageState extends ConsumerState<MailModulePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _refreshAll() async {
    await mailRefreshAll(ref);
  }

  Widget _folderBody() {
    switch (widget.folder) {
      case MailFolder.inbox:
        return const MailInboxListView();
      case MailFolder.drafts:
        return const MailDraftsListView();
      case MailFolder.sent:
        return const MailSentListView();
      case MailFolder.trash:
        return const MailTrashListView();
      case MailFolder.starred:
        return const MailStarredListView(title: 'Flagged');
      case MailFolder.important:
        return const MailStarredListView(title: 'Important');
      case MailFolder.label:
        return MailLabelListView(labelName: widget.labelName ?? '');
      case MailFolder.compose:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool wide = width >= 900;

    return AppListScaffold(
      scaffoldKey: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Mail'),
        leading: wide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const MailNotificationsMenu(),
          const SizedBox(width: 8),
        ],
      ),
      drawer: wide
          ? null
          : Drawer(
              width: 280,
              child: MailSidebar(
                selected: widget.folder,
                labelName: widget.labelName,
                onNavigate: () => Navigator.of(context).pop(),
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (wide)
            SizedBox(
              width: 260,
              child: MailSidebar(
                selected: widget.folder,
                labelName: widget.labelName,
              ),
            ),
          Expanded(child: _folderBody()),
        ],
      ),
    );
  }
}
