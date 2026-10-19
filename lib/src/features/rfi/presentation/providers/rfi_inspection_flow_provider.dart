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
  });

  final String path;
  final String description;

  RfiLocalSupportingDoc copyWith({String? description}) {
    return RfiLocalSupportingDoc(
      path: path,
      description: description ?? this.description,
    );
  }
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

  RfiUserRole get role {
    final AuthSession? session = ref.read(authControllerProvider).valueOrNull;
    return RfiUserRoleResolver.fromSession(session);
  }

  String get uploadedBy => rfiInspectionUploadedBy(role);

  String get checklistUploadedBy => rfiChecklistUploadedBy(role);

  Future<void> load() async {
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
    list[index] = updated.copyWith(totalQty: _computeQty(updated));
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

  Future<void> saveStep1AndContinue() async {
    if (!state.hasSelfie) {
      throw StateError('Selfie is required.');
    }
    state = state.copyWith(busy: true, clearError: true);
    try {
      final int id = await _source.saveDraft(
        data: <String, dynamic>{
          'rfiId': arg.rfiId,
          'chainage': state.chainage,
          'inspectionMode': arg.inspectionMode,
          'location': state.location,
          'nameOfRepresentative': state.contractorRepresentative,
          if (state.conInspectionId != null)
            'conInspectionId': state.conInspectionId,
        },
        selfiePath: state.selfiePath!,
      );
      state = state.copyWith(busy: false, conInspectionId: id, currentStep: 2);
      await fetchLocation();
      await refreshDetails();
    } on Object catch (error) {
      state = state.copyWith(busy: false, error: error);
      rethrow;
    }
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
        supportingFiles: state.supportingDocuments
            .where((RfiLocalSupportingDoc d) => !d.path.startsWith('http'))
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
      state = state.copyWith(busy: false, error: error);
      rethrow;
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
      'supportingDescriptions': state.supportingDocuments
          .map((RfiLocalSupportingDoc d) => d.description)
          .toList(growable: false),
    };
  }

  Map<String, dynamic> _submitPayload() {
    final Map<String, dynamic> data = _draftPayload();
    data['uploadedBy'] = uploadedBy;
    final AuthSession? session = ref.read(authControllerProvider).valueOrNull;
    data['userId'] = session?.userId;
    return data;
  }

  static String _defaultUnit(String type) {
    return switch (type) {
      'Area' => 'sqm',
      'Length' => 'm',
      'Volume' => 'cum',
      'Number' => 'nos',
      'Weight' => 'kg',
      _ => 'Select U',
    };
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
