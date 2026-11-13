import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_button_lottie.dart';

/// Longest deletion reason the web form accepts.
const int rfiDeleteReasonMaxLength = 500;

/// Asks for a reason, then runs [onDelete] with it. The dialog stays open
/// while the request runs and shows any error inline so the typed reason is
/// not lost. Returns the server message on success, or null if closed.
Future<String?> showRfiDeleteDialog(
  BuildContext context, {
  required String rfiCode,
  required Future<String> Function(String reason) onDelete,
}) {
  return showDialog<String>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (BuildContext context) =>
        _RfiDeleteDialog(rfiCode: rfiCode, onDelete: onDelete),
  );
}

class _RfiDeleteDialog extends StatefulWidget {
  const _RfiDeleteDialog({required this.rfiCode, required this.onDelete});

  final String rfiCode;
  final Future<String> Function(String reason) onDelete;

  @override
  State<_RfiDeleteDialog> createState() => _RfiDeleteDialogState();
}

class _RfiDeleteDialogState extends State<_RfiDeleteDialog> {
  final TextEditingController _reason = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _canConfirm => !_busy && _reason.text.trim().isNotEmpty;

  Future<void> _confirm() async {
    if (!_canConfirm) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final String message = await widget.onDelete(_reason.text.trim());
      if (mounted) {
        Navigator.of(context).pop(message);
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = error is DioException
            ? userFriendlyErrorMessage(error)
            : 'Unable to delete this RFI. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool dark = scheme.brightness == Brightness.dark;
    final AppPalette palette = AppPalette.of(context);
    final Color red = dark ? const Color(0xFFFF8A93) : AppTheme.railwayRed;
    final String code = widget.rfiCode.trim();
    return PopScope(
      canPop: !_busy,
      child: Dialog(
        backgroundColor: dark ? const Color(0xFF122844) : AppTheme.surfaceLight,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: red.withValues(alpha: dark ? 0.22 : 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.priority_high_rounded,
                          color: red,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Delete RFI',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            code.isEmpty
                                ? 'Please provide a reason before deleting this RFI.'
                                : 'Please provide a reason before deleting $code.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: palette.mutedText,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text.rich(
                  TextSpan(
                    text: 'Reason for deletion ',
                    children: <InlineSpan>[
                      TextSpan(
                        text: '*',
                        style: TextStyle(color: red),
                      ),
                    ],
                  ),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: palette.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reason,
                  enabled: !_busy,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 6,
                  maxLength: rfiDeleteReasonMaxLength,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() => _error = null),
                  decoration: const InputDecoration(
                    hintText: 'Enter the reason for deleting this RFI...',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _error ?? 'Required field',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _error == null ? palette.mutedText : red,
                        ),
                      ),
                    ),
                    Text(
                      '${_reason.text.length}/$rfiDeleteReasonMaxLength',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.mutedText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: scheme.outlineVariant),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(88, 44),
                        foregroundColor: scheme.onSurface,
                      ),
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(140, 44),
                        backgroundColor: AppTheme.railwayRed,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _canConfirm ? _confirm : null,
                      child: _busy
                          ? const AppButtonLoader.white(height: 18)
                          : const Text('Confirm Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
