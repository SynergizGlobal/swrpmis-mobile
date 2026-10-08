import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_row.dart';

class RfiInspectionCatalog {
  const RfiInspectionCatalog({
    this.categories = const <RfiFilterOption>[],
    this.projects = const <RfiFilterOption>[],
    this.contracts = const <RfiFilterOption>[],
    this.structureTypes = const <RfiFilterOption>[],
    this.structures = const <RfiFilterOption>[],
    this.items = const <RfiFilterOption>[],
    this.materials = const <RfiFilterOption>[],
    this.qualitySafety = const <RfiFilterOption>[],
    this.rows = const <RfiInspectionRow>[],
  });

  final List<RfiFilterOption> categories;
  final List<RfiFilterOption> projects;
  final List<RfiFilterOption> contracts;
  final List<RfiFilterOption> structureTypes;
  final List<RfiFilterOption> structures;
  final List<RfiFilterOption> items;
  final List<RfiFilterOption> materials;
  final List<RfiFilterOption> qualitySafety;
  final List<RfiInspectionRow> rows;

  RfiInspectionCatalog copyWithRows(List<RfiInspectionRow> rows) {
    return RfiInspectionCatalog(
      categories: categories,
      projects: projects,
      contracts: contracts,
      structureTypes: structureTypes,
      structures: structures,
      items: items,
      materials: materials,
      qualitySafety: qualitySafety,
      rows: rows,
    );
  }
}
