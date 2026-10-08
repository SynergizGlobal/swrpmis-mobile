import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_menu.dart';

enum RfiListKind {
  material,
  work,
  quality;

  static RfiListKind? fromMenuId(RfiMenuId? id) {
    return switch (id) {
      RfiMenuId.createMaterial => RfiListKind.material,
      RfiMenuId.createWork => RfiListKind.work,
      RfiMenuId.createQuality => RfiListKind.quality,
      _ => null,
    };
  }

  String get title => switch (this) {
    RfiListKind.material => 'Material RFI',
    RfiListKind.work => 'Work RFI',
    RfiListKind.quality => 'Quality/Safety RFI',
  };

  String get emptyMessage => switch (this) {
    RfiListKind.material => 'No Material RFIs found.',
    RfiListKind.work => 'No Work RFIs found.',
    RfiListKind.quality => 'No Quality/Safety RFIs found.',
  };
}
