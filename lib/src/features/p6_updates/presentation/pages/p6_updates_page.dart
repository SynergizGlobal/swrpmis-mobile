import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_list_scaffold.dart';
import 'package:swr_pmis_mobile/src/features/p6_updates/domain/p6_list.dart';
import 'package:swr_pmis_mobile/src/features/p6_updates/presentation/widgets/p6_history_list_view.dart';
import 'package:swr_pmis_mobile/src/features/p6_updates/presentation/widgets/p6_upload_sheet.dart';

class P6UpdatesPage extends StatelessWidget {
  const P6UpdatesPage({super.key});

  static const String routeName = 'forms-p6';
  static const String routePath = '/module/p6';

  void _showUploadSheet(BuildContext context, P6UploadKind kind) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => P6UploadSheet(kind: kind),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      appBar: AppBar(title: const Text('Structure P6 Updates')),
      body: const P6HistoryListView(),
      floatingActionButton: _P6SpeedDial(
        onKindSelected: (P6UploadKind kind) =>
            _showUploadSheet(context, kind),
      ),
    );
  }
}

class _P6SpeedDial extends StatefulWidget {
  const _P6SpeedDial({required this.onKindSelected});

  final ValueChanged<P6UploadKind> onKindSelected;

  @override
  State<_P6SpeedDial> createState() => _P6SpeedDialState();
}

class _P6SpeedDialState extends State<_P6SpeedDial>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _open = false;

  static const List<_FabOption> _options = <_FabOption>[
    _FabOption(kind: P6UploadKind.baseline, icon: Icons.upload_file_rounded),
    _FabOption(
      kind: P6UploadKind.revisedBaseline,
      icon: Icons.edit_document,
    ),
    _FabOption(kind: P6UploadKind.update, icon: Icons.update_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _select(P6UploadKind kind) {
    _toggle();
    widget.onKindSelected(kind);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        for (int i = 0; i < _options.length; i++)
          _buildMiniOption(theme, _options[i], i),
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: AppTheme.brandPrimary,
          foregroundColor: Colors.white,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _controller,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniOption(ThemeData theme, _FabOption option, int index) {
    final Animation<double> scale = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        index * 0.15,
        0.5 + index * 0.15,
        curve: Curves.easeOut,
      ),
    );
    return ScaleTransition(
      scale: scale,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Material(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              elevation: 2,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  option.kind.title,
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ),
            const SizedBox(width: 10),
            FloatingActionButton.small(
              heroTag: 'p6_fab_${option.kind.name}',
              onPressed: _open ? () => _select(option.kind) : null,
              backgroundColor: AppTheme.brandPrimary,
              foregroundColor: Colors.white,
              child: Icon(option.icon, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _FabOption {
  const _FabOption({required this.kind, required this.icon});
  final P6UploadKind kind;
  final IconData icon;
}
