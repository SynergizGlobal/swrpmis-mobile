import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_fullscreen_loader.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_details.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_user_role.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_inspection_flow_provider.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/rfi_inspection_errors.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_checklist_dialog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_server_image.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/work_rfi_form.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_stored_file.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/rfi_log_print.dart';
import 'package:printing/printing.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_submit_progress_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class RfiInspectionFlowPage extends ConsumerStatefulWidget {
  const RfiInspectionFlowPage({super.key, required this.args});

  static const String routePath = '/rfi/inspection-flow';
  static const String routeName = 'rfi-inspection-flow';

  final RfiInspectionFlowArgs args;

  @override
  ConsumerState<RfiInspectionFlowPage> createState() =>
      _RfiInspectionFlowPageState();
}

class _RfiInspectionFlowPageState
    extends ConsumerState<RfiInspectionFlowPage> {
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _chainage;
  late final TextEditingController _location;
  late final TextEditingController _representative;
  late final TextEditingController _contractorDescription;
  bool _bound = false;

  @override
  void initState() {
    super.initState();
    _chainage = TextEditingController();
    _location = TextEditingController();
    _representative = TextEditingController();
    _contractorDescription = TextEditingController();
  }

  @override
  void dispose() {
    _chainage.dispose();
    _location.dispose();
    _representative.dispose();
    _contractorDescription.dispose();
    super.dispose();
  }

  void _syncControllers(RfiInspectionFlowState state) {
    if (_bound && state.loading) {
      return;
    }
    void setIfChanged(TextEditingController c, String value) {
      if (c.text != value) {
        c.value = TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        );
      }
    }

    setIfChanged(_chainage, state.chainage);
    setIfChanged(_location, state.location);
    setIfChanged(_representative, state.contractorRepresentative);
    setIfChanged(_contractorDescription, state.contractorDescription);
    _bound = true;
  }

  Future<void> _captureSelfie(RfiInspectionFlowController notifier) async {
    try {
      // Debug builds may take the selfie from the photo library (the iOS
      // Simulator has no camera). Release builds are camera-only.
      ImageSource source = ImageSource.camera;
      if (kDebugMode) {
        final ImageSource? picked = await showModalBottomSheet<ImageSource>(
          context: context,
          showDragHandle: true,
          builder: (BuildContext sheet) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(sheet, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Photo library (debug only)'),
                  onTap: () => Navigator.pop(sheet, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
        if (picked == null) {
          return;
        }
        source = picked;
      }
      final XFile? file = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (file == null) {
        return;
      }
      notifier.updateSelfie(file.path);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Selfie failed',
        message: rfiInspectionErrorMessage(error),
      );
    }
  }

  Future<void> _pickSiteImage(
    RfiInspectionFlowController notifier, {
    required ImageSource source,
  }) async {
    try {
      // Resize before upload: full camera photos are 3–8 MB, slow to send
      // and slow to decode again for the thumbnail.
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      if (file == null) {
        return;
      }
      await notifier.uploadSiteImage(file.path);
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Uploaded',
        message: 'Site image uploaded successfully.',
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Upload failed',
        message: rfiInspectionErrorMessage(error),
      );
    }
  }

  Future<String?> _pickPdf() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['pdf'],
      withData: false,
    );
    final String? path = result?.files.single.path;
    if (path == null || path.isEmpty) {
      return null;
    }
    if (!path.toLowerCase().endsWith('.pdf')) {
      if (!mounted) {
        return null;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Invalid file',
        message: 'Please select a PDF file.',
      );
      return null;
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final RfiInspectionFlowState state =
        ref.watch(rfiInspectionFlowControllerProvider(widget.args));
    final RfiInspectionFlowController notifier =
        ref.read(rfiInspectionFlowControllerProvider(widget.args).notifier);
    _syncControllers(state);
    // Includes the /inspection-access fallback for unrecognised user types.
    final RfiUserRole role = notifier.role;
    final String title = state.currentStep == 1
        ? 'RFI Inspection - Step 1'
        : 'RFI Inspection - Step 2';

    return PopScope(
      canPop: state.currentStep == 1 && !state.busy,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop || state.busy) {
          return;
        }
        if (state.currentStep == 2) {
          notifier.setStep(1);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: state.busy
                ? null
                : () {
                    if (state.currentStep == 2) {
                      notifier.setStep(1);
                    } else if (context.canPop()) {
                      context.pop();
                    }
                  },
          ),
        ),
        body: _compactButtons(
          context,
          Stack(
          children: <Widget>[
            if (state.loading)
              const AppFullscreenLoader()
            else if (state.details == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.error == null
                        ? 'Unable to load inspection details.'
                        : rfiInspectionErrorMessage(state.error!),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Column(
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFD6E4F5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.brandPrimary,
                          ),
                    ),
                  ),
                  Expanded(
                    child: state.currentStep == 1
                        ? _buildStep1(context, state, notifier)
                        : _buildStep2(context, state, notifier, role),
                  ),
                ],
              ),
            if (state.busy)
              const AppFullscreenLoader.blocking(),
          ],
        ),
        ),
      ),
    );
  }

  /// The app theme makes filled/outlined buttons full width
  /// (`Size.fromHeight`). On this screen buttons sit in rows, where that
  /// width is infinite and breaks layout, so size them to their content.
  Widget _compactButtons(BuildContext context, Widget child) {
    final ThemeData theme = Theme.of(context);
    const WidgetStatePropertyAll<Size> size = WidgetStatePropertyAll<Size>(
      Size(0, 44),
    );
    return Theme(
      data: theme.copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style: (theme.filledButtonTheme.style ?? const ButtonStyle())
              .copyWith(minimumSize: size),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: (theme.outlinedButtonTheme.style ?? const ButtonStyle())
              .copyWith(minimumSize: size),
        ),
      ),
      child: child,
    );
  }

  Widget _buildStep1(
    BuildContext context,
    RfiInspectionFlowState state,
    RfiInspectionFlowController notifier,
  ) {
    final RfiInspectionDetailRfi rfi = state.details!.rfi;
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: <Widget>[
              _readonlyField('RFI ID', rfi.rfiId),
              _readonlyField('Project', rfi.project),
              _readonlyField('Contract', rfi.contract),
              _readonlyField('Structure Type', rfi.structureType),
              _readonlyField('Structure', rfi.structure),
              _readonlyField('RFI Description', rfi.rfiDescription),
              _readonlyField('Description', rfi.description),
              Text('Chainage', style: Theme.of(context).textTheme.labelLarge),
              TextField(
                controller: _chainage,
                decoration: const InputDecoration(
                  isDense: true,
                  border: UnderlineInputBorder(),
                ),
                onChanged: notifier.updateChainage,
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text.rich(
                    TextSpan(
                      text: 'Selfie ',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      children: const <InlineSpan>[
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Color(0xFFC1121F)),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Column(
                    children: <Widget>[
                      InkWell(
                        onTap: state.busy
                            ? null
                            : () => _captureSelfie(notifier),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E4F8A),
                            borderRadius: BorderRadius.circular(12),
                            image: state.hasSelfie
                                ? DecorationImage(
                                    image: FileImage(File(state.selfiePath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: state.hasSelfie
                              ? null
                              : const Icon(
                                  Icons.photo_camera,
                                  color: Colors.white,
                                  size: 36,
                                ),
                        ),
                      ),
                      if (!state.hasSelfie)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            '*Selfie required',
                            style: TextStyle(
                              color: Color(0xFFC1121F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: !state.canGoNext
                    ? null
                    : () async {
                        try {
                          notifier.continueToStep2();
                        } on Object catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          await AppDialog.show(
                            context,
                            variant: AppDialogVariant.error,
                            title: 'Could not continue',
                            message: rfiInspectionErrorMessage(error),
                          );
                        }
                      },
                style: FilledButton.styleFrom(backgroundColor: AppTheme.brandPrimary),
                child: const Text('Next'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(
    BuildContext context,
    RfiInspectionFlowState state,
    RfiInspectionFlowController notifier,
    RfiUserRole role,
  ) {
    final RfiInspectionDetails details = state.details!;
    final RfiInspectionDetailRfi rfi = details.rfi;
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: <Widget>[
              _requiredLabel('Location'),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _location,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: UnderlineInputBorder(),
                      ),
                      onChanged: notifier.updateLocation,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh location',
                    onPressed: state.locationLoading
                        ? null
                        : () async {
                            await notifier.fetchLocation();
                            if (!context.mounted) {
                              return;
                            }
                            final RfiInspectionFlowState latest = ref.read(
                              rfiInspectionFlowControllerProvider(
                                widget.args,
                              ),
                            );
                            if (latest.locationPermissionDenied) {
                              await AppDialog.show(
                                context,
                                variant: AppDialogVariant.warning,
                                title: 'Location permission',
                                message:
                                    'Location permission is required to capture the inspection location.',
                              );
                            }
                          },
                    icon: state.locationLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _readonlyField('Date of Inspection', state.dateOfInspection),
              _readonlyField('Time of Inspection', state.timeOfInspection),
              Text(
                "Contractor's Representative",
                style: Theme.of(context).textTheme.labelLarge,
              ),
              TextField(
                controller: _representative,
                decoration: const InputDecoration(
                  isDense: true,
                  border: UnderlineInputBorder(),
                ),
                onChanged: notifier.updateContractorRepresentative,
              ),
              const SizedBox(height: 16),
              Text(
                'Upload Site Image',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.brandPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  IconButton.filled(
                    onPressed: state.busy
                        ? null
                        : () => _pickSiteImage(
                              notifier,
                              source: ImageSource.camera,
                            ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.brandPrimary,
                    ),
                    icon: const Icon(Icons.photo_camera),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: state.busy
                        ? null
                        : () => _pickSiteImage(
                              notifier,
                              source: ImageSource.gallery,
                            ),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Choose File'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Site Images Uploaded',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _siteImagesRow(
                      'Contractor Site Images',
                      rfi.conSiteImgs,
                      onDelete: !state.busy && notifier.uploadedBy == 'CON'
                          ? (String path) => _deleteSiteImage(notifier, path)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    _siteImagesRow(
                      'Engineer Site Images',
                      rfi.enggSiteImgs,
                      onDelete: !state.busy && notifier.uploadedBy != 'CON'
                          ? (String path) => _deleteSiteImage(notifier, path)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Enclosures *',
                child: details.enclosures.isEmpty
                    ? const Text('No enclosures configured.')
                    : _scrollTable(
                        columns: _enclosureColumns,
                        rows: <List<Widget>>[
                          for (final RfiInspectionEnclosure enclosure
                              in details.enclosures)
                            _enclosureCells(
                              context,
                              state,
                              notifier,
                              role,
                              enclosure,
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Supporting Documents',
                child: Column(
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: state.busy
                          ? null
                          : () async {
                              final String? path = await _pickPdf();
                              if (path == null) {
                                return;
                              }
                              notifier.addSupportingDoc(path);
                            },
                      icon: const Icon(Icons.add),
                      label: const Text('+ Add Document'),
                    ),
                    const SizedBox(height: 8),
                    for (int i = 0;
                        i < state.supportingDocuments.length;
                        i++)
                      _supportingDocRow(state, notifier, i),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: notifier.isEngineer
                    ? 'Description By Client'
                    : 'Description By Contractor',
                child: TextField(
                  controller: _contractorDescription,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Enter your comments here',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: notifier.updateContractorDescription,
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Measurements *',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _scrollTable(
                      columns: _measurementColumns,
                      rows: <List<Widget>>[
                        for (int i = 0; i < state.measurements.length; i++)
                          _measurementCells(state, notifier, i),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: notifier.addMeasurementRow,
                      icon: const Icon(Icons.add),
                      label: const Text('Add measurement row'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Confirm Inspection *',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (notifier.isEngineer) ...<Widget>[
                      const Text('Inspection Status *'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        key: ValueKey<String>(
                          'engg-status-${state.engineerStatus}',
                        ),
                        initialValue: state.engineerStatus.isEmpty
                            ? null
                            : state.engineerStatus,
                        hint: const Text('Select Inspection Status'),
                        items: <DropdownMenuItem<String>>[
                          for (final (String value, String label)
                              in rfiEngineerStatusOptions(
                                offline: widget.args.offline,
                              ))
                            DropdownMenuItem<String>(
                              value: value,
                              child: Text(label),
                            ),
                        ],
                        onChanged: state.busy
                            ? null
                            : (String? value) {
                                if (value != null) {
                                  notifier.updateEngineerStatus(value);
                                }
                              },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      if (state.engineerStatus.isNotEmpty &&
                              state.engineerStatus != rfiInspectionAccepted ||
                          state.engineerRemarks.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 12),
                        const Text('Remarks By Client *'),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: state.engineerRemarks,
                          minLines: 3,
                          maxLines: 5,
                          maxLength: 1000,
                          decoration: const InputDecoration(
                            hintText: 'Enter remarks',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: notifier.updateEngineerRemarks,
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                    const Text('Tests in Site/Lab'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: state.testInSiteLab,
                      items: rfiInspectionTestOptions(state.testInSiteLab)
                          .map(
                            (String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: state.busy
                          ? null
                          : (String? value) {
                              if (value != null) {
                                notifier.updateTestInSiteLab(value);
                              }
                            },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    if (state.testInSiteLab == 'Lab Test' ||
                        state.testInSiteLab == 'Site Test') ...<Widget>[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: state.busy
                            ? null
                            : () async {
                                final String? path = await _pickPdf();
                                if (path == null) {
                                  return;
                                }
                                notifier.updateTestReport(path);
                              },
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          state.testReportPath == null
                              ? 'Upload Test Report'
                              : 'Test report selected',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: state.busy
                        ? null
                        : () async {
                            final bool? confirmed = await AppDialog.show(
                              context,
                              variant: AppDialogVariant.confirm,
                              title: 'Close inspection',
                              message:
                                  'Close without submitting? Unsaved changes may be lost.',
                            );
                            if (confirmed == true &&
                                context.mounted &&
                                context.canPop()) {
                              context.pop();
                            }
                          },
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.brandPrimary),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: state.busy
                        ? null
                        : () async {
                            try {
                              await notifier.saveAsDraft();
                              if (!context.mounted) {
                                return;
                              }
                              await AppDialog.show(
                                context,
                                variant: AppDialogVariant.success,
                                title: 'Draft saved',
                                message: 'Draft saved successfully.',
                              );
                            } on Object catch (error) {
                              if (!context.mounted) {
                                return;
                              }
                              await AppDialog.show(
                                context,
                                variant: AppDialogVariant.error,
                                title: 'Save draft failed',
                                message: rfiInspectionErrorMessage(error),
                              );
                            }
                          },
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.brandPrimary),
                    child: const Text('Save Draft'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: state.busy || !notifier.isStep2Valid()
                        ? null
                        : () => _onSubmitPressed(notifier),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF198754),
                    ),
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Enclosures table, laid out like the web: RFI Description, Enclosure,
  /// Action (Open / Upload) and Uploaded (View / Download or ---).
  static const List<(String, double)> _enclosureColumns = <(String, double)>[
    ('RFI Description', 150),
    ('Enclosure', 180),
    ('Action', 190),
    ('Uploaded', 190),
  ];

  List<Widget> _enclosureCells(
    BuildContext context,
    RfiInspectionFlowState state,
    RfiInspectionFlowController notifier,
    RfiUserRole role,
    RfiInspectionEnclosure enclosure,
  ) {
    return <Widget>[
      Text(enclosure.rfiDescription, textAlign: TextAlign.center),
      Text(enclosure.enclosureName, textAlign: TextAlign.center),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: <Widget>[
              OutlinedButton(
                  onPressed: state.busy
                      ? null
                      : () => showRfiChecklistDialog(
                            context: context,
                            controller: notifier,
                            enclosure: enclosure,
                            details: state.details!,
                            role: role,
                          ),
                  child: const Text('Open'),
                ),
              OutlinedButton(
                  onPressed: state.busy
                      ? null
                      : () async {
                          final String? path = await _pickPdf();
                          if (path == null) {
                            return;
                          }
                          try {
                            await notifier.uploadEnclosure(
                              filePath: path,
                              enclosure: enclosure,
                            );
                            if (!context.mounted) {
                              return;
                            }
                            await AppDialog.show(
                              context,
                              variant: AppDialogVariant.success,
                              title: 'Uploaded',
                              message: 'Enclosure uploaded successfully.',
                            );
                          } on Object catch (error) {
                            if (!context.mounted) {
                              return;
                            }
                            await AppDialog.show(
                              context,
                              variant: AppDialogVariant.error,
                              title: 'Upload failed',
                              message: rfiInspectionErrorMessage(error),
                            );
                          }
                        },
                  child: const Text('Upload'),
                ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: <Widget>[
              if (enclosure.enclosureUploadedFile.isNotEmpty) ...<Widget>[
                OutlinedButton(
                  onPressed: state.busy
                      ? null
                      : () => _viewEnclosure(notifier, enclosure),
                  child: const Text('View'),
                ),
                OutlinedButton(
                  onPressed: state.busy
                      ? null
                      : () => _downloadEnclosure(notifier, enclosure),
                  child: const Text('Download'),
                ),
                if (enclosure.enclosureUploadedFileId != null)
                  FilledButton(
                    onPressed: state.busy
                        ? null
                        : () => _removeEnclosure(notifier, enclosure),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD9534F),
                    ),
                    child: const Text('Remove'),
                  ),
              ] else
                const Text('---'),
            ],
          ),
    ];
  }

  /// Web checks before submitting: engineer status/remarks, the checklist
  /// YES/NO auto-reject, and the rectification confirmation.
  Future<void> _onSubmitPressed(RfiInspectionFlowController notifier) async {
    if (notifier.isEngineer) {
      final String? problem = rfiEngineerSubmitError(
        ref.read(rfiInspectionFlowControllerProvider(widget.args)),
      );
      if (problem != null) {
        await AppDialog.show(
          context,
          variant: AppDialogVariant.warning,
          title: 'Inspection status',
          message: problem,
        );
        return;
      }
      if (!notifier.isRfiNotRequired &&
          !notifier.isReturningForRectification &&
          await notifier.checklistConflict()) {
        notifier.updateEngineerStatus(rfiInspectionRejected);
        if (!mounted) {
          return;
        }
        await AppDialog.show(
          context,
          variant: AppDialogVariant.warning,
          title: 'Inspection auto-rejected',
          message:
              'Contractor marked YES but Engineer marked NO — Inspection auto-rejected.',
        );
      }
    }
    if (!mounted) {
      return;
    }
    final bool confirmed = await AppDialog.confirm(
      context,
      title: notifier.isReturningForRectification
          ? 'Return for rectification'
          : 'Submit inspection',
      message: notifier.isReturningForRectification
          ? 'Are you sure you want to return this for rectification?'
          : 'Submit this RFI inspection now?',
    );
    if (!confirmed || !mounted) {
      return;
    }
    await _submitWithProgress(notifier);
  }

  /// Submit with the web's step-by-step progress dialog.
  Future<void> _submitWithProgress(
    RfiInspectionFlowController notifier,
  ) async {
    final RfiSubmitProgress progress = RfiSubmitProgress(
      steps: rfiSubmitSteps(
        rectification: notifier.isReturningForRectification,
      ),
    );
    final Future<void> dialog = showRfiSubmitProgressDialog(context, progress);
    try {
      final String message = await notifier.submitWithSteps(progress.update);
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Submitted',
        message: message.trim().isEmpty
            ? 'Inspection submitted successfully.'
            : message,
      );
      if (mounted && context.canPop()) {
        context.pop(true);
      }
    } on RfiSubmitStepFailure catch (failure) {
      progress.fail(rfiSubmitStepMessage(failure));
      await dialog;
    } on Object catch (error) {
      progress.fail(rfiInspectionErrorMessage(error));
      await dialog;
    } finally {
      progress.dispose();
    }
  }

  Future<Uint8List?> _fetchEnclosure(
    RfiInspectionFlowController notifier,
    RfiInspectionEnclosure enclosure,
  ) => _fetchPdf(notifier, enclosure.enclosureUploadedFile, onServer: true);

  /// PDF bytes from the phone ([onServer] false) or from the server via
  /// DownloadPrev. Shows an error and returns null when it can't be read.
  Future<Uint8List?> _fetchPdf(
    RfiInspectionFlowController notifier,
    String path, {
    required bool onServer,
  }) async {
    try {
      final Uint8List bytes = onServer
          ? await notifier.downloadEnclosure(path)
          : await File(path).readAsBytes();
      if (!RfiStoredFile.looksLikePdf(bytes)) {
        throw StateError('Not a PDF.');
      }
      return bytes;
    } on Object catch (error) {
      if (mounted) {
        await AppDialog.show(
          context,
          variant: AppDialogVariant.error,
          title: 'File unavailable',
          message: error is StateError
              ? 'This file could not be opened.'
              : rfiInspectionErrorMessage(error),
        );
      }
      return null;
    }
  }

  /// View: the uploaded PDF in an in-app preview.
  Future<void> _viewEnclosure(
    RfiInspectionFlowController notifier,
    RfiInspectionEnclosure enclosure,
  ) async {
    final Uint8List? bytes = await _fetchEnclosure(notifier, enclosure);
    if (bytes == null || !mounted) {
      return;
    }
    await _previewPdf(
      bytes,
      RfiStoredFile.fileName(enclosure.enclosureUploadedFile),
    );
  }

  Future<void> _previewPdf(Uint8List bytes, String name) async {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) => Scaffold(
          appBar: AppBar(title: Text(name)),
          body: PdfPreview(
            build: (_) async => bytes,
            pdfFileName: name,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            allowPrinting: false,
            allowSharing: true,
          ),
        ),
      ),
    );
  }

  /// Download: hands the PDF to the share sheet (Save to Files, etc.).
  Future<void> _downloadEnclosure(
    RfiInspectionFlowController notifier,
    RfiInspectionEnclosure enclosure,
  ) async {
    final Uint8List? bytes = await _fetchEnclosure(notifier, enclosure);
    if (bytes == null || !mounted) {
      return;
    }
    await shareRfiLogFile(
      bytes: bytes,
      fileName: RfiStoredFile.fileName(enclosure.enclosureUploadedFile),
      sharePositionOrigin: _shareOrigin(),
    );
  }

  Rect _shareOrigin() {
    final Size size = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 2,
      height: 2,
    );
  }

  Future<void> _removeEnclosure(
    RfiInspectionFlowController notifier,
    RfiInspectionEnclosure enclosure,
  ) async {
    final bool confirmed = await AppDialog.confirm(
      context,
      title: 'Remove file',
      message: 'Remove this uploaded enclosure file? This cannot be undone.',
      primaryLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      await notifier.deleteEnclosureFile(enclosure.enclosureUploadedFileId!);
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Removed',
        message: 'Enclosure file removed.',
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Remove failed',
        message: rfiInspectionErrorMessage(error),
      );
    }
  }

  Future<void> _viewSupportingDoc(
    RfiInspectionFlowController notifier,
    RfiLocalSupportingDoc doc,
  ) async {
    final Uint8List? bytes = await _fetchPdf(
      notifier,
      doc.path,
      onServer: doc.onServer,
    );
    if (bytes == null || !mounted) {
      return;
    }
    await _previewPdf(bytes, RfiStoredFile.fileName(doc.path));
  }

  Future<void> _downloadSupportingDoc(
    RfiInspectionFlowController notifier,
    RfiLocalSupportingDoc doc,
  ) async {
    final Uint8List? bytes = await _fetchPdf(
      notifier,
      doc.path,
      onServer: doc.onServer,
    );
    if (bytes == null || !mounted) {
      return;
    }
    await shareRfiLogFile(
      bytes: bytes,
      fileName: RfiStoredFile.fileName(doc.path),
      sharePositionOrigin: _shareOrigin(),
    );
  }

  Widget _supportingDocRow(
    RfiInspectionFlowState state,
    RfiInspectionFlowController notifier,
    int index,
  ) {
    final RfiLocalSupportingDoc doc = state.supportingDocuments[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFFE8EEF5),
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontSize: 12, color: AppTheme.brandPrimary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: doc.description,
              decoration: const InputDecoration(
                hintText: 'Enter document description',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (String value) =>
                  notifier.updateSupportingDocDescription(index, value),
            ),
          ),
          IconButton(
            tooltip: 'View',
            onPressed: state.busy
                ? null
                : () => _viewSupportingDoc(notifier, doc),
            icon: const Icon(Icons.visibility_outlined),
          ),
          IconButton(
            tooltip: 'Download',
            onPressed: state.busy
                ? null
                : () => _downloadSupportingDoc(notifier, doc),
            icon: const Icon(Icons.download_rounded),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: () => notifier.removeSupportingDoc(index),
            icon: const Icon(Icons.delete_outline, color: Color(0xFFC1121F)),
          ),
        ],
      ),
    );
  }

  /// Measurements table, laid out like the web. Fields a type does not use
  /// are disabled; Percent locks Units to % and takes a typed Total Qty.
  static const List<(String, double)> _measurementColumns = <(String, double)>[
    ('Component', 120),
    ('Element', 130),
    ('Activity', 160),
    ('Type of Measurement', 150),
    ('Units', 110),
    ('Length', 90),
    ('Breadth', 90),
    ('Height', 90),
    ('Weight', 90),
    ('No.', 90),
    ('Total Qty', 100),
  ];

  List<Widget> _measurementCells(
    RfiInspectionFlowState state,
    RfiInspectionFlowController notifier,
    int index,
  ) {
    final RfiInspectionMeasurementRow row = state.measurements[index];
    final WorkRfiMeasureFields fields = workRfiFieldsFor(row.type);
    final List<String> units = rfiInspectionUnitOptions(row.type, row.units);
    final bool unitsEditable = workRfiUnitsFor(row.type).length > 1;
    void update(RfiInspectionMeasurementRow next) =>
        notifier.updateMeasurement(index, next);
    String qtyText(double v) =>
        v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);
    return <Widget>[
      Text(row.component.isEmpty ? '—' : row.component),
      Text(row.element.isEmpty ? '—' : row.element),
      row.activityName.isEmpty
          ? _cellField(
              key: 'activity-$index',
              value: row.activityName,
              enabled: true,
              numeric: false,
              onChanged: (String v) => update(row.copyWith(activityName: v)),
            )
          : Text(row.activityName),
      _cellDropdown(
        key: 'type-$index-${row.type}',
        value: row.type,
        items: rfiInspectionTypeOptions(row.type),
        enabled: !state.busy,
        onChanged: (String v) => update(row.copyWith(type: v)),
      ),
      _cellDropdown(
        key: 'units-$index-${row.type}-${row.units}',
        value: row.units,
        items: units,
        enabled: unitsEditable && !state.busy,
        onChanged: (String v) => update(row.copyWith(units: v)),
      ),
      _cellField(
        key: 'l-$index-${row.type}',
        value: row.length,
        enabled: fields.length,
        onChanged: (String v) => update(row.copyWith(length: v)),
      ),
      _cellField(
        key: 'b-$index-${row.type}',
        value: row.breadth,
        enabled: fields.breadth,
        onChanged: (String v) => update(row.copyWith(breadth: v)),
      ),
      _cellField(
        key: 'h-$index-${row.type}',
        value: row.height,
        enabled: fields.height,
        onChanged: (String v) => update(row.copyWith(height: v)),
      ),
      _cellField(
        key: 'w-$index-${row.type}',
        value: row.weight,
        enabled: fields.weight,
        onChanged: (String v) => update(row.copyWith(weight: v)),
      ),
      _cellField(
        key: 'n-$index-${row.type}',
        value: row.no,
        enabled: fields.no,
        onChanged: (String v) => update(row.copyWith(no: v)),
      ),
      fields.totalQty
          ? _cellField(
              key: 't-$index-${row.type}',
              value: row.totalQty == 0 ? '' : qtyText(row.totalQty),
              enabled: true,
              onChanged: (String v) =>
                  update(row.copyWith(totalQty: double.tryParse(v) ?? 0)),
            )
          : _cellField(
              key: 'tc-$index-${row.type}-${row.totalQty}',
              value: row.totalQty == 0 ? '' : qtyText(row.totalQty),
              enabled: false,
              onChanged: (_) {},
            ),
    ];
  }

  Widget _cellField({
    required String key,
    required String value,
    required bool enabled,
    required ValueChanged<String> onChanged,
    bool numeric = true,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return TextFormField(
      key: ValueKey<String>(key),
      initialValue: value,
      enabled: enabled,
      textAlign: numeric ? TextAlign.center : TextAlign.start,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        isDense: true,
        filled: !enabled,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }

  Widget _cellDropdown({
    required String key,
    required String value,
    required List<String> items,
    required bool enabled,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey<String>(key),
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(),
      ),
      items: items
          .map(
            (String v) => DropdownMenuItem<String>(
              value: v,
              child: Text(v, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: enabled
          ? (String? v) {
              if (v != null) {
                onChanged(v);
              }
            }
          : null,
    );
  }

  /// A web-style table that scrolls sideways: tinted header row, fixed
  /// column widths, a divider under each row.
  Widget _scrollTable({
    required List<(String, double)> columns,
    required List<List<Widget>> rows,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool dark = scheme.brightness == Brightness.dark;
    final Color headerFill = dark
        ? const Color(0xFF1B3556)
        : const Color(0xFFE8F1FB);
    final BorderSide line = BorderSide(color: scheme.outlineVariant);
    Widget cell(double width, Widget child, {Color? color}) => Container(
      width: width,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      alignment: Alignment.center,
      child: child,
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border.fromBorderSide(line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                for (final (String label, double width) in columns)
                  cell(
                    width,
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.brandPrimary,
                      ),
                    ),
                    color: headerFill,
                  ),
              ],
            ),
            for (final List<Widget> cells in rows)
              DecoratedBox(
                decoration: BoxDecoration(border: Border(top: line)),
                child: Row(
                  children: <Widget>[
                    for (int i = 0; i < columns.length; i++)
                      cell(columns[i].$2, cells[i]),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Confirms, deletes one site image and shows the result. The controller
  /// reloads the RFI afterwards so the thumbnails match the server.
  Future<void> _deleteSiteImage(
    RfiInspectionFlowController notifier,
    String path,
  ) async {
    final bool confirmed = await AppDialog.confirm(
      context,
      title: 'Delete site image',
      message: 'Delete this site image? This cannot be undone.',
      primaryLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      await notifier.deleteSiteImage(path);
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Deleted',
        message: 'Site image deleted successfully.',
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Delete failed',
        message: rfiInspectionErrorMessage(error),
      );
    }
  }

  Widget _siteImagesRow(
    String label,
    List<String> images, {
    ValueChanged<String>? onDelete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        if (images.isEmpty)
          const Text('No images uploaded')
        else
          RfiServerImageGrid(paths: images, onDelete: onDelete),
      ],
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x661E4F8A)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.brandPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _requiredLabel(String label) {
    return Text.rich(
      TextSpan(
        text: label,
        style: const TextStyle(fontWeight: FontWeight.w600),
        children: const <InlineSpan>[
          TextSpan(text: ' *', style: TextStyle(color: Color(0xFFC1121F))),
        ],
      ),
    );
  }

  Widget _readonlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value.isEmpty ? '—' : value),
          const Divider(height: 16),
        ],
      ),
    );
  }
}
