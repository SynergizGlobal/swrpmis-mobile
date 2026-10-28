import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/contractors/data/datasources/contractor_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/contractors/domain/contractor_form.dart';
import 'package:swr_pmis_mobile/src/features/contractors/domain/contractor_list.dart';
import 'package:swr_pmis_mobile/src/features/contractors/presentation/providers/contractor_form_provider.dart';

class AddContractorFormPage extends ConsumerStatefulWidget {
  const AddContractorFormPage({
    super.key,
    this.contractorId = '',
    this.prefill = const ContractorFormDraft(),
  });

  final String contractorId;
  final ContractorFormDraft prefill;

  static const String routeName = 'add-contractor-form';
  static const String routePath = '/module/contractors/add';
  static const String editRouteName = 'edit-contractor-form';
  static const String editRoutePath = '/module/contractors/edit/:contractorId';

  static String location({String contractorId = ''}) {
    final String id = contractorId.trim();
    if (id.isEmpty) {
      return routePath;
    }
    return '/module/contractors/edit/${Uri.encodeComponent(id)}';
  }

  static ContractorFormDraft prefillFromExtra(Object? extra) {
    if (extra is ContractorFormDraft) {
      return extra;
    }
    if (extra is ContractorRow) {
      return ContractorFormDraft.fromRow(extra);
    }
    return const ContractorFormDraft();
  }

  @override
  ConsumerState<AddContractorFormPage> createState() =>
      _AddContractorFormPageState();
}

class _AddContractorFormPageState extends ConsumerState<AddContractorFormPage> {
  static const List<String> _stepTitles = <String>[
    'Basic',
    'Contact',
    'Bank & GST',
    'Remarks',
  ];

  final TextEditingController _pan = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _shortCode = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _primaryContact = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _gst = TextEditingController();
  final TextEditingController _bankName = TextEditingController();
  final TextEditingController _ifsc = TextEditingController();
  final TextEditingController _accountNo = TextEditingController();
  final TextEditingController _bankAddress = TextEditingController();
  final TextEditingController _remarks = TextEditingController();

  int _step = 0;
  bool _seeded = false;
  bool _saving = false;
  String _specialization = '';
  String? _searchStr;
  ContractorFormValidation _validation = const ContractorFormValidation();

  String get _contractorId {
    final String fromRoute = widget.contractorId.trim();
    if (fromRoute.isNotEmpty) {
      return fromRoute;
    }
    return widget.prefill.contractorId.trim();
  }

  bool get _editing => _contractorId.isNotEmpty;

  @override
  void dispose() {
    _pan.dispose();
    _name.dispose();
    _shortCode.dispose();
    _address.dispose();
    _primaryContact.dispose();
    _phone.dispose();
    _email.dispose();
    _gst.dispose();
    _bankName.dispose();
    _ifsc.dispose();
    _accountNo.dispose();
    _bankAddress.dispose();
    _remarks.dispose();
    super.dispose();
  }

  void _seed() {
    if (_seeded) {
      return;
    }
    final ContractorFormDraft draft = widget.prefill;
    _pan.text = draft.panNumber;
    _name.text = draft.contractorName;
    _shortCode.text = draft.contractorShortCode;
    _address.text = draft.address;
    _primaryContact.text = draft.primaryContact;
    _phone.text = draft.phoneNumber;
    _email.text = draft.email;
    _gst.text = draft.gstNumber;
    _bankName.text = draft.bankName;
    _ifsc.text = draft.ifscCode;
    _accountNo.text = draft.accountNo;
    _bankAddress.text = draft.bankAddress;
    _remarks.text = draft.remarks;
    _specialization = draft.specialization;
    _searchStr = draft.searchStr;
    _seeded = true;
  }

  ContractorFormValidation _validate({
    required bool requireBasic,
    required bool requireContact,
  }) {
    return validateContractorForm(
      panNumber: _pan.text,
      specialization: _specialization,
      contractorName: _name.text,
      contractorShortCode: _shortCode.text,
      address: _address.text,
      primaryContact: _primaryContact.text,
      phoneNumber: _phone.text,
      email: _email.text,
      requireBasic: requireBasic,
      requireContact: requireContact,
    );
  }

  Future<void> _goNext() async {
    if (_step == 0) {
      final ContractorFormValidation result = _validate(
        requireBasic: true,
        requireContact: false,
      );
      setState(() => _validation = result);
      if (result.hasBasicErrors) {
        return;
      }
    } else if (_step == 1) {
      final ContractorFormValidation result = _validate(
        requireBasic: false,
        requireContact: true,
      );
      setState(() => _validation = result);
      if (result.hasContactErrors) {
        return;
      }
    }
    if (_step < _stepTitles.length - 1) {
      setState(() => _step += 1);
    }
  }

  void _goBack() {
    if (_step <= 0) {
      return;
    }
    setState(() => _step -= 1);
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }
    final ContractorFormValidation result = _validate(
      requireBasic: true,
      requireContact: true,
    );
    setState(() => _validation = result);
    if (result.hasErrors) {
      setState(() {
        if (result.hasBasicErrors) {
          _step = 0;
        } else if (result.hasContactErrors) {
          _step = 1;
        }
      });
      return;
    }

    setState(() => _saving = true);
    try {
      final ContractorRemoteDataSource remote = ref.read(
        contractorRemoteDataSourceProvider,
      );
      final Map<String, dynamic> body = buildContractorPayload(
        contractorName: _name.text,
        contractorShortCode: _shortCode.text,
        panNumber: _pan.text,
        specialization: _specialization,
        address: _address.text,
        primaryContact: _primaryContact.text,
        phoneNumber: _phone.text,
        email: _email.text,
        gstNumber: _gst.text,
        bankName: _bankName.text,
        accountNo: _accountNo.text,
        ifscCode: _ifsc.text,
        bankAddress: _bankAddress.text,
        remarks: _remarks.text,
        searchStr: _searchStr,
        includeSearchStr: _editing,
      );
      if (_editing) {
        await remote.update(contractorId: _contractorId, body: body);
      } else {
        await remote.create(body);
      }
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: _editing ? 'Update Contractor' : 'Add Contractor',
        message: _editing
            ? 'Contractor updated successfully.'
            : 'Contractor added successfully.',
      );
      if (!mounted) {
        return;
      }
      context.pop(true);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: _editing ? 'Update Contractor' : 'Add Contractor',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error is StateError
            ? error.message
            : error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<String>> specializationsAsync = ref.watch(
      contractorSpecializationsProvider,
    );
    if (!_seeded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _seeded) {
          return;
        }
        setState(_seed);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Update Contractor' : 'Add Contractor'),
      ),
      body: !_seeded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                _StepHeader(titles: _stepTitles, current: _step),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: <Widget>[
                      if (_step == 0)
                        _basicStep(specializationsAsync)
                      else if (_step == 1)
                        _contactStep()
                      else if (_step == 2)
                        _bankStep()
                      else
                        _remarksStep(),
                    ],
                  ),
                ),
                _footer(),
              ],
            ),
    );
  }

  Widget _basicStep(AsyncValue<List<String>> specializationsAsync) {
    final List<String> options = specializationsAsync.valueOrNull ??
        <String>[
          if (_specialization.trim().isNotEmpty) _specialization.trim(),
        ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _fieldGrid(<Widget>[
          _text(
            _pan,
            label: 'PAN Number *',
            hint: 'Enter Number',
            errorText: _validation.panError,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(10),
              _UpperCaseTextFormatter(),
            ],
            onChanged: (_) {
              if (_validation.panError != null) {
                setState(() {
                  _validation = _validate(
                    requireBasic: true,
                    requireContact: false,
                  );
                });
              }
            },
          ),
          _dropdown(
            label: 'Specialization *',
            options: options,
            selected: _specialization,
            errorText: _validation.specializationError,
            loading: specializationsAsync.isLoading,
            onPick: (String value) {
              setState(() {
                _specialization = value;
                if (_validation.specializationError != null) {
                  _validation = _validate(
                    requireBasic: true,
                    requireContact: false,
                  );
                }
              });
            },
          ),
          _text(
            _name,
            label: 'Contractor Name *',
            hint: 'Enter Contractor Name',
            errorText: _validation.nameError,
          ),
          _text(
            _shortCode,
            label: 'Contractor Short Code *',
            hint: 'Enter max 5 chars',
            errorText: _validation.shortCodeError,
            maxLength: contractorShortCodeMaxLength,
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(contractorShortCodeMaxLength),
            ],
          ),
        ]),
        _text(
          _address,
          label: 'Address',
          hint: 'Enter address',
          maxLines: 4,
          maxLength: contractorAddressMaxLength,
          errorText: _validation.addressError,
        ),
        if (specializationsAsync.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Unable to load specializations. Retry from the menu or enter after reload.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  Widget _contactStep() {
    return _fieldGrid(<Widget>[
      _text(
        _primaryContact,
        label: 'Primary Contact',
        hint: 'Enter number',
        errorText: _validation.primaryContactError,
        keyboardType: TextInputType.phone,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        onChanged: (_) {
          if (_validation.primaryContactError != null) {
            setState(() {
              _validation = _validate(
                requireBasic: false,
                requireContact: true,
              );
            });
          }
        },
      ),
      _text(
        _phone,
        label: 'Phone Number',
        hint: 'Enter phone number',
        errorText: _validation.phoneError,
        keyboardType: TextInputType.phone,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        onChanged: (_) {
          if (_validation.phoneError != null) {
            setState(() {
              _validation = _validate(
                requireBasic: false,
                requireContact: true,
              );
            });
          }
        },
      ),
      _text(
        _email,
        label: 'Email',
        hint: 'Enter Value',
        errorText: _validation.emailError,
        keyboardType: TextInputType.emailAddress,
      ),
    ]);
  }

  Widget _bankStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _fieldGrid(<Widget>[
          _text(_gst, label: 'GST Number', hint: 'Enter Value'),
          _text(_bankName, label: 'Bank Name', hint: 'Enter Value'),
          _text(_ifsc, label: 'IFSC Code', hint: 'Enter Value'),
          _text(_accountNo, label: 'Account Number', hint: 'Enter Value'),
        ]),
        _text(
          _bankAddress,
          label: 'Bank Address',
          hint: 'Enter bank address',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _remarksStep() {
    return _text(
      _remarks,
      label: 'Remarks',
      hint: 'Enter remarks',
      maxLines: 5,
    );
  }

  Widget _footer() {
    final bool last = _step >= _stepTitles.length - 1;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: <Widget>[
            if (_step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : _goBack,
                  child: const Text('Back'),
                ),
              ),
            if (_step > 0) const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _saving
                    ? null
                    : last
                    ? _submit
                    : _goNext,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        last
                            ? (_editing ? 'Update' : 'ADD')
                            : 'Next',
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => context.pop(false),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final int columns = maxWidth >= 900
            ? 3
            : maxWidth >= 560
            ? 2
            : 1;
        const double gap = 12;
        final double width = columns == 1
            ? maxWidth
            : (maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: 4,
          children: <Widget>[
            for (final Widget child in children)
              SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }

  Widget _text(
    TextEditingController controller, {
    required String label,
    String? hint,
    String? errorText,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        textInputAction: maxLines == 1
            ? TextInputAction.next
            : TextInputAction.newline,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          alignLabelWithHint: maxLines > 1,
          counterText: maxLength == null ? null : null,
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onPick,
    String? errorText,
    bool loading = false,
  }) {
    final List<String> items = <String>[
      ...options,
      if (selected.trim().isNotEmpty &&
          !options.any(
            (String option) =>
                option.toLowerCase() == selected.trim().toLowerCase(),
          ))
        selected.trim(),
    ];
    final String? value = selected.trim().isEmpty
        ? null
        : items.any((String option) => option == selected)
        ? selected
        : items
            .where(
              (String option) =>
                  option.toLowerCase() == selected.trim().toLowerCase(),
            )
            .firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        key: ValueKey<String>('$label|$selected|${items.length}|$loading'),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          hintText: loading ? 'Loading...' : 'Select specialization',
          errorText: errorText,
        ),
        items: <DropdownMenuItem<String>>[
          for (final String option in items)
            DropdownMenuItem<String>(
              value: option,
              child: Text(option, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: loading
            ? null
            : (String? next) {
                if (next == null) {
                  return;
                }
                onPick(next);
              },
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.titles, required this.current});

  final List<String> titles;
  final int current;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: AppPalette.of(context).cardSurface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                for (int i = 0; i < titles.length; i++) ...<Widget>[
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i <= current
                            ? AppTheme.brandPrimary
                            : colors.outlineVariant,
                      ),
                    ),
                  _StepDot(
                    index: i,
                    label: titles[i],
                    active: i == current,
                    done: i < current,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Step ${current + 1} of ${titles.length}: ${titles[current]}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.brandPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.label,
    required this.active,
    required this.done,
  });

  final int index;
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color fill = active || done
        ? AppTheme.brandPrimary
        : colors.outlineVariant;
    final Color textColor = active || done ? Colors.white : colors.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CircleAvatar(
          radius: 14,
          backgroundColor: fill,
          child: done && !active
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 64,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active
                  ? AppTheme.brandPrimary
                  : AppPalette.of(context).mutedText,
            ),
          ),
        ),
      ],
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
