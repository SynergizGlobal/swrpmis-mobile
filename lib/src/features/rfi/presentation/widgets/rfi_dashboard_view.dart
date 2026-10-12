import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_dashboard_counts.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_dashboard_card.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_dashboard_provider.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';

class RfiDashboardView extends ConsumerWidget {
  const RfiDashboardView({super.key, required this.onOpenCard});

  final ValueChanged<RfiDashboardCardTarget> onOpenCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<RfiDashboardCounts>>(rfiDashboardProvider, (
      AsyncValue<RfiDashboardCounts>? previous,
      AsyncValue<RfiDashboardCounts> next,
    ) {
      final bool failed = next.hasError && !next.isLoading;
      final bool wasFailed =
          previous != null && previous.hasError && !previous.isLoading;
      if (!failed || wasFailed) {
        return;
      }
      final String message = _errorMessage(next.error!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        AppDialog.show(
          context,
          variant: AppDialogVariant.error,
          title: 'RFI dashboard',
          message: message,
        );
      });
    });
    final AsyncValue<RfiDashboardCounts> dashboard = ref.watch(
      rfiDashboardProvider,
    );
    final RfiDashboardCounts? counts = dashboard.valueOrNull;
    final bool showError = dashboard.hasError && !dashboard.isLoading;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RfiContentLoader(loading: dashboard.isLoading),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            'Welcome to RFI System',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: dark ? const Color(0xFF9DC0F0) : const Color(0xFF2F5FBF),
            ),
          ),
        ),
        Expanded(
          child: showError
              ? _ErrorBody(
                  message: _errorMessage(dashboard.error!),
                  onRetry: () => ref.invalidate(rfiDashboardProvider),
                )
              : counts == null
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  children: <Widget>[
                    _CountGrid(counts: counts, onOpenCard: onOpenCard),
                  ],
                ),
        ),
      ],
    );
  }
}

String _errorMessage(Object error) {
  if (error is DioException) {
    return userFriendlyErrorMessage(error);
  }
  return error.toString();
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 0;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 88),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: math.max(height - 48, 0)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CountGrid extends StatelessWidget {
  const _CountGrid({required this.counts, required this.onOpenCard});

  final RfiDashboardCounts counts;
  final ValueChanged<RfiDashboardCardTarget> onOpenCard;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 720 ? 3 : 2;
        final Map<String, int> byLabel = <String, int>{
          for (final ({String label, int count}) metric in counts.metrics)
            metric.label: metric.count,
        };
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: RfiDashboardCardTarget.all.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 112,
          ),
          itemBuilder: (BuildContext context, int index) {
            final RfiDashboardCardTarget target =
                RfiDashboardCardTarget.all[index];
            return _CountCard(
              label: target.label,
              count: byLabel[target.label] ?? 0,
              icon: _metricIcon(index),
              onTap: () => onOpenCard(target),
            );
          },
        );
      },
    );
  }
}

Widget _metricIcon(int index) {
  switch (index) {
    case 0:
      return const Icon(
        Icons.check_circle_rounded,
        color: Color(0xFF4ADE80),
        size: 26,
      );
    case 1:
      return const Icon(
        Icons.warning_amber_rounded,
        color: Color(0xFFFBBF24),
        size: 26,
      );
    case 2:
      return const Icon(
        Icons.calendar_month_rounded,
        color: Color(0xFFF8FAFC),
        size: 26,
      );
    case 3:
      return const Icon(
        Icons.verified_rounded,
        color: Color(0xFFFBBF24),
        size: 26,
      );
    case 4:
      return const Icon(
        Icons.assignment_turned_in_rounded,
        color: Color(0xFF4ADE80),
        size: 26,
      );
    case 5:
      return const _DocumentMarkIcon();
    default:
      return const Icon(
        Icons.settings_rounded,
        color: Color(0xFF7DD3FC),
        size: 26,
      );
  }
}

class _DocumentMarkIcon extends StatelessWidget {
  const _DocumentMarkIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.topLeft,
            child: Icon(
              Icons.description_rounded,
              color: Color(0xFFF8FAFC),
              size: 24,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Icon(
              Icons.cancel_rounded,
              color: Color(0xFFF87171),
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final int count;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF1E4F8A), Color(0xFF3A7AB8)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        height: 1,
                      ),
                    ),
                    const Spacer(),
                    icon,
                  ],
                ),
                const Spacer(),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
