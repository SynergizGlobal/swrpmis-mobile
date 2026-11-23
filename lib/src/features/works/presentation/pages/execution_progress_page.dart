import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_fullscreen_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/execution_chart_data.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/pages/project_overview_page.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/providers/works_providers.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/widgets/execution_progress_chart.dart';

class ExecutionProgressPage extends ConsumerWidget {
  const ExecutionProgressPage({
    super.key,
    required this.projectId,
    required this.fallbackName,
  });

  static const String routeName = 'works-progress';
  static const String routePath = '/works/progress/:projectId';

  final String projectId;
  final String fallbackName;

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    // Deep link / cold start: return to Project Overview hub, not Works list.
    context.goNamed(
      ProjectOverviewPage.routeName,
      pathParameters: <String, String>{'projectId': projectId},
      queryParameters: <String, String>{
        if (fallbackName.trim().isNotEmpty) 'name': fallbackName,
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // GET /execution/progress runs only while this Track Strip page is open.
    final AsyncValue<ExecutionChartData> progress = ref.watch(
      executionProgressProvider(projectId),
    );

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => _goBack(context)),
        title: const Text('Track Strip Chart'),
      ),
      body: progress.when(
        loading: () => const AppFullscreenLoader(),
        error: (Object error, StackTrace stackTrace) {
          final String message = error is DioException
              ? userFriendlyErrorMessage(error)
              : error.toString();
          return _Message(
            message: message,
            onRetry: () => ref.invalidate(executionProgressProvider(projectId)),
          );
        },
        data: (ExecutionChartData data) {
          if (data.isEmpty) {
            return _Message(
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
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(executionProgressProvider(projectId));
              await ref.read(executionProgressProvider(projectId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: <Widget>[ExecutionProgressChart(data: titled)],
            ),
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
