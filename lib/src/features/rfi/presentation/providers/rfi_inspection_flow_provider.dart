import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_inspection_flow_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_checklist_item.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_details.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_uploaded_by.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_user_role.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/rfi_inspection_errors.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/work_rfi_form.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_final_submit_payload.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/rfi_inspection_pdf.dart';
import 'package:flutter/services.dart';

class RfiInspectionFlowArgs {
  const RfiInspectionFlowArgs({
    required this.rfiId,
    required this.rfiCategory,
    required this.offline,
  });

  final int rfiId;
  final String rfiCategory;
  final bool offline;

  String get inspectionMode => offline ? 'OFFLINE' : 'ONLINE';

  @override
  bool operator ==(Object other) {
    return other is RfiInspectionFlowArgs &&
        other.rfiId == rfiId &&
        other.rfiCategory == rfiCategory &&
        other.offline == offline;
  }

  @override
  int get hashCode => Object.hash(rfiId, rfiCategory, offline);
}

class RfiInspectionMeasurementRow {
  const RfiInspectionMeasurementRow({
    this.activityName = '',
    this.component = '',
    this.element = '',
    this.activityIdFk,
    this.type = 'Select',
    this.units = 'Select U',
    this.length = '',
    this.breadth = '',
    this.height = '',
    this.weight = '',
    this.no = '',
    this.totalQty = 0,
  });

  final String activityName;

  /// Shown in the table only, like the web; not edited or re-sent.
  final String component;
  final String element;

  /// The P6 activity this row measures; sent back as `activityIdFk`.
  final int? activityIdFk;
  final String type;
  final String units;
  final String length;
  final String breadth;
  final String height;
  final String weight;
  final String no;
  final double totalQty;

  RfiInspectionMeasurementRow copyWith({
    String? activityName,
    String? type,
    String? units,
    String? length,
    String? breadth,
    String? height,
    String? weight,
    String? no,
    double? totalQty,
  }) {
    return RfiInspectionMeasurementRow(
      activityName: activityName ?? this.activityName,
      component: component,
      element: element,
      activityIdFk: activityIdFk,
      type: type ?? this.type,
      units: units ?? this.units,
      length: length ?? this.length,
      breadth: breadth ?? this.breadth,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      no: no ?? this.no,
      totalQty: totalQty ?? this.totalQty,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'activityName': activityName,
      'measurementType': type == 'Select' ? null : type,
      'units': units == 'Select U' ? null : units,
      'length': double.tryParse(length),
      'breadth': double.tryParse(breadth),
      'height': double.tryParse(height),
      'weight': double.tryParse(weight),
      'noOfItems': int.tryParse(no),
      'totalQty': totalQty,
    };
  }
}

class RfiLocalSupportingDoc {
  const RfiLocalSupportingDoc({
    required this.path,
    this.description = '',
    this.onServer = false,
  });

  /// Phone file path for a newly picked PDF, or the server path of one that
  /// was already uploaded.
  final String path;
  final String description;

  /// True for documents loaded from the RFI; only new phone files are sent
  /// again with Submit.
  final bool onServer;

  bool get isNewUpload => !onServer && !path.startsWith('http');

  RfiLocalSupportingDoc copyWith({String? description}) {
    return RfiLocalSupportingDoc(
      path: path,
      description: description ?? this.description,
      onServer: onServer,
    );
  }
}

/// The new PDFs Submit uploads as `supportingFiles`, each with its typed
/// description, in the same order.
List<RfiLocalSupportingDoc> rfiSupportingUploads(
  List<RfiLocalSupportingDoc> docs,
) {
  return docs
      .where((RfiLocalSupportingDoc d) => d.isNewUpload && d.path.isNotEmpty)
      .toList(growable: false);
}

class RfiInspectionFlowState {
  const RfiInspectionFlowState({
    required this.args,
    this.details,
    this.currentStep = 1,
    this.loading = true,
    this.busy = false,
    this.error,
    this.selfiePath,
    this.chainage = '',
    this.location = '',
    this.dateOfInspection = '',
    this.timeOfInspection = '',
    this.contractorRepresentative = '',
    this.contractorDescription = '',
    this.testInSiteLab = 'Visual',
    this.testReportPath,
    this.conInspectionId,
    this.measurements = const <RfiInspectionMeasurementRow>[
      RfiInspectionMeasurementRow(),
    ],
    this.supportingDocuments = const <RfiLocalSupportingDoc>[],
    this.locationPermissionDenied = false,
    this.locationLoading = false,
    this.engineerStatus = '',
    this.engineerRemarks = '',
  });

  final RfiInspectionFlowArgs args;
  final RfiInspectionDetails? details;
  final int currentStep;
  final bool loading;
  final bool busy;
  final Object? error;
  final String? selfiePath;
  final String chainage;
  final String location;
  final String dateOfInspection;
  final String timeOfInspection;
  final String contractorRepresentative;
  final String contractorDescription;
  final String testInSiteLab;
  final String? testReportPath;
  final int? conInspectionId;
  final List<RfiInspectionMeasurementRow> measurements;
  final List<RfiLocalSupportingDoc> supportingDocuments;
  final bool locationPermissionDenied;
  final bool locationLoading;

  /// Engineer's decision: Accepted, Rejected or Returned_For_Rectification.
  final String engineerStatus;

  /// "Remarks By Client"; required unless the status is Accepted.
  final String engineerRemarks;

  bool get hasSelfie => selfiePath != null && selfiePath!.trim().isNotEmpty;

  bool get canGoNext => hasSelfie && !busy && !loading;

  RfiInspectionFlowState copyWith({
    RfiInspectionDetails? details,
    int? currentStep,
    bool? loading,
    bool? busy,
    Object? error = _keep,
    bool clearError = false,
    String? selfiePath = _keepString,
    bool clearSelfie = false,
    String? chainage,
    String? location,
    String? dateOfInspection,
    String? timeOfInspection,
    String? contractorRepresentative,
    String? contractorDescription,
    String? testInSiteLab,
    String? testReportPath = _keepString,
    bool clearTestReport = false,
    int? conInspectionId = _keepInt,
    List<RfiInspectionMeasurementRow>? measurements,
    List<RfiLocalSupportingDoc>? supportingDocuments,
    bool? locationPermissionDenied,
    bool? locationLoading,
    String? engineerStatus,
    String? engineerRemarks,
  }) {
    return RfiInspectionFlowState(
      args: args,
      details: details ?? this.details,
      currentStep: currentStep ?? this.currentStep,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearError
          ? null
          : (identical(error, _keep) ? this.error : error),
      selfiePath: clearSelfie
          ? null
          : (identical(selfiePath, _keepString) ? this.selfiePath : selfiePath),
      chainage: chainage ?? this.chainage,
      location: location ?? this.location,
      dateOfInspection: dateOfInspection ?? this.dateOfInspection,
      timeOfInspection: timeOfInspection ?? this.timeOfInspection,
      contractorRepresentative:
          contractorRepresentative ?? this.contractorRepresentative,
      contractorDescription:
          contractorDescription ?? this.contractorDescription,
      testInSiteLab: testInSiteLab ?? this.testInSiteLab,
      testReportPath: clearTestReport
          ? null
          : (identical(testReportPath, _keepString)
              ? this.testReportPath
              : testReportPath),
      conInspectionId: identical(conInspectionId, _keepInt)
          ? this.conInspectionId
          : conInspectionId,
      measurements: measurements ?? this.measurements,
      supportingDocuments: supportingDocuments ?? this.supportingDocuments,
      locationPermissionDenied:
          locationPermissionDenied ?? this.locationPermissionDenied,
      locationLoading: locationLoading ?? this.locationLoading,
      engineerStatus: engineerStatus ?? this.engineerStatus,
      engineerRemarks: engineerRemarks ?? this.engineerRemarks,
    );
  }
}

const Object _keep = Object();
const String _keepString = '__keep__';
const int _keepInt = -999999001;

final rfiInspectionFlowControllerProvider = NotifierProvider.autoDispose
    .family<RfiInspectionFlowController, RfiInspectionFlowState,
        RfiInspectionFlowArgs>(RfiInspectionFlowController.new);

class RfiInspectionFlowController
    extends AutoDisposeFamilyNotifier<RfiInspectionFlowState,
        RfiInspectionFlowArgs> {
  @override
  RfiInspectionFlowState build(RfiInspectionFlowArgs arg) {
    Future<void>.microtask(load);
    return RfiInspectionFlowState(args: arg);
  }

  RfiInspectionFlowRemoteDataSource get _source =>
      ref.read(rfiInspectionFlowRemoteDataSourceProvider);

  /// `/inspection-access` answer, used when the user type is not one the
  /// app recognises.
  String _accessType = '';

  RfiUserRole get role {
    final AuthSession? session = ref.read(authControllerProvider).valueOrNull;
    return rfiInspectionRole(
      RfiUserRoleResolver.fromSession(session),
      _accessType,
    );
  }

  String get uploadedBy => rfiInspectionUploadedBy(role);

  String get checklistUploadedBy => rfiChecklistUploadedBy(role);

  Future<void> load() async {
    if (_accessType.isEmpty) {
      try {
        _accessType = (await _source.fetchAccess(
          arg.rfiCategory.isEmpty ? 'WORK' : arg.rfiCategory,
        )).accessType;
      } on Object {
        _accessType = '';
      }
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final RfiInspectionDetails details =
          await _source.fetchDetails(arg.rfiId);
      final RfiInspectionDetailRfi rfi = details.rfi;
      final List<RfiInspectionMeasurementRow> rows =
          details.measurements.isEmpty
              ? <RfiInspectionMeasurementRow>[
                  const RfiInspectionMeasurementRow(),
                ]
              : details.measurements
                  .map(
                    (RfiInspectionMeasurement m) => RfiInspectionMeasurementRow(
                      activityName: m.activityName,
                      component: m.component,
                      element: m.element,
                      activityIdFk: m.activityIdFk,
                      type: m.measurementType.isEmpty
                          ? 'Select'
                          : m.measurementType,
                      units: m.units.isEmpty ? 'Select U' : m.units,
                      length: m.length,
                      breadth: m.breadth,
                      height: m.height,
                      weight: m.weight,
                      no: m.noOfItems,
                      totalQty: m.totalQty,
                    ),
                  )
                  .toList();
      final List<RfiLocalSupportingDoc> docs = rfi.conSupDocs
          .map(
            (RfiSupportingDocument d) => RfiLocalSupportingDoc(
              path: d.path,
              description: d.description,
              onServer: true,
            ),
          )
          .toList();
      state = state.copyWith(
        details: details,
        loading: false,
        chainage: state.chainage.isEmpty ? rfi.chainage : state.chainage,
        location: state.location.isEmpty ? rfi.location : state.location,
        dateOfInspection: rfi.dateOfInspection.isEmpty
            ? state.dateOfInspection
            : rfi.dateOfInspection,
        timeOfInspection: rfi.timeOfInspection.isEmpty
            ? state.timeOfInspection
            : rfi.timeOfInspection,
        contractorRepresentative: state.contractorRepresentative.isEmpty
            ? rfi.nameOfRepresentative
            : state.contractorRepresentative,
        testInSiteLab: rfi.testInSiteOrLab.isEmpty
            ? state.testInSiteLab
            : _displayTestType(rfi.testInSiteOrLab),
        conInspectionId: rfi.conInspectionId ?? state.conInspectionId,
        measurements: rows,
        supportingDocuments:
            state.supportingDocuments.isEmpty ? docs : state.supportingDocuments,
      );
    } on Object catch (error) {
      state = state.copyWith(loading: false, error: error);
    }
  }

  Future<void> refreshDetails() => load();

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
    if (step == 2 && state.location.trim().isEmpty) {
      fetchLocation();
    }
  }

  void updateChainage(String value) =>
      state = state.copyWith(chainage: value);

  void updateLocation(String value) =>
      state = state.copyWith(location: value);

  void updateContractorRepresentative(String value) =>
      state = state.copyWith(contractorRepresentative: value);

  /// True for the client/engineer side; the web's `inspectionAccessType`
  /// is ENGINEER for every non-contractor role.
  bool get isEngineer => !rfiRoleIsContractorSide(role);

  /// `uploadedBy` for submit and PDF upload: CON or ENGG (web values).
  String get submitUploadedBy => isEngineer ? 'ENGG' : 'CON';

  bool get isRfiNotRequired =>
      !rfiRequiresStamp(state.details?.rfi.field('isRfiRequired') ?? '');

  bool get isReturningForRectification =>
      isEngineer && state.engineerStatus == rfiReturnForRectification;

  void updateEngineerStatus(String value) =>
      state = state.copyWith(engineerStatus: value);

  void updateEngineerRemarks(String value) => state = state.copyWith(
    engineerRemarks: value.length > 1000 ? value.substring(0, 1000) : value,
  );

  /// Web rule: a checklist row the contractor marked YES and the engineer
  /// marked NO forces the inspection to Rejected.
  Future<bool> checklistConflict() async {
    final RfiInspectionDetails? details = state.details;
    if (details == null) {
      return false;
    }
    for (final RfiInspectionEnclosure e in details.enclosures) {
      try {
        final List<RfiChecklistItem> items = await loadChecklist(e);
        if (items.any(
          (RfiChecklistItem i) =>
              i.contractorStatus.toUpperCase() == 'YES' &&
              i.engineerStatus.toUpperCase() == 'NO',
        )) {
          return true;
        }
      } on Object {
        // An unreadable checklist cannot prove a conflict.
      }
    }
    return false;
  }

  void updateContractorDescription(String value) =>
      state = state.copyWith(contractorDescription: value);

  void updateSelfie(String? path) {
    if (path == null || path.trim().isEmpty) {
      state = state.copyWith(clearSelfie: true);
      return;
    }
    state = state.copyWith(selfiePath: path.trim());
  }

  void updateTestInSiteLab(String value) {
    final bool needsReport = value == 'Lab Test' || value == 'Site Test';
    state = state.copyWith(
      testInSiteLab: value,
      clearTestReport: !needsReport,
    );
  }

  void updateTestReport(String? path) {
    if (path == null || path.trim().isEmpty) {
      state = state.copyWith(clearTestReport: true);
      return;
    }
    state = state.copyWith(testReportPath: path.trim());
  }

  void updateMeasurement(int index, RfiInspectionMeasurementRow row) {
    final List<RfiInspectionMeasurementRow> list =
        List<RfiInspectionMeasurementRow>.from(state.measurements);
    if (index < 0 || index >= list.length) {
      return;
    }
    RfiInspectionMeasurementRow updated = row;
    if (list[index].type != row.type) {
      updated = row.copyWith(
        units: _defaultUnit(row.type),
        length: '',
        breadth: '',
        height: '',
        weight: '',
        no: '',
      );
    }
    // Percent: Total Qty is typed (as on the web), not calculated.
    final bool typedTotal = workRfiFieldsFor(updated.type).totalQty;
    list[index] = typedTotal
        ? updated.copyWith(
            totalQty: list[index].type == updated.type ? updated.totalQty : 0,
          )
        : updated.copyWith(totalQty: _computeQty(updated));
    state = state.copyWith(measurements: list);
  }

  void addMeasurementRow() {
    state = state.copyWith(
      measurements: <RfiInspectionMeasurementRow>[
        ...state.measurements,
        const RfiInspectionMeasurementRow(),
      ],
    );
  }

  void addSupportingDoc(String path) {
    state = state.copyWith(
      supportingDocuments: <RfiLocalSupportingDoc>[
        ...state.supportingDocuments,
        RfiLocalSupportingDoc(path: path),
      ],
    );
  }

  void updateSupportingDocDescription(int index, String description) {
    final List<RfiLocalSupportingDoc> list =
        List<RfiLocalSupportingDoc>.from(state.supportingDocuments);
    if (index < 0 || index >= list.length) {
      return;
    }
    list[index] = list[index].copyWith(description: description);
    state = state.copyWith(supportingDocuments: list);
  }

  void removeSupportingDoc(int index) {
    final List<RfiLocalSupportingDoc> list =
        List<RfiLocalSupportingDoc>.from(state.supportingDocuments);
    if (index < 0 || index >= list.length) {
      return;
    }
    list.removeAt(index);
    state = state.copyWith(supportingDocuments: list);
  }

  Future<void> fetchLocation() async {
    state = state.copyWith(
      locationLoading: true,
      locationPermissionDenied: false,
      clearError: true,
    );
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          locationLoading: false,
          error: 'Location services are disabled.',
        );
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          locationLoading: false,
          locationPermissionDenied: true,
        );
        return;
      }
      final Position position = await Geolocator.getCurrentPosition();
      final List<Placemark> marks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (marks.isEmpty) {
        state = state.copyWith(
          locationLoading: false,
          location:
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
        );
        return;
      }
      final Placemark p = marks.first;
      final String address = <String?>[
        p.name,
        p.subLocality,
        p.locality,
        p.subAdministrativeArea,
        p.administrativeArea,
        p.postalCode,
        p.country,
      ].whereType<String>().where((String part) => part.trim().isNotEmpty).join(
            ', ',
          );
      state = state.copyWith(location: address, locationLoading: false);
    } on Object catch (error) {
      state = state.copyWith(
        locationLoading: false,
        error: rfiInspectionErrorMessage(error),
      );
    }
  }

  /// Step 1 -> Step 2 is local only, like the web: the selfie stays on the
  /// device and reaches the server with Save as Draft or Submit.
  void continueToStep2() {
    if (!state.hasSelfie) {
      throw StateError('Selfie is required.');
    }
    setStep(2);
  }

  Future<void> saveAsDraft() async {
    if (!state.hasSelfie) {
      throw StateError('Selfie is required to save draft.');
    }
    state = state.copyWith(busy: true, clearError: true);
    try {
      final int id = await _source.saveDraft(
        data: _draftPayload(),
        selfiePath: state.selfiePath!,
      );
      state = state.copyWith(busy: false, conInspectionId: id);
      await refreshDetails();
    } on Object catch (error) {
      state = state.copyWith(busy: false, error: error);
      rethrow;
    }
  }

  Future<String> submit() async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final String message = await _source.finalSubmit(
        data: _submitPayload(),
        selfiePath: state.selfiePath,
        supportingFiles: rfiSupportingUploads(state.supportingDocuments)
            .map(
              (RfiLocalSupportingDoc d) => (
                path: d.path,
                description: d.description,
              ),
            )
            .toList(growable: false),
        testReportPath: state.testReportPath,
      );
      state = state.copyWith(busy: false);
      return message;
    } on Object catch (error) {
      final bool draftSaved = await _saveDraftAfterFailedSubmit();
      state = state.copyWith(busy: false, error: error);
      throw RfiSubmitFailure(error, draftSaved: draftSaved);
    }
  }

  /// Full contractor submit, in the web's order:
  /// session → generate PDF → upload PDF → e-sign/stamp → final submit.
  /// [onStep] reports each step's progress for the progress sheet. Stamping
  /// is skipped when RFI Required is "No". Returns the server's message.
  Future<String> submitWithSteps(
    void Function(RfiSubmitStep step, RfiStepStatus status) onStep,
  ) async {
    state = state.copyWith(busy: true, clearError: true);
    final bool rectification = isReturningForRectification;
    RfiSubmitStep current =
        rectification ? RfiSubmitStep.rectifyPrepare : RfiSubmitStep.session;
    Future<String> finalSubmit() => _source.finalSubmit(
      data: _submitPayload(),
      selfiePath: state.selfiePath,
      supportingFiles: rfiSupportingUploads(state.supportingDocuments)
          .map(
            (RfiLocalSupportingDoc d) => (
              path: d.path,
              description: d.description,
            ),
          )
          .toList(growable: false),
      testReportPath: state.testReportPath,
    );
    try {
      // Engineer returning for rectification: no PDF, upload or stamping.
      if (rectification) {
        onStep(current, RfiStepStatus.active);
        onStep(current, RfiStepStatus.done);
        current = RfiSubmitStep.rectifySend;
        onStep(current, RfiStepStatus.active);
        final String message = await finalSubmit();
        onStep(current, RfiStepStatus.done);
        state = state.copyWith(busy: false);
        return message;
      }

      onStep(current, RfiStepStatus.active);
      await _source.checkSession();
      onStep(current, RfiStepStatus.done);

      current = RfiSubmitStep.pdf;
      onStep(current, RfiStepStatus.active);
      final Uint8List pdf = await _buildInspectionPdf();
      onStep(current, RfiStepStatus.done);

      current = RfiSubmitStep.upload;
      onStep(current, RfiStepStatus.active);
      if (isEngineer) {
        await _source.uploadEngineerPdf(
          rfiId: arg.rfiId,
          pdf: pdf,
          inspectionStatus: state.engineerStatus,
          engineerRemarks: state.engineerRemarks,
        );
      } else {
        await _source.uploadContractorPdf(rfiId: arg.rfiId, pdf: pdf);
      }
      onStep(current, RfiStepStatus.done);

      current = RfiSubmitStep.stamp;
      if (isRfiNotRequired) {
        onStep(current, RfiStepStatus.skipped);
      } else {
        onStep(current, RfiStepStatus.active);
        if (isEngineer) {
          await _source.stampEngineerPdf(rfiId: arg.rfiId);
        } else {
          await _source.stampContractorPdf(
            rfiId: arg.rfiId,
            txnId: rfiStampTxnId(),
          );
        }
        onStep(current, RfiStepStatus.done);
      }

      current = RfiSubmitStep.finalize;
      onStep(current, RfiStepStatus.active);
      final String message = await finalSubmit();
      onStep(current, RfiStepStatus.done);
      state = state.copyWith(busy: false);
      return message;
    } on Object catch (error) {
      onStep(current, RfiStepStatus.failed);
      // Only a failed final submit falls back to a draft; earlier steps
      // changed nothing the inspector would lose.
      final bool draftSaved =
          current == RfiSubmitStep.finalize &&
          await _saveDraftAfterFailedSubmit();
      state = state.copyWith(busy: false, error: error);
      throw RfiSubmitStepFailure(current, error, draftSaved: draftSaved);
    }
  }

  /// Collects everything the web's `pdfPayload` holds and builds the merged
  /// inspection PDF.
  Future<Uint8List> _buildInspectionPdf() async {
    final RfiInspectionDetails details = state.details!;
    final RfiInspectionDetailRfi rfi = details.rfi;

    Future<Uint8List?> stored(String path) async {
      if (path.trim().isEmpty) {
        return null;
      }
      try {
        return await _source.previewStoredFile(path.trim());
      } on Object {
        return null;
      }
    }

    Future<List<Uint8List>> all(Iterable<Future<Uint8List?>> files) async =>
        (await Future.wait(files)).whereType<Uint8List>().toList();

    // Checklists for every enclosure, as at submit time on the web.
    final List<RfiInspectionEnclosure> unique = <RfiInspectionEnclosure>[];
    for (final RfiInspectionEnclosure e in details.enclosures) {
      if (!unique.any(
        (RfiInspectionEnclosure u) =>
            u.enclosureName == e.enclosureName &&
            u.rfiDescription == e.rfiDescription,
      )) {
        unique.add(e);
      }
    }
    final List<RfiPdfEnclosure> enclosures = await Future.wait(
      unique.map((RfiInspectionEnclosure e) async {
        List<RfiChecklistItem> items = const <RfiChecklistItem>[];
        try {
          items = await loadChecklist(e);
        } on Object {
          items = const <RfiChecklistItem>[];
        }
        return RfiPdfEnclosure(
          rfiDescription: e.rfiDescription,
          enclosure: e.enclosureName,
          checklist: items
              .map(
                (RfiChecklistItem i) => RfiPdfChecklistRow(
                  description: i.checklistDescription,
                  contractorStatus: i.contractorStatus,
                  engineerStatus: i.engineerStatus,
                  contractorRemark: i.contractorRemarks,
                  engineerRemark: i.engineerRemark,
                ),
              )
              .toList(),
        );
      }),
    );

    final Set<String> enclosurePaths = <String>{
      for (final RfiInspectionEnclosure e in details.enclosures)
        if (e.enclosureUploadedFile.trim().isNotEmpty)
          e.enclosureUploadedFile.trim(),
    };
    final List<Uint8List> enclosurePdfs = await all(enclosurePaths.map(stored));

    final List<Uint8List> conImages = await all(rfi.conSiteImgs.map(stored));
    final List<Uint8List> enggImages = await all(rfi.enggSiteImgs.map(stored));

    final List<Uint8List> supporting = await all(<Future<Uint8List?>>[
      for (final RfiLocalSupportingDoc d in state.supportingDocuments)
        d.onServer
            ? stored(d.path)
            : File(d.path).readAsBytes().then<Uint8List?>((Uint8List b) => b,
                onError: (Object _) => null),
      for (final RfiSupportingDocument d in rfi.enggSupDocs) stored(d.path),
    ]);

    final String? localReport = state.testReportPath;
    final List<Uint8List> testReports = await all(<Future<Uint8List?>>[
      if (localReport != null && localReport.isNotEmpty)
        File(localReport).readAsBytes().then<Uint8List?>((Uint8List b) => b,
            onError: (Object _) => null)
      else
        stored(rfi.field('testReport')),
    ]);

    final String structureKey =
        rfi.structureType.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    final bool chainageType = <String>{
      'earthwork',
      'blanketing',
      'tunnel',
      'trackwork',
    }.contains(structureKey);
    final bool layerType =
        structureKey == 'earthwork' || structureKey == 'blanketing';

    final RfiInspectionPdfData data = RfiInspectionPdfData(
      rfiNo: rfi.rfiId,
      rfiCategory: rfi.rfiCategory.isEmpty ? arg.rfiCategory : rfi.rfiCategory,
      inspectionMode: arg.inspectionMode,
      contract: rfi.contract,
      contractor: rfi.field('contractorName'),
      contractorRep: state.contractorRepresentative,
      location: state.location,
      // Web: the submitter's side gets "now"; for an engineer the contractor
      // date is printed only when the RFI is not required.
      conSubmittedOn: isEngineer
          ? (isRfiNotRequired ? rfi.field('contractorSubmittedOn') : '')
          : rfiPdfTimestamp(DateTime.now()),
      enggSubmittedOn: isEngineer ? rfiPdfTimestamp(DateTime.now()) : '',
      rfiNotRequired: isRfiNotRequired,
      inspectionStatus: isEngineer ? state.engineerStatus : '',
      engineerRemarks: isEngineer ? state.engineerRemarks : '',
      raisedOn: rfiPdfServerDate(rfi.field('createdAt')),
      rfiDescriptionSelected: rfi.rfiDescription,
      rfiDescription: rfi.description,
      structureType: rfi.structureType,
      structure: rfi.structure,
      component: rfi.component,
      element: rfi.element,
      activity: rfi.activity,
      chainageFrom: chainageType ? rfi.field('chainageFrom') : '',
      chainageTo: chainageType ? rfi.field('chainageTo') : '',
      layer: layerType ? rfi.field('layer') : '',
      enclosures: enclosures,
      inspDescriptionCon: isEngineer
          ? rfi.field('conDescriptionEnclosure')
          : state.contractorDescription,
      inspDescriptionEngg: isEngineer
          ? state.contractorDescription
          : rfi.field('enggDescriptionEnclosure'),
      measurements: state.measurements
          .map(
            (RfiInspectionMeasurementRow m) => RfiPdfMeasurement(
              component: m.component,
              element: m.element,
              activityName: m.activityName,
              type: m.type == rfiInspectionNoType ? '' : m.type,
              units: m.units == rfiInspectionNoUnit ? '' : m.units,
              l: m.length,
              b: m.breadth,
              h: m.height,
              weight: m.weight,
              no: m.no,
              total: rfiPdfQuantity(m.totalQty),
            ),
          )
          .toList(),
      workDetails: <List<String>>[
        for (final Map<String, dynamic> w in details.workDetails)
          <String>[
            for (final String key in const <String>[
              'activityName',
              'unit',
              'scope',
              'completedTillDate',
              'inspectionQuantity',
            ])
              '${w[key] ?? ''}',
          ],
      ],
      earthworkDetails: layerType
          ? <(String, String)>[
              for (final (String label, String key) in const <(String, String)>[
                ('FDD Test Pit Nos', 'fddTestPitNos'),
                ('Field Compaction (%)', 'fieldCompactionPercentage'),
                ('Manpower Deployment', 'manpowerDeployment'),
                ('M&P Deployment Details', 'mpDeploymentDetails'),
              ])
                if (rfi.field(key).isNotEmpty) (label, rfi.field(key)),
            ]
          : const <(String, String)>[],
      validationRows: rfiPdfValidationRows(details.validationList),
      contractorImages: conImages,
      engineerImages: enggImages,
    );

    Uint8List? logo;
    try {
      logo = (await rootBundle.load('assets/brand/swr_logo.png'))
          .buffer
          .asUint8List();
    } on Object {
      logo = null;
    }
    final Uint8List main = await RfiInspectionPdf.build(
      data: data,
      fonts: await RfiInspectionPdfFonts.load(),
      logo: logo,
    );
    // RFI Required = No appends supporting documents only (web RFI-NO).
    return mergeRfiInspectionPdf(
      main: main,
      enclosures: isRfiNotRequired ? const <Uint8List>[] : enclosurePdfs,
      supporting: supporting,
      testReports: isRfiNotRequired ? const <Uint8List>[] : testReports,
    );
  }

  /// When final submit fails the inspection is saved as a draft, as the web
  /// does, so nothing the inspector entered is lost.
  Future<bool> _saveDraftAfterFailedSubmit() async {
    if (!state.hasSelfie) {
      return false;
    }
    try {
      final int id = await _source.saveDraft(
        data: _draftPayload(),
        selfiePath: state.selfiePath!,
      );
      state = state.copyWith(conInspectionId: id);
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> uploadSiteImage(String path) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _source.uploadSiteImage(
        rfiId: arg.rfiId,
        imagePath: path,
        uploadedBy: uploadedBy,
      );
      await refreshDetails();
      state = state.copyWith(busy: false);
    } on Object catch (error) {
      state = state.copyWith(busy: false, error: error);
      rethrow;
    }
  }

  /// Deletes one of this user's site images, then reloads the RFI so the
  /// list matches the server.
  Future<void> deleteSiteImage(String imagePath) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _source.deleteSiteImage(
        rfiId: arg.rfiId,
        imagePath: imagePath,
        uploadedBy: uploadedBy,
      );
      await refreshDetails();
      state = state.copyWith(busy: false);
    } on Object catch (error) {
      state = state.copyWith(busy: false, error: error);
      rethrow;
    }
  }

  Future<void> uploadEnclosure({
    required String filePath,
    required RfiInspectionEnclosure enclosure,
  }) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _source.uploadEnclosure(
        rfiId: arg.rfiId,
        filePath: filePath,
        enclosureName: '${enclosure.enclosureId ?? enclosure.enclosureName}',
        rfiDescription:
            '${enclosure.rfiDescriptionId ?? enclosure.rfiDescription}',
        uploadedBy: uploadedBy,
      );
      await refreshDetails();
      state = state.copyWith(busy: false);
    } on Object catch (error) {
      state = state.copyWith(busy: false, error: error);
      rethrow;
    }
  }

  Future<Uint8List> downloadEnclosure(String filepath) =>
      _source.downloadEnclosure(filepath);

  /// Deletes one uploaded enclosure file, then reloads the RFI.
  Future<void> deleteEnclosureFile(int enclosureUploadedFileId) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _source.deleteEnclosureFile(
        enclosureUploadedFileId: enclosureUploadedFileId,
        uploadedBy: uploadedBy,
      );
      await refreshDetails();
      state = state.copyWith(busy: false);
    } on Object catch (error) {
      state = state.copyWith(busy: false, error: error);
      rethrow;
    }
  }

  Future<List<RfiChecklistItem>> loadChecklist(
    RfiInspectionEnclosure enclosure,
  ) {
    return _source.fetchChecklistItems(
      enclosureName: enclosure.enclosureName,
      rfiDescription: enclosure.rfiDescription,
      rfiId: arg.rfiId,
    );
  }

  Future<String> saveChecklist({
    required RfiInspectionEnclosure enclosure,
    required List<RfiChecklistItem> items,
    required String gradeOfConcrete,
  }) {
    return _source.saveChecklist(<String, dynamic>{
      'rfiId': arg.rfiId,
      'enclosureId': enclosure.enclosureId,
      'rfiDescriptionId': enclosure.rfiDescriptionId,
      'enclosureName': enclosure.enclosureName,
      'rfiDescription': enclosure.rfiDescription,
      'gradeOfConcrete': gradeOfConcrete,
      'uploadedBy': checklistUploadedBy,
      'checklistRows': items
          .map((RfiChecklistItem item) => item.toSaveRowJson())
          .toList(growable: false),
    });
  }

  bool isStep2Valid() {
    if (state.location.trim().isEmpty) {
      return false;
    }
    final bool hasMeasurement = state.measurements.any(
      (RfiInspectionMeasurementRow m) =>
          m.type != 'Select' && m.units != 'Select U' && m.totalQty > 0,
    );
    if (!hasMeasurement) {
      return false;
    }
    if (rfiRoleIsContractorSide(role) && state.testInSiteLab == 'Select') {
      return false;
    }
    final String test = state.testInSiteLab;
    if ((test == 'Lab Test' || test == 'Site Test') &&
        (state.testReportPath == null || state.testReportPath!.isEmpty)) {
      return false;
    }
    return true;
  }

  Map<String, dynamic> _draftPayload() {
    final RfiInspectionMeasurementRow first = state.measurements.isNotEmpty
        ? state.measurements.first
        : const RfiInspectionMeasurementRow();
    return <String, dynamic>{
      'rfiId': arg.rfiId,
      'conInspectionId': state.conInspectionId,
      'chainage': state.chainage,
      'location': state.location,
      'inspectionMode': arg.inspectionMode,
      'nameOfRepresentative': state.contractorRepresentative,
      'dateOfInspection': state.dateOfInspection,
      'timeOfInspection': state.timeOfInspection,
      'descriptionEnclosure': state.contractorDescription,
      'inspectionStatus': _mapTestType(state.testInSiteLab),
      'measurementType': first.type == 'Select' ? null : first.type,
      'units': first.units == 'Select U' ? null : first.units,
      'length': double.tryParse(first.length),
      'breadth': double.tryParse(first.breadth),
      'height': double.tryParse(first.height),
      'weight': double.tryParse(first.weight),
      'noOfItems': int.tryParse(first.no),
      'totalQty': first.totalQty,
      'measurements': state.measurements
          .map((RfiInspectionMeasurementRow m) => m.toJson())
          .toList(growable: false),
      'supportingDescriptions': rfiSupportingUploads(state.supportingDocuments)
          .map((RfiLocalSupportingDoc d) => d.description)
          .toList(growable: false),
    };
  }

  /// The `/rfi/finalSubmit` `data` JSON, matching the web payload.
  Map<String, dynamic> _submitPayload() {
    return buildRfiFinalSubmitPayload(
      inspectionId: isEngineer
          ? int.tryParse(state.details?.rfi.field('enggInspectionId') ?? '')
          : state.conInspectionId,
      rfiId: arg.rfiId,
      uploadedBy: submitUploadedBy,
      location: state.location,
      chainage: state.chainage,
      nameOfRepresentative: state.contractorRepresentative,
      measurements: state.measurements
          .map(
            (RfiInspectionMeasurementRow m) => RfiSubmitMeasurement(
              activityIdFk: m.activityIdFk,
              activityName: m.activityName,
              measurementType: m.type == rfiInspectionNoType ? '' : m.type,
              units: m.units == rfiInspectionNoUnit ? '' : m.units,
              length: m.length,
              breadth: m.breadth,
              height: m.height,
              weight: m.weight,
              no: m.no,
              totalQty: m.totalQty,
            ),
          )
          .toList(growable: false),
      testInsiteLab: _mapTestType(state.testInSiteLab),
      // Accepted / Rejected / Returned is the engineer's decision; the
      // contractor sends null like the web.
      inspectionStatus: isEngineer ? state.engineerStatus : null,
      engineerRemarks: isEngineer ? state.engineerRemarks : null,
      descriptionEnclosure: state.contractorDescription,
      supportingDescriptions: rfiSupportingUploads(state.supportingDocuments)
          .map((RfiLocalSupportingDoc d) => d.description)
          .toList(growable: false),
      inspectionMode: arg.inspectionMode,
    );
  }

  /// A type with a single unit (Number → Nos, Percent → %) picks it; others
  /// wait for the inspector to choose, like the Work RFI form.
  static String _defaultUnit(String type) {
    final List<String> units = workRfiUnitsFor(type);
    return units.length == 1 ? units.first : rfiInspectionNoUnit;
  }

  static double _computeQty(RfiInspectionMeasurementRow row) {
    final double l = double.tryParse(row.length) ?? 0;
    final double b = double.tryParse(row.breadth) ?? 0;
    final double h = double.tryParse(row.height) ?? 0;
    final double w = double.tryParse(row.weight) ?? 0;
    final double n = double.tryParse(row.no) ?? 1;
    return switch (row.type) {
      'Area' => l * b * n,
      'Length' => l * n,
      'Volume' => l * b * h * n,
      'Number' => double.tryParse(row.no) ?? 0,
      'Weight' => w * n,
      'Percent' => double.tryParse(row.no) ?? 0,
      _ => 0,
    };
  }

  static String _displayTestType(String raw) {
    final String value = raw.trim().toUpperCase();
    return switch (value) {
      'VISUAL' => 'Visual',
      'LAB_TEST' || 'LAB TEST' => 'Lab Test',
      'SITE_TEST' || 'SITE TEST' => 'Site Test',
      _ => raw.trim().isEmpty ? 'Visual' : raw.trim(),
    };
  }

  static String? _mapTestType(String value) {
    return switch (value) {
      'Visual' => 'VISUAL',
      'Lab Test' => 'LAB_TEST',
      'Site Test' => 'SITE_TEST',
      'Select' => null,
      _ => value.isEmpty ? null : value,
    };
  }
}

/// A failed final submit, and whether the draft backup was saved.
class RfiSubmitFailure implements Exception {
  const RfiSubmitFailure(this.cause, {required this.draftSaved});

  final Object cause;
  final bool draftSaved;

  @override
  String toString() => cause.toString();
}

/// Error text for a failed submit, saying whether the draft backup worked.
String rfiSubmitFailureMessage(Object error) {
  if (error is! RfiSubmitFailure) {
    return rfiInspectionErrorMessage(error);
  }
  final String reason = rfiInspectionErrorMessage(error.cause);
  return error.draftSaved
      ? '$reason\n\nYour inspection was saved as a draft.'
      : '$reason\n\nThe draft could not be saved either. Please try again.';
}


/// Placeholder shown before a unit is chosen.
const String rfiInspectionNoUnit = 'Select U';

/// Placeholder shown before a measurement type is chosen.
const String rfiInspectionNoType = 'Select';

/// Units offered for [type]: the same list as the Work RFI form (so a saved
/// "Nos", "m²" or "MT" is always present), plus [current] if the server sent
/// something else. Every dropdown value is therefore one of its items.
List<String> rfiInspectionUnitOptions(String type, String current) {
  final List<String> options = <String>[
    rfiInspectionNoUnit,
    ...workRfiUnitsFor(type),
  ];
  final String value = current.trim();
  if (value.isNotEmpty && !options.contains(value)) {
    options.add(value);
  }
  return options;
}

/// Measurement types for the dropdown, plus [current] if it is unknown.
List<String> rfiInspectionTypeOptions(String current) {
  final List<String> options = <String>[
    rfiInspectionNoType,
    ...workRfiMeasurementTypes,
  ];
  final String value = current.trim();
  if (value.isNotEmpty && !options.contains(value)) {
    options.add(value);
  }
  return options;
}

/// Tests in Site/Lab choices, plus [current] if the server sent another.
List<String> rfiInspectionTestOptions(String current) {
  final List<String> options = <String>['Visual', 'Lab Test', 'Site Test'];
  final String value = current.trim();
  if (value.isNotEmpty && !options.contains(value)) {
    options.add(value);
  }
  return options;
}

/// Steps of the inspection submit, shown like the web's progress modal.
enum RfiSubmitStep {
  session('Verifying session'),
  pdf('Generating Inspection PDF'),
  upload('Uploading Inspection PDF'),
  stamp('E-Sign / Stamping in progress'),
  finalize('Finalizing inspection'),
  rectifyPrepare('Preparing rectification return'),
  rectifySend('Sending back for rectification');

  const RfiSubmitStep(this.label);

  final String label;
}

enum RfiStepStatus { waiting, active, done, skipped, failed }

/// A submit that stopped at [step].
class RfiSubmitStepFailure implements Exception {
  const RfiSubmitStepFailure(this.step, this.cause, {this.draftSaved = false});

  final RfiSubmitStep step;
  final Object cause;
  final bool draftSaved;

  @override
  String toString() => cause.toString();
}

/// The web's per-step error text.
String rfiSubmitStepMessage(RfiSubmitStepFailure failure) {
  final String reason = rfiInspectionErrorMessage(failure.cause);
  return switch (failure.step) {
    RfiSubmitStep.session =>
      'Your session has expired. Please log in again.',
    RfiSubmitStep.pdf => 'PDF generation failed: $reason',
    RfiSubmitStep.upload => 'Upload Inspection Pdf failed: $reason',
    RfiSubmitStep.stamp => 'E-sign failed: $reason',
    RfiSubmitStep.rectifyPrepare ||
    RfiSubmitStep.rectifySend => 'Return for rectification failed: $reason',
    RfiSubmitStep.finalize =>
      'PDF was uploaded and signed, but final submit failed: $reason'
          '${failure.draftSaved ? '\n\nYour inspection was saved as a draft.' : ''}',
  };
}

/// The steps shown for a submit, like the web's step list.
List<RfiSubmitStep> rfiSubmitSteps({required bool rectification}) =>
    rectification
    ? const <RfiSubmitStep>[
        RfiSubmitStep.rectifyPrepare,
        RfiSubmitStep.rectifySend,
      ]
    : const <RfiSubmitStep>[
        RfiSubmitStep.session,
        RfiSubmitStep.pdf,
        RfiSubmitStep.upload,
        RfiSubmitStep.stamp,
        RfiSubmitStep.finalize,
      ];

const String rfiInspectionAccepted = 'Accepted';
const String rfiInspectionRejected = 'Rejected';
const String rfiReturnForRectification = 'Returned_For_Rectification';

/// Engineer status choices; Return For Rectification is online only.
List<(String, String)> rfiEngineerStatusOptions({required bool offline}) =>
    <(String, String)>[
      (rfiInspectionAccepted, 'Accepted'),
      (rfiInspectionRejected, 'Rejected'),
      if (!offline) (rfiReturnForRectification, 'Return For Rectification'),
    ];

/// Web validation before an engineer submit; null when it may go ahead.
String? rfiEngineerSubmitError(RfiInspectionFlowState state) {
  if (state.engineerStatus.trim().isEmpty) {
    return 'Please select Inspection Status!';
  }
  if (state.engineerStatus != rfiInspectionAccepted &&
      state.engineerRemarks.trim().isEmpty) {
    final String label = state.engineerStatus == rfiReturnForRectification
        ? 'Returned For Rectification'
        : state.engineerStatus;
    return 'Remarks are mandatory when Inspection is $label!';
  }
  return null;
}

/// Stamping runs only when the RFI is required (web: `!isRfiNotRequired`).
bool rfiRequiresStamp(String isRfiRequired) =>
    isRfiRequired.trim().toLowerCase() != 'no';

/// "13/11/2026 12:47", like the web's en-GB timestamp without the comma.
String rfiPdfTimestamp(DateTime time) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(time.day)}/${two(time.month)}/${time.year} '
      '${two(time.hour)}:${two(time.minute)}';
}

/// rfi-details `createdAt` ("13-11-2026 11:02") shown as "13/11/2026 11:02".
String rfiPdfServerDate(String raw) {
  final RegExpMatch? m = RegExp(
    r'^(\d{2})-(\d{2})-(\d{4})(.*)$',
  ).firstMatch(raw.trim());
  if (m == null) {
    return raw.trim();
  }
  return '${m[1]}/${m[2]}/${m[3]}${m[4]}';
}

String rfiPdfQuantity(double value) {
  if (value == 0) {
    return '';
  }
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

/// Validation history rows: No., Type, Validated By, Status, On, Remarks.
List<List<String>> rfiPdfValidationRows(List<Map<String, dynamic>> list) {
  String text(Object? v) => v == null ? '' : '$v'.trim();
  return <List<String>>[
    for (int i = 0; i < list.length; i++)
      <String>[
        '${i + 1}',
        text(list[i]['validationType']),
        text(list[i]['validatorName'] ?? list[i]['validatedByUserName']),
        text(list[i]['status']).replaceAll('_', ' '),
        text(list[i]['validatedOn'] ?? list[i]['sentForValidationAt']),
        <String>[
          if (text(list[i]['remarks']).isNotEmpty)
            'Remarks: ${text(list[i]['remarks'])}',
          if (text(list[i]['comment']).isNotEmpty)
            'Comment: ${text(list[i]['comment'])}',
        ].join('\n'),
      ],
  ];
}
