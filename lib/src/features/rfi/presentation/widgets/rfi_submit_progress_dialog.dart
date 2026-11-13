import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_inspection_flow_provider.dart';

/// Live state of the submit, read by [RfiSubmitProgressDialog].
class RfiSubmitProgress extends ChangeNotifier {
  RfiSubmitProgress({List<RfiSubmitStep>? steps})
    : steps = steps ?? rfiSubmitSteps(rectification: false);

  /// The steps shown, in order (rectification shows its own two).
  final List<RfiSubmitStep> steps;

  late final Map<RfiSubmitStep, RfiStepStatus> _status =
      <RfiSubmitStep, RfiStepStatus>{
        for (final RfiSubmitStep step in steps) step: RfiStepStatus.waiting,
      };
  String? _error;

  RfiStepStatus statusOf(RfiSubmitStep step) =>
      _status[step] ?? RfiStepStatus.waiting;
  String? get error => _error;
  bool get finished =>
      _error != null ||
      _status.values.every(
        (RfiStepStatus s) =>
            s == RfiStepStatus.done || s == RfiStepStatus.skipped,
      );

  void update(RfiSubmitStep step, RfiStepStatus status) {
    if (!_status.containsKey(step)) {
      return;
    }
    _status[step] = status;
    notifyListeners();
  }

  void fail(String message) {
    _error = message;
    notifyListeners();
  }
}

/// "Submitting Inspection" with the web's five steps. It can't be dismissed
/// while running; after a failure it shows the reason and a Close button.
Future<void> showRfiSubmitProgressDialog(
  BuildContext context,
  RfiSubmitProgress progress,
) {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (BuildContext context) =>
        RfiSubmitProgressDialog(progress: progress),
  );
}

class RfiSubmitProgressDialog extends StatelessWidget {
  const RfiSubmitProgressDialog({super.key, required this.progress});

  final RfiSubmitProgress progress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListenableBuilder(
      listenable: progress,
      builder: (BuildContext context, Widget? _) {
        final String? error = progress.error;
        return PopScope(
          canPop: error != null,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Submitting Inspection',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.brandPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    error == null
                        ? 'Please do not close the app or go back until submission completes.'
                        : 'Submission stopped.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final RfiSubmitStep step in progress.steps)
                    _StepRow(
                      step: step,
                      status: progress.statusOf(step),
                      last: step == progress.steps.last,
                    ),
                  if (error != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        error,
                        style: const TextStyle(color: Color(0xFFB42318)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.status,
    required this.last,
  });

  final RfiSubmitStep step;
  final RfiStepStatus status;
  final bool last;

  @override
  Widget build(BuildContext context) {
    const Color green = Color(0xFF3E9B4F);
    const Color blue = Color(0xFF2F6FED);
    const Color red = Color(0xFFD92D20);
    final Color grey = Theme.of(context).colorScheme.outlineVariant;
    final (Widget marker, String caption, Color line) = switch (status) {
      RfiStepStatus.done => (
        const CircleAvatar(
          radius: 13,
          backgroundColor: green,
          child: Icon(Icons.check, size: 16, color: Colors.white),
        ),
        'Completed',
        green,
      ),
      RfiStepStatus.active => (
        const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: blue),
        ),
        'Processing...',
        grey,
      ),
      RfiStepStatus.failed => (
        const CircleAvatar(
          radius: 13,
          backgroundColor: red,
          child: Icon(Icons.close, size: 16, color: Colors.white),
        ),
        'Failed',
        grey,
      ),
      RfiStepStatus.skipped => (
        _ring(grey),
        'Skipped (RFI not required)',
        grey,
      ),
      RfiStepStatus.waiting => (_ring(grey), 'Waiting', grey),
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              marker,
              if (!last) Expanded(child: Container(width: 2, color: line)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2, bottom: last ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    step.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caption,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _ring(Color color) => Container(
    width: 26,
    height: 26,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: color, width: 2),
    ),
  );
}
