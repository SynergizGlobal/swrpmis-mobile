import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_filter.dart';

final rfiSectionLaunchProvider =
    NotifierProvider<RfiSectionLaunchController, RfiSectionLaunch>(
      RfiSectionLaunchController.new,
    );

class RfiSectionLaunch {
  const RfiSectionLaunch({
    this.inspection = const RfiInspectionFilter(),
    this.log = const RfiInspectionFilter(),
  });

  final RfiInspectionFilter inspection;
  final RfiInspectionFilter log;

  RfiSectionLaunch copyWith({
    RfiInspectionFilter? inspection,
    RfiInspectionFilter? log,
  }) {
    return RfiSectionLaunch(
      inspection: inspection ?? this.inspection,
      log: log ?? this.log,
    );
  }
}

class RfiSectionLaunchController extends Notifier<RfiSectionLaunch> {
  @override
  RfiSectionLaunch build() => const RfiSectionLaunch();

  void setInspection(RfiInspectionFilter filter) {
    state = state.copyWith(inspection: filter);
  }

  void setLog(RfiInspectionFilter filter) {
    state = state.copyWith(log: filter);
  }
}
