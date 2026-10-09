import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_catalog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_filter.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_clear_button.dart';

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
      _chip(
        context,
        label: 'RFI Category',
        value: _label(catalog.categories, filter.rfiCategory),
        options: catalog.categories,
        selectedId: filter.rfiCategory,
        onClear: filter.rfiCategory == null ? null : () => onCategory(null),
        onPick: (RfiFilterOption option) => onCategory(option.id),
      ),
      _chip(
        context,
        label: 'Project',
        value: _label(catalog.projects, filter.projectId),
        options: catalog.projects,
        selectedId: filter.projectId,
        onClear: filter.projectId == null ? null : () => onProject(null),
        onPick: (RfiFilterOption option) => onProject(option.id),
      ),
      _chip(
        context,
        label: 'Contract',
        value: _label(catalog.contracts, filter.contractId),
        options: catalog.contracts,
        selectedId: filter.contractId,
        onClear: filter.contractId == null ? null : () => onContract(null),
        onPick: (RfiFilterOption option) => onContract(option.id),
      ),
      if (categoryChosen && catalog.structureTypes.isNotEmpty)
        _chip(
          context,
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
        _chip(
          context,
          label: 'Structure',
          value: _label(catalog.structures, filter.structureId?.toString()),
          options: catalog.structures,
          selectedId: filter.structureId?.toString(),
          onClear: filter.structureId == null ? null : () => onStructure(null),
          onPick: (RfiFilterOption option) => onStructure(option.numberId),
        ),
      if (categoryChosen && catalog.items.isNotEmpty)
        _chip(
          context,
          label: 'Item',
          value: _label(catalog.items, filter.itemId?.toString()),
          options: catalog.items,
          selectedId: filter.itemId?.toString(),
          onClear: filter.itemId == null ? null : () => onItem(null),
          onPick: (RfiFilterOption option) => onItem(option.numberId),
        ),
      if (categoryChosen && catalog.materials.isNotEmpty)
        _chip(
          context,
          label: 'Material',
          value: _label(catalog.materials, filter.materialId?.toString()),
          options: catalog.materials,
          selectedId: filter.materialId?.toString(),
          onClear: filter.materialId == null ? null : () => onMaterial(null),
          onPick: (RfiFilterOption option) => onMaterial(option.numberId),
        ),
      if (categoryChosen && catalog.qualitySafety.isNotEmpty)
        _chip(
          context,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        IgnorePointer(
          ignoring: !enabled,
          child: Opacity(
            opacity: enabled ? 1 : 0.6,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                const double gap = 8;
                final double cell = constraints.maxWidth <= gap
                    ? constraints.maxWidth
                    : (constraints.maxWidth - gap) / 2;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: <Widget>[
                    for (final Widget chip in chips)
                      SizedBox(width: cell, child: chip),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: RfiFilterClearButton(
            onPressed: enabled ? onClear : null,
          ),
        ),
      ],
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required String? value,
    required List<RfiFilterOption> options,
    required String? selectedId,
    required VoidCallback? onClear,
    required ValueChanged<RfiFilterOption> onPick,
  }) {
    final AppPalette palette = AppPalette.of(context);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? const Color(0xFF122844) : AppTheme.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: palette.borderSubtle),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pick(context, label, options, selectedId, onPick),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 2, 6),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      value ?? 'Select',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: 'Clear $label',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 16),
                ),
              const Icon(Icons.arrow_drop_down_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    String title,
    List<RfiFilterOption> options,
    String? selectedId,
    ValueChanged<RfiFilterOption> onPick,
  ) async {
    final RfiFilterOption? picked = await showModalBottomSheet<RfiFilterOption>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final double maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.6;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: options.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No options'),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(
                          title,
                          style: Theme.of(sheetContext).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      for (final RfiFilterOption option in options)
                        ListTile(
                          title: Text(option.label),
                          trailing: option.id == selectedId
                              ? const Icon(Icons.check_rounded)
                              : null,
                          onTap: () => Navigator.pop(sheetContext, option),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
    if (picked != null) {
      onPick(picked);
    }
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
