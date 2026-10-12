import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_catalog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_filter.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_clear_button.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_field.dart';

class RfiLogFilterBar extends StatelessWidget {
  const RfiLogFilterBar({
    super.key,
    required this.filter,
    required this.catalog,
    required this.enabled,
    required this.onClear,
    required this.onCategory,
    required this.onProject,
    required this.onContract,
    required this.onStructureType,
    required this.onStructure,
    required this.onItem,
    required this.onMaterial,
    required this.onQuality,
  });

  final RfiInspectionFilter filter;
  final RfiInspectionCatalog catalog;
  final bool enabled;
  final VoidCallback onClear;
  final ValueChanged<String?> onCategory;
  final ValueChanged<String?> onProject;
  final ValueChanged<String?> onContract;
  final ValueChanged<String?> onStructureType;
  final ValueChanged<int?> onStructure;
  final ValueChanged<int?> onItem;
  final ValueChanged<int?> onMaterial;
  final ValueChanged<int?> onQuality;

  @override
  Widget build(BuildContext context) {
    final bool categoryChosen =
        filter.rfiCategory != null && filter.rfiCategory!.trim().isNotEmpty;
    final List<Widget> chips = <Widget>[
      RfiFilterField(
        label: 'RFI Category',
        value: _label(catalog.categories, filter.rfiCategory),
        options: catalog.categories,
        selectedId: filter.rfiCategory,
        onClear: filter.rfiCategory == null ? null : () => onCategory(null),
        onPick: (RfiFilterOption option) => onCategory(option.id),
      ),
      RfiFilterField(
        label: 'Project',
        value: _label(catalog.projects, filter.projectId),
        options: catalog.projects,
        selectedId: filter.projectId,
        onClear: filter.projectId == null ? null : () => onProject(null),
        onPick: (RfiFilterOption option) => onProject(option.id),
      ),
      RfiFilterField(
        label: 'Contract',
        value: _label(catalog.contracts, filter.contractId),
        options: catalog.contracts,
        selectedId: filter.contractId,
        onClear: filter.contractId == null ? null : () => onContract(null),
        onPick: (RfiFilterOption option) => onContract(option.id),
      ),
      if (categoryChosen && catalog.structureTypes.isNotEmpty)
        RfiFilterField(
          label: 'Structure Type',
          value: _label(catalog.structureTypes, filter.structureType),
          options: catalog.structureTypes,
          selectedId: filter.structureType,
          onClear: filter.structureType == null
              ? null
              : () => onStructureType(null),
          onPick: (RfiFilterOption option) => onStructureType(option.id),
        ),
      if (categoryChosen && catalog.structures.isNotEmpty)
        RfiFilterField(
          label: 'Structure',
          value: _label(catalog.structures, filter.structureId?.toString()),
          options: catalog.structures,
          selectedId: filter.structureId?.toString(),
          onClear: filter.structureId == null ? null : () => onStructure(null),
          onPick: (RfiFilterOption option) => onStructure(option.numberId),
        ),
      if (categoryChosen && catalog.items.isNotEmpty)
        RfiFilterField(
          label: 'Item',
          value: _label(catalog.items, filter.itemId?.toString()),
          options: catalog.items,
          selectedId: filter.itemId?.toString(),
          onClear: filter.itemId == null ? null : () => onItem(null),
          onPick: (RfiFilterOption option) => onItem(option.numberId),
        ),
      if (categoryChosen && catalog.materials.isNotEmpty)
        RfiFilterField(
          label: 'Material',
          value: _label(catalog.materials, filter.materialId?.toString()),
          options: catalog.materials,
          selectedId: filter.materialId?.toString(),
          onClear: filter.materialId == null ? null : () => onMaterial(null),
          onPick: (RfiFilterOption option) => onMaterial(option.numberId),
        ),
      if (categoryChosen && catalog.qualitySafety.isNotEmpty)
        RfiFilterField(
          label: 'Quality/Safety',
          value: _label(
            catalog.qualitySafety,
            filter.qualityOrSafetyId?.toString(),
          ),
          options: catalog.qualitySafety,
          selectedId: filter.qualityOrSafetyId?.toString(),
          onClear: filter.qualityOrSafetyId == null
              ? null
              : () => onQuality(null),
          onPick: (RfiFilterOption option) => onQuality(option.numberId),
        ),
    ];

    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: RfiFilterGrid(
          children: <Widget>[
            ...chips,
            RfiFilterClearButton(onPressed: enabled ? onClear : null),
          ],
        ),
      ),
    );
  }
}

String? _label(List<RfiFilterOption> options, String? id) {
  if (id == null) {
    return null;
  }
  for (final RfiFilterOption option in options) {
    if (option.id == id) {
      return option.label;
    }
  }
  return id;
}
