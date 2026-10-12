import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_filter.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_menu.dart';

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

final rfiCurrentSectionProvider =
    NotifierProvider<RfiCurrentSectionController, RfiMenuId>(
      RfiCurrentSectionController.new,
    );

class RfiCurrentSectionController extends Notifier<RfiMenuId> {
  @override
  RfiMenuId build() => RfiMenuId.home;

  void select(RfiMenuId id) => state = id;
}

bool _rfiBackConsumed = false;

void handleRfiBack(
  WidgetRef ref, {
  required int shellIndex,
  required void Function() goHome,
}) {
  if (_rfiBackConsumed) {
    return;
  }
  _rfiBackConsumed = true;
  Future<void>.microtask(() => _rfiBackConsumed = false);
  if (shellIndex != 3) {
    return;
  }
  if (ref.read(rfiCurrentSectionProvider) != RfiMenuId.home) {
    ref.read(rfiCurrentSectionProvider.notifier).select(RfiMenuId.home);
    return;
  }
  goHome();
}
