import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:swr_pmis_mobile/src/app/config/app_config_controller.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/ncr_observations/data/datasources/ncr_observation_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/ncr_observations/domain/ncr_observation_detail.dart';
import 'package:swr_pmis_mobile/src/features/ncr_observations/domain/ncr_observation_parse.dart';
import 'package:swr_pmis_mobile/src/features/ncr_observations/presentation/providers/ncr_observation_provider.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';

enum _VerifyDecision { close, returnAction }

class NcrObservationDetailPage extends ConsumerStatefulWidget {
  const NcrObservationDetailPage({super.key, required this.observationId});

  static const String routeName = 'forms-quality-ncr-observations-detail';

  static String locationFor(int observationId) {
    return '/module/quality/ncr-observations/item/$observationId';
  }

  final int observationId;

  @override
  ConsumerState<NcrObservationDetailPage> createState() =>
      _NcrObservationDetailPageState();
}

class _NcrObservationDetailPageState
    extends ConsumerState<NcrObservationDetailPage> {
  NcrObservationDetail? _detail;
  Object? _error;
  bool _loading = true;
  bool _submitting = false;

  final TextEditingController _remarks = TextEditingController();
  _VerifyDecision? _decision;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  @override
  void dispose() {
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final NcrObservationDetail detail = await ref
          .read(ncrObservationRemoteDataSourceProvider)
          .fetchDetail(widget.observationId);
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail;
        _loading = false;
        _decision = detail.isClosed ? _VerifyDecision.close : null;
        if (detail.verificationRemarks.isNotEmpty) {
          _remarks.text = detail.verificationRemarks;
        }
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

  Future<void> _openAttachment(NcrAttachment file) async {
    final String url = ncrAttachmentAbsoluteUrl(
      baseUrl: ref.read(appConfigProvider).baseUrl,
      filePath: file.filePath,
    );
    if (url.isEmpty) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Attachment',
        message: 'File path is missing.',
      );
      return;
    }
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Attachment',
        message: 'Invalid file URL.',
      );
      return;
    }
    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Attachment',
        message:
            'Could not open the file. The link was opened as:\n$url\n\n'
            'If this fails in the browser, the backend may need to fix file serving.',
      );
    }
  }

  Future<void> _submitVerification() async {
    final NcrObservationDetail? detail = _detail;
    if (detail == null || !detail.canVerify || _submitting) {
      return;
    }
    final _VerifyDecision? decision = _decision;
    if (decision == null) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Verification',
        message: 'Select Close NCR or Return for Further Action.',
      );
      return;
    }
    // Web: remarks mandatory when returning for further action.
    if (decision == _VerifyDecision.returnAction &&
        _remarks.text.trim().isEmpty) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Verification',
        message: 'Verification remarks are mandatory when returning.',
      );
      return;
    }
    final String verifiedBy =
        ref.read(authControllerProvider).valueOrNull?.userId.trim() ?? '';
    if (verifiedBy.isEmpty) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Verification',
        message: 'Unable to determine logged-in user for verification.',
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final NcrObservationDetail updated = await ref
          .read(ncrObservationRemoteDataSourceProvider)
          .verify(
            id: detail.id,
            approved: decision == _VerifyDecision.close,
            verificationRemarks: _remarks.text,
            verifiedBy: verifiedBy,
            current: detail,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = updated;
        _submitting = false;
        _decision = updated.isClosed ? _VerifyDecision.close : _decision;
      });
      ref.read(ncrObservationControllerProvider.notifier).load(
        reloadFilters: false,
      );
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Verification',
        message: decision == _VerifyDecision.close
            ? 'NCR closed successfully.'
            : 'NCR returned for further action.',
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Verification failed',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final NcrObservationDetail? detail = _detail;
    final String title = detail == null || detail.ncrCode.isEmpty
        ? 'NCR Details'
        : 'NCR Details – ${detail.ncrCode}';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RfiContentLoader(loading: _loading || _submitting),
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
    final NcrObservationDetail? detail = _detail;
    if (detail == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        _Section(
          index: 1,
          title: 'Reference Details',
          child: _ReferenceGrid(detail: detail),
        ),
        const SizedBox(height: 12),
        _Section(
          index: 2,
          title: 'NCR Details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _LabeledBlock(
                label: 'Description of Non-Conformance',
                child: _ReadOnlyBox(text: detail.description),
              ),
              const SizedBox(height: 12),
              _KV('Severity', formatNcrEnumLabel(detail.severity)),
              const SizedBox(height: 12),
              _AttachmentList(
                label: 'Supporting Documents',
                files: detail.issueAttachments,
                onOpen: _openAttachment,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          index: 3,
          title: 'Corrective Action (Contractor)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _LabeledBlock(
                label: 'Action Taken',
                child: _ReadOnlyBox(text: detail.correctiveActionTaken),
              ),
              const SizedBox(height: 12),
              _AttachmentList(
                label: 'Attachments',
                files: detail.correctiveAttachments,
                onOpen: _openAttachment,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          index: 4,
          title: 'Verification (Engineer)',
          child: _VerificationPanel(
            detail: detail,
            remarksController: _remarks,
            decision: _decision,
            submitting: _submitting,
            onDecision: ( _VerifyDecision? value) {
              setState(() => _decision = value);
            },
            onSubmit: _submitVerification,
          ),
        ),
      ],
    );
  }
}

class _ReferenceGrid extends StatelessWidget {
  const _ReferenceGrid({required this.detail});

  final NcrObservationDetail detail;

  @override
  Widget build(BuildContext context) {
    final NcrObligationReference obligation = detail.obligation;
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: <Widget>[
        _KV('Source', detail.sourceLabel),
        _KV('Test Name', obligation.testName),
        _KV('Material / Work', obligation.materialName),
        _KV('Material Receipt ID', detail.materialReceiptId),
        _KV('Batch / Lot No.', obligation.batchLotNo),
        _KV('Project', detail.projectId),
        _KV('Section', detail.sectionId),
        _KV('Contract', detail.contractId),
        _KV('Date Raised', detail.raisedDate),
        _StatusKV(status: detail.status),
      ],
    );
  }
}

class _VerificationPanel extends StatelessWidget {
  const _VerificationPanel({
    required this.detail,
    required this.remarksController,
    required this.decision,
    required this.submitting,
    required this.onDecision,
    required this.onSubmit,
  });

  final NcrObservationDetail detail;
  final TextEditingController remarksController;
  final _VerifyDecision? decision;
  final bool submitting;
  final ValueChanged<_VerifyDecision?> onDecision;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    if (detail.isClosed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'This item has already been verified and closed.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (detail.verificationRemarks.isNotEmpty) ...<Widget>[
            _LabeledBlock(
              label: 'Verification Remarks',
              child: _ReadOnlyBox(text: detail.verificationRemarks),
            ),
            const SizedBox(height: 12),
          ],
          _decisionRadios(enabled: false),
        ],
      );
    }
    if (detail.isWaitingOnContractor) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Waiting on the contractor to submit corrective action before '
            'this can be verified.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _LabeledBlock(
            label: 'Verification Remarks *',
            child: TextField(
              controller: remarksController,
              enabled: false,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter verification remarks',
              ),
            ),
          ),
          const SizedBox(height: 12),
          _decisionRadios(enabled: false),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _LabeledBlock(
          label: 'Verification Remarks',
          child: TextField(
            controller: remarksController,
            enabled: !submitting,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Enter verification remarks',
            ),
          ),
        ),
        const SizedBox(height: 12),
        _decisionRadios(enabled: !submitting),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: submitting ? null : onSubmit,
            child: Text(submitting ? 'Submitting…' : 'Submit'),
          ),
        ),
      ],
    );
  }

  Widget _decisionRadios({required bool enabled}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Status *', style: TextStyle(fontWeight: FontWeight.w700)),
        IgnorePointer(
          ignoring: !enabled,
          child: Opacity(
            opacity: enabled ? 1 : 0.55,
            child: RadioGroup<_VerifyDecision>(
              groupValue: decision,
              onChanged: onDecision,
              child: const Column(
                children: <Widget>[
                  RadioListTile<_VerifyDecision>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Close NCR'),
                    value: _VerifyDecision.close,
                  ),
                  RadioListTile<_VerifyDecision>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Return for Further Action'),
                    value: _VerifyDecision.returnAction,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.index,
    required this.title,
    required this.child,
  });

  final int index;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    return Card(
      color: palette.cardSurface,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ColoredBox(
            color: colors.primary.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                '$index. $title',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }
}

class _LabeledBlock extends StatelessWidget {
  const _LabeledBlock({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _ReadOnlyBox extends StatelessWidget {
  const _ReadOnlyBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final String value = text.trim().isEmpty ? '—' : text.trim();
    final AppPalette palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.fieldFill,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final String text = value.trim().isEmpty ? '—' : value.trim();
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
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

class _StatusKV extends StatelessWidget {
  const _StatusKV({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final String label = formatNcrEnumLabel(status);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final String key = status.trim().toUpperCase().replaceAll(' ', '_');
    final Color foreground;
    final Color fill;
    switch (key) {
      case 'CLOSED':
        foreground = palette.success;
        fill = palette.success.withValues(alpha: 0.16);
      case 'OPEN':
        foreground = dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
        fill = dark
            ? const Color(0xFFFBBF24).withValues(alpha: 0.18)
            : const Color(0xFFFEF3C7);
      case 'ACTION_SUBMITTED':
        foreground = scheme.primary;
        fill = scheme.primary.withValues(alpha: 0.14);
      case 'RETURNED':
        foreground = dark ? const Color(0xFFFB923C) : const Color(0xFFC2410C);
        fill = dark
            ? const Color(0xFFFB923C).withValues(alpha: 0.18)
            : const Color(0xFFFFEDD5);
      default:
        foreground = scheme.onSurfaceVariant;
        fill = scheme.outlineVariant.withValues(alpha: 0.55);
    }
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Status',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                label.isEmpty ? '—' : label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentList extends StatelessWidget {
  const _AttachmentList({
    required this.label,
    required this.files,
    required this.onOpen,
  });

  final String label;
  final List<NcrAttachment> files;
  final void Function(NcrAttachment file) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        if (files.isEmpty)
          Text(
            '—',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final NcrAttachment file in files)
                ActionChip(
                  avatar: Icon(
                    Icons.insert_drive_file_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(file.fileName),
                  onPressed: () => onOpen(file),
                ),
            ],
          ),
      ],
    );
  }
}
