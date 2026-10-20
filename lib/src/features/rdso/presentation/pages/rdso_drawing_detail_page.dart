import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_list.dart';
import 'package:swr_pmis_mobile/src/features/rdso/presentation/providers/rdso_drawing_detail_provider.dart';
import 'package:swr_pmis_mobile/src/features/rdso/presentation/widgets/rdso_drawing_files_table.dart';
import 'package:swr_pmis_mobile/src/features/rdso/presentation/widgets/rdso_library_dialogs.dart';
import 'package:swr_pmis_mobile/src/features/rdso/presentation/widgets/rdso_open_file.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';

class RdsoDrawingDetailPage extends ConsumerStatefulWidget {
  const RdsoDrawingDetailPage({super.key, required this.drawing});

  final RdsoDrawingRow drawing;

  static const String routeName = 'more-rdso-drawing';
  static const String routePath = '/module/rdso/drawing/:drawingId';

  static String routePathFor(String drawingId) =>
      '/module/rdso/drawing/${Uri.encodeComponent(drawingId.trim())}';

  @override
  ConsumerState<RdsoDrawingDetailPage> createState() =>
      _RdsoDrawingDetailPageState();
}

class _RdsoDrawingDetailPageState
    extends ConsumerState<RdsoDrawingDetailPage> {
  final TextEditingController _postContent = TextEditingController();
  String _postType = 'comment';
  String? _busyFileId;

  @override
  void dispose() {
    _postContent.dispose();
    super.dispose();
  }

  RdsoDrawingRow get drawing => widget.drawing;

  Future<void> _openFile(RdsoDrawingFile file, {required bool preview}) async {
    if (_busyFileId != null) {
      return;
    }
    setState(() => _busyFileId = file.id);
    try {
      final String fallback = file.name.trim().isEmpty
          ? '${drawing.drawingKey.trim()}.pdf'
          : file.name.trim();
      await openRdsoFile(
        ref: ref,
        context: context,
        fileId: file.id,
        fallbackName: fallback,
        preview: preview,
        shareOrigin: preview ? null : rdsoShareOrigin(context),
      );
    } finally {
      if (mounted) {
        setState(() => _busyFileId = null);
      }
    }
  }

  Future<void> _submitPost() async {
    final RdsoDrawingDetailState state = ref.read(
      rdsoDrawingDetailProvider(drawing),
    );
    if (state.posting) {
      return;
    }
    try {
      await ref
          .read(rdsoDrawingDetailProvider(drawing).notifier)
          .submitPost(postType: _postType, content: _postContent.text);
      if (!mounted) {
        return;
      }
      _postContent.clear();
      setState(() {});
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Post',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : 'Unable to post.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final RdsoDrawingDetailState state = ref.watch(
      rdsoDrawingDetailProvider(drawing),
    );
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(drawing.drawingKey.isEmpty ? 'Drawing' : drawing.drawingKey),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
          tooltip: 'Back to Library',
        ),
      ),
      body: Stack(
        children: <Widget>[
          RfiContentLoader(loading: state.loading),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: <Widget>[
              TextButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back to Library'),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                drawing.drawingKey,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (drawing.title.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  drawing.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: palette.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Files',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Material(
                color: palette.cardSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  side: BorderSide(color: colors.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: RdsoDrawingFilesTable(
                  files: state.files,
                  busyFileId: _busyFileId,
                  onView: (RdsoDrawingFile file) =>
                      _openFile(file, preview: true),
                  onDownload: (RdsoDrawingFile file) =>
                      _openFile(file, preview: false),
                  onMail: (RdsoDrawingFile file) {
                    showRdsoSendMailDialog(
                      context: context,
                      ref: ref,
                      fileId: file.id,
                      fileName: file.name,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Comments & Feedback',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (state.posts.isEmpty)
                Text(
                  'No comments yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.mutedText,
                  ),
                )
              else
                ...state.posts.map(
                  (RdsoPost post) => _PostTile(post: post),
                ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: 'comment',
                    label: Text('Comment'),
                  ),
                  ButtonSegment<String>(
                    value: 'feedback',
                    label: Text('Feedback'),
                  ),
                ],
                selected: <String>{_postType},
                onSelectionChanged: state.posting
                    ? null
                    : (Set<String> value) {
                        setState(() => _postType = value.first);
                      },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _postContent,
                enabled: !state.posting,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: state.posting ? null : _submitPost,
                  child: state.posting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Post'),
                ),
              ),
              if (state.error != null && !state.loading)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    state.error is DioException
                        ? userFriendlyErrorMessage(state.error! as DioException)
                        : state.error.toString(),
                    style: TextStyle(color: colors.error),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({required this.post});

  final RdsoPost post;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: palette.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    post.isFeedback ? 'Feedback' : 'Comment',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (post.createdAt.trim().isNotEmpty)
                    Text(
                      post.createdAt,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.mutedText,
                      ),
                    ),
                ],
              ),
              if (post.author.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  post.author,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(post.content),
            ],
          ),
        ),
      ),
    );
  }
}
