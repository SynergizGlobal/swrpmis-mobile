import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_user_role.dart';

enum RfiMenuId {
  home,
  createMaterial,
  createWork,
  createQuality,
  inspection,
  validation,
  log,
  assignExecutive,
  inspectionReference,
}

class RfiMenuItem {
  const RfiMenuItem({
    required this.id,
    required this.title,
    required this.icon,
  });

  final RfiMenuId id;
  final String title;
  final IconData icon;

  static const List<RfiMenuItem> all = <RfiMenuItem>[
    RfiMenuItem(
      id: RfiMenuId.home,
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
    ),
    RfiMenuItem(
      id: RfiMenuId.createMaterial,
      title: 'Create Material RFI',
      icon: Icons.inventory_2_outlined,
    ),
    RfiMenuItem(
      id: RfiMenuId.createWork,
      title: 'Create Work RFI',
      icon: Icons.construction_outlined,
    ),
    RfiMenuItem(
      id: RfiMenuId.createQuality,
      title: 'Create Quality/Safety RFI',
      icon: Icons.health_and_safety_outlined,
    ),
    RfiMenuItem(
      id: RfiMenuId.inspection,
      title: 'Inspection',
      icon: Icons.assignment_outlined,
    ),
    RfiMenuItem(
      id: RfiMenuId.validation,
      title: 'Validation',
      icon: Icons.verified_outlined,
    ),
    RfiMenuItem(id: RfiMenuId.log, title: 'RFI Log', icon: Icons.history),
    RfiMenuItem(
      id: RfiMenuId.assignExecutive,
      title: 'Assign Executive',
      icon: Icons.person_add_alt_outlined,
    ),
    RfiMenuItem(
      id: RfiMenuId.inspectionReference,
      title: 'Inspection Reference Form',
      icon: Icons.description_outlined,
    ),
  ];

  static const int maxNavSlots = 5;

  static List<RfiMenuItem> visibleFor(RfiUserRole role) {
    return all.where((RfiMenuItem item) => item.isVisible(role)).toList();
  }

  static List<RfiMenuItem> navItemsFor(RfiUserRole role) {
    return visibleFor(role).where((RfiMenuItem item) => item.isNav).toList();
  }

  static List<RfiMenuItem> createItemsFor(RfiUserRole role) {
    return visibleFor(role).where((RfiMenuItem item) => item.isCreate).toList();
  }

  static ({List<RfiMenuItem> bar, List<RfiMenuItem> overflow}) navBarFor(
    RfiUserRole role,
  ) {
    final List<RfiMenuItem> items = navItemsFor(role);
    if (items.length <= maxNavSlots) {
      return (bar: items, overflow: const <RfiMenuItem>[]);
    }
    final List<RfiMenuItem> pinned = items
        .where((RfiMenuItem item) => item.id == RfiMenuId.home)
        .toList(growable: false);
    final List<RfiMenuItem> rest = items
        .where((RfiMenuItem item) => item.id != RfiMenuId.home)
        .toList(growable: false);
    final int roleSlots = maxNavSlots - 1 - pinned.length;
    final int kept = roleSlots < 0 ? 0 : roleSlots;
    return (
      bar: <RfiMenuItem>[...pinned, ...rest.take(kept)],
      overflow: rest.skip(kept).toList(growable: false),
    );
  }

  bool get isCreate =>
      id == RfiMenuId.createMaterial ||
      id == RfiMenuId.createWork ||
      id == RfiMenuId.createQuality;

  bool get isNav => !isCreate;

  String get navLabel => switch (id) {
    RfiMenuId.assignExecutive => 'Assign',
    RfiMenuId.inspectionReference => 'Reference',
    _ => title,
  };

  String get pendingMessage => switch (id) {
    RfiMenuId.home => 'The RFI dashboard is not ready yet.',
    RfiMenuId.createMaterial ||
    RfiMenuId.createWork ||
    RfiMenuId.createQuality =>
      'The create form will follow the same steps as the other RFI apps.',
    RfiMenuId.inspection =>
      'Inspection will follow the same list and actions as the other RFI apps.',
    RfiMenuId.validation =>
      'Validation will follow the same list and actions as the other RFI apps.',
    RfiMenuId.log => 'The RFI log will open here.',
    RfiMenuId.assignExecutive => 'Assign Executive will open here.',
    RfiMenuId.inspectionReference =>
      'The inspection reference form will open here.',
  };

  bool isVisible(RfiUserRole role) {
    return switch (id) {
      RfiMenuId.home => true,
      RfiMenuId.createMaterial ||
      RfiMenuId.createWork ||
      RfiMenuId.createQuality => role.canCreateRfi,
      RfiMenuId.inspection => role.canViewInspection,
      RfiMenuId.validation => role.canViewValidation,
      RfiMenuId.log => role.canViewRfiLog,
      RfiMenuId.assignExecutive => role.canAssignExecutive,
      RfiMenuId.inspectionReference => role.canViewInspectionReferenceForm,
    };
  }

  static RfiMenuItem? byId(String raw) {
    for (final RfiMenuItem item in all) {
      if (item.id.name == raw) {
        return item;
      }
    }
    return null;
  }
}
