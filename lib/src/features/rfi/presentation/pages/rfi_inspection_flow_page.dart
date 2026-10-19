import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_details.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_user_role.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_inspection_flow_provider.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/rfi_inspection_errors.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_checklist_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

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
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
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
      final XFile? file = source == ImageSource.gallery
          ? await _picker.pickImage(source: ImageSource.gallery)
          : await _picker.pickImage(source: ImageSource.camera);
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

  Future<void> _openPath(String path) async {
    final Uri uri = path.startsWith('http')
        ? Uri.parse(path)
        : Uri.file(path);
    final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Unable to open',
        message: 'Could not open the selected file.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final RfiInspectionFlowState state =
        ref.watch(rfiInspectionFlowControllerProvider(widget.args));
    final RfiInspectionFlowController notifier =
        ref.read(rfiInspectionFlowControllerProvider(widget.args).notifier);
    _syncControllers(state);
    final RfiUserRole role = RfiUserRoleResolver.fromSession(
      ref.watch(authControllerProvider).valueOrNull,
    );
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
        body: Stack(
          children: <Widget>[
            if (state.loading)
              const Center(child: CircularProgressIndicator())
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
              const ColoredBox(
                color: Color(0x66000000),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
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
                          await notifier.saveStep1AndContinue();
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
                    ),
                    const SizedBox(height: 8),
                    _siteImagesRow(
                      'Engineer Site Images',
                      rfi.enggSiteImgs,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Enclosures *',
                child: Column(
                  children: details.enclosures.isEmpty
                      ? <Widget>[
                          const Text('No enclosures configured.'),
                        ]
                      : details.enclosures
                          .map(
                            (RfiInspectionEnclosure enclosure) =>
                                _enclosureTile(
                              context,
                              state,
                              notifier,
                              role,
                              enclosure,
                            ),
                          )
                          .toList(),
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
                title: 'Description By Contractor',
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
                  children: <Widget>[
                    for (int i = 0; i < state.measurements.length; i++)
                      _measurementEditor(state, notifier, i),
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
                    const Text('Tests in Site/Lab'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: state.testInSiteLab,
                      items: const <String>[
                        'Visual',
                        'Lab Test',
                        'Site Test',
                      ]
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
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: <Widget>[
                FilledButton(
                  onPressed: state.busy ? null : () => notifier.setStep(1),
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.brandPrimary),
                  child: const Text('Back'),
                ),
                FilledButton(
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
                  child: const Text('Save As Draft'),
                ),
                FilledButton(
                  onPressed: state.busy || !notifier.isStep2Valid()
                      ? null
                      : () async {
                          final bool? confirmed = await AppDialog.show(
                            context,
                            variant: AppDialogVariant.confirm,
                            title: 'Submit inspection',
                            message:
                                'Submit this RFI inspection now?',
                          );
                          if (confirmed != true) {
                            return;
                          }
                          try {
                            final String message = await notifier.submit();
                            if (!context.mounted) {
                              return;
                            }
                            await AppDialog.show(
                              context,
                              variant: AppDialogVariant.success,
                              title: 'Submitted',
                              message: message,
                            );
                            if (context.mounted && context.canPop()) {
                              context.pop(true);
                            }
                          } on Object catch (error) {
                            if (!context.mounted) {
                              return;
                            }
                            await AppDialog.show(
                              context,
                              variant: AppDialogVariant.error,
                              title: 'Submit failed',
                              message: rfiInspectionErrorMessage(error),
                            );
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF198754),
                  ),
                  child: const Text('Submit'),
                ),
                FilledButton(
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _enclosureTile(
    BuildContext context,
    RfiInspectionFlowState state,
    RfiInspectionFlowController notifier,
    RfiUserRole role,
    RfiInspectionEnclosure enclosure,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x331E4F8A)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            enclosure.rfiDescription.isEmpty
                ? '—'
                : enclosure.rfiDescription,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(enclosure.enclosureName),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (enclosure.hasOpenAction)
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
              if (enclosure.hasUploadAction || !enclosure.hasOpenAction)
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
              if (enclosure.hasUploadedFile) ...<Widget>[
                OutlinedButton(
                  onPressed: () => _openPath(enclosure.enclosureUploadedFile),
                  child: const Text('View'),
                ),
                OutlinedButton(
                  onPressed: () => _openPath(enclosure.enclosureUploadedFile),
                  child: const Text('Download'),
                ),
              ] else
                const Text('Uploaded: ---'),
            ],
          ),
        ],
      ),
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
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _openPath(doc.path),
            child: const Text('View'),
          ),
          const SizedBox(width: 4),
          OutlinedButton(
            onPressed: () => _openPath(doc.path),
            child: const Text('Download'),
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: () => notifier.removeSupportingDoc(index),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC1121F),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _measurementEditor(
    RfiInspectionFlowState state,
    RfiInspectionFlowController notifier,
    int index,
  ) {
    final RfiInspectionMeasurementRow row = state.measurements[index];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x331E4F8A)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: <Widget>[
          TextFormField(
            initialValue: row.activityName,
            decoration: const InputDecoration(
              labelText: 'Activity Name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (String value) => notifier.updateMeasurement(
              index,
              row.copyWith(activityName: value),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: row.type,
            decoration: const InputDecoration(
              labelText: 'Type of Measurement',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const <String>[
              'Select',
              'Area',
              'Length',
              'Volume',
              'Number',
              'Weight',
            ]
                .map(
                  (String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(),
            onChanged: (String? value) {
              if (value != null) {
                notifier.updateMeasurement(index, row.copyWith(type: value));
              }
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: row.units,
            decoration: const InputDecoration(
              labelText: 'Units',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const <String>[
              'Select U',
              'sqm',
              'm',
              'cum',
              'nos',
              'kg',
            ]
                .map(
                  (String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(),
            onChanged: (String? value) {
              if (value != null) {
                notifier.updateMeasurement(index, row.copyWith(units: value));
              }
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _dimField('Length', row.length, (String v) {
                notifier.updateMeasurement(index, row.copyWith(length: v));
              }),
              _dimField('Breadth', row.breadth, (String v) {
                notifier.updateMeasurement(index, row.copyWith(breadth: v));
              }),
              _dimField('Height', row.height, (String v) {
                notifier.updateMeasurement(index, row.copyWith(height: v));
              }),
              _dimField('Weight', row.weight, (String v) {
                notifier.updateMeasurement(index, row.copyWith(weight: v));
              }),
              _dimField('No.', row.no, (String v) {
                notifier.updateMeasurement(index, row.copyWith(no: v));
              }),
              SizedBox(
                width: 110,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Total Qty',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: Text(row.totalQty.toStringAsFixed(
                    row.totalQty == row.totalQty.roundToDouble() ? 0 : 2,
                  )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dimField(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return SizedBox(
      width: 110,
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: onChanged,
      ),
    );
  }

  Widget _siteImagesRow(String label, List<String> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        if (images.isEmpty)
          const Text('No images uploaded')
        else
          Wrap(
            spacing: 8,
            children: images
                .map(
                  (String path) => TextButton(
                    onPressed: () => _openPath(path),
                    child: Text(path.split('/').last),
                  ),
                )
                .toList(),
          ),
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
