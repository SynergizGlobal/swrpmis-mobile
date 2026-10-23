import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/features/quality_test_register/data/datasources/quality_test_register_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/quality_test_register/domain/quality_test_register_detail.dart';
import 'package:swr_pmis_mobile/src/features/quality_test_register/domain/quality_test_register_parse.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';

class QualityTestRegisterDetailPage extends ConsumerStatefulWidget {
  const QualityTestRegisterDetailPage({super.key, required this.obligationId});

  static const String routeName = 'forms-quality-test-register-detail';

  static String locationFor(int obligationId) {
    return '/module/quality/test-register/obligation/$obligationId';
  }

  final int obligationId;

  @override
  ConsumerState<QualityTestRegisterDetailPage> createState() =>
      _QualityTestRegisterDetailPageState();
}

class _QualityTestRegisterDetailPageState
    extends ConsumerState<QualityTestRegisterDetailPage> {
  QualityTestObligationDetail? _detail;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final QualityTestObligationDetail detail = await ref
          .read(qualityTestRegisterRemoteDataSourceProvider)
          .fetchDetail(widget.obligationId);
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final QualityTestObligationDetail? detail = _detail;
    final String title = detail == null || detail.obligationCode.isEmpty
        ? 'Test Obligation'
        : detail.obligationCode;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RfiContentLoader(loading: _loading),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _error is DioException
                    ? userFriendlyErrorMessage(_error! as DioException)
                    : _error.toString(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final QualityTestObligationDetail? detail = _detail;
    if (detail == null) {
      return const SizedBox.shrink();
    }
    final AppPalette palette = AppPalette.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: <Widget>[
        _section(
          context,
          title: 'Obligation',
          children: <Widget>[
            _row('Test Obligation Id', detail.obligationCode),
            _row('Project', detail.projectId),
            _row('Section Id', detail.sectionId),
            _row('Contract', detail.contractId),
            _row(
              'Material / Work',
              detail.materialName.isEmpty
                  ? detail.materialCode
                  : detail.materialName,
            ),
            _row('Test Name', detail.testName),
            _row('Generated Form', detail.generatedFrom),
            _row('Obligation Basis/Coverage', detail.obligationBasisCoverage),
            _row('Triggers (Source)', detail.batchLotNo),
            _row('Required By Date', detail.requiredByDate),
            _row('Test Date', detail.testDate),
          ],
        ),
        const SizedBox(height: 12),
        _section(
          context,
          title: 'Status',
          children: <Widget>[
            _row(
              'Contractor Status',
              formatQualityTestStatus(detail.contractorStatus),
            ),
            _row(
              'Engineer Status',
              formatQualityTestStatus(detail.engineerStatus),
            ),
            _row('Final Result', detail.finalResult),
            _row('Contractor Remarks', detail.contractorRemarks),
            _row('Submitted By', detail.submittedBy),
            _row('Submitted On', detail.submittedOn),
            _row('Reviewed By', detail.reviewedBy),
            _row('Review Date', detail.reviewDate),
            _row('Review Comments', detail.reviewComments),
            _row('Remarks', detail.remarks),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'View only — actions coming later.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: palette.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    final String text = value.trim().isEmpty ? '—' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppPalette.of(context).mutedText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
