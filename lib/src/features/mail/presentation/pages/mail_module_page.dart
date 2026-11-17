import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_list_scaffold.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/pages/mail_repository_page.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_dashboard_view.dart';
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
      case MailFolder.dashboard:
        return '$routePath/dashboard';
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
      case MailFolder.repository:
        return MailRepositoryPage.routePath;
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
        segments.length >= 3 ? segments[2] : 'dashboard';
    return MailModulePage(
      folder: _folderFromSegment(segment),
      labelName: null,
    );
  }

  static MailFolder _folderFromSegment(String segment) {
    switch (segment) {
      case 'dashboard':
        return MailFolder.dashboard;
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
      case 'repository':
        return MailFolder.repository;
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

  String _folderTitle() {
    switch (widget.folder) {
      case MailFolder.dashboard:
        return 'Mail Correspondence Dashboard';
      case MailFolder.inbox:
        return 'Inbox';
      case MailFolder.drafts:
        return 'Drafts';
      case MailFolder.sent:
        return 'Sent Mail';
      case MailFolder.trash:
        return 'Trash';
      case MailFolder.starred:
        return 'Flagged';
      case MailFolder.important:
        return 'Important';
      case MailFolder.repository:
        return 'My Repository';
      case MailFolder.label:
        return widget.labelName ?? 'Label';
      case MailFolder.compose:
        return 'Compose';
    }
  }

  Widget _folderBody() {
    switch (widget.folder) {
      case MailFolder.dashboard:
        return const MailDashboardView();
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
      case MailFolder.repository:
        return const MailRepositoryPage(embedded: true);
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
        automaticallyImplyLeading: false,
        leading: const BackButton(),
        title: const Text('Mail'),
        actions: const <Widget>[
          MailNotificationsMenu(),
          SizedBox(width: 8),
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Row(
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (!wide)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
                      child: Row(
                        children: <Widget>[
                          IconButton(
                            tooltip: 'Menu',
                            icon: const Icon(Icons.menu, size: 22),
                            onPressed: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _folderTitle(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(child: _folderBody()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
