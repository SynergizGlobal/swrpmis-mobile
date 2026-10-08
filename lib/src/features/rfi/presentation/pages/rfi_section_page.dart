import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_list_kind.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_menu.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_list_view.dart';

class RfiSectionPage extends StatelessWidget {
  const RfiSectionPage({super.key, required this.section});

  static const String routeName = 'rfi-section';
  static const String routePath = '/rfi/section/:section';

  final String section;

  @override
  Widget build(BuildContext context) {
    final RfiMenuItem? item = RfiMenuItem.byId(section);
    final RfiListKind? listKind = RfiListKind.fromMenuId(item?.id);
    if (listKind != null) {
      return Scaffold(
        appBar: AppBar(title: Text(listKind.title)),
        body: RfiListView(kind: listKind),
      );
    }
    final String title = item?.title ?? 'RFI';
    final String message = switch (item?.id) {
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
      null => 'This RFI section is not available.',
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
