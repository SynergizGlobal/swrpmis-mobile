import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_fullscreen_loader.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/execution_chart_data.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/providers/works_providers.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/widgets/execution_progress_chart.dart';

/// Project Overview body: `GET /execution/progress` → [ExecutionProgressChart].
class ProjectProgressPanel extends ConsumerWidget {
  const ProjectProgressPanel({
    super.key,
    required this.projectId,
    required this.fallbackName,
  });

  final String projectId;
  final String fallbackName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ExecutionChartData> progress = ref.watch(
      executionProgressProvider(projectId),
    );

    return progress.when(
      loading: () => const SizedBox(
        height: 220,
        child: AppFullscreenLoader(),
      ),
      error: (Object error, StackTrace _) {
        final String message = error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString();
        return _PanelMessage(
          message: message,
          onRetry: () => ref.invalidate(executionProgressProvider(projectId)),
        );
      },
      data: (ExecutionChartData data) {
        if (data.isEmpty) {
          return _PanelMessage(
            message: fallbackName.isEmpty
                ? 'No progress data for this project.'
                : 'No progress data for $fallbackName.',
            onRetry: () =>
                ref.invalidate(executionProgressProvider(projectId)),
          );
        }
        final ExecutionChartData titled = data.projectName.isEmpty
            ? ExecutionChartData(
                projectName: fallbackName,
                fromKm: data.fromKm,
                toKm: data.toKm,
                asOnLabel: data.asOnLabel,
                sections: data.sections,
                rows: data.rows,
              )
            : data;
        return ExecutionProgressChart(data: titled);
      },
    );
  }
}

class _PanelMessage extends StatelessWidget {
  const _PanelMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
