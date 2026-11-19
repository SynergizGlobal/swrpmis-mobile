import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_button_lottie.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_inspection_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_validator_option.dart';

Future<bool> showRfiSendForValidationDialog(
  BuildContext context, {
  required int rfiId,
  required String contractId,
  required String rfiCategory,
}) async {
  final bool? sent = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => _RfiSendForValidationDialog(
      rfiId: rfiId,
      contractId: contractId,
      rfiCategory: rfiCategory,
    ),
  );
  return sent == true;
}

class _RfiSendForValidationDialog extends ConsumerStatefulWidget {
  const _RfiSendForValidationDialog({
    required this.rfiId,
    required this.contractId,
    required this.rfiCategory,
  });

  final int rfiId;
  final String contractId;
  final String rfiCategory;

  @override
  ConsumerState<_RfiSendForValidationDialog> createState() =>
      _RfiSendForValidationDialogState();
}

class _RfiSendForValidationDialogState
    extends ConsumerState<_RfiSendForValidationDialog> {
  List<RfiValidatorOption> _validators = const <RfiValidatorOption>[];
  RfiValidatorOption? _selected;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<RfiValidatorOption> validators = await ref
          .read(rfiInspectionRemoteDataSourceProvider)
          .fetchValidators(
            contractId: widget.contractId,
            rfiCategory: widget.rfiCategory,
            rfiId: widget.rfiId,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _validators = validators;
        _loading = false;
        if (validators.isEmpty) {
          _error = 'No validators available for this RFI.';
        }
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString();
      });
    }
  }

  Future<void> _send() async {
    final RfiValidatorOption? selected = _selected;
    if (selected == null || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final String message = await ref
          .read(rfiInspectionRemoteDataSourceProvider)
          .sendForValidation(
            rfiId: widget.rfiId,
            sentToUserId: selected.userId,
            sentToUserName: selected.userName,
            validationType: selected.validateType,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Send for Validation',
        message: message,
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Send for Validation',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send for Validation'),
      content: SizedBox(
        width: 360,
        child: _loading
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text('Select the validator and validation type.'),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  else
                    DropdownButtonFormField<RfiValidatorOption>(
                      initialValue: _selected,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select validator',
                      ),
                      items: <DropdownMenuItem<RfiValidatorOption>>[
                        for (final RfiValidatorOption option in _validators)
                          DropdownMenuItem<RfiValidatorOption>(
                            value: option,
                            child: Text(option.label),
                          ),
                      ],
                      onChanged: _busy
                          ? null
                          : (RfiValidatorOption? value) {
                              setState(() => _selected = value);
                            },
                    ),
                ],
              ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, AppTheme.fieldHeight),
          ),
          onPressed: _selected == null || _busy || _loading ? null : _send,
          child: _busy
              ? const AppButtonLoader.white(height: 18)
              : const Text('Send for Validation'),
        ),
      ],
    );
  }
}
