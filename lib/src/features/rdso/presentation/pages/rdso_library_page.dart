import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/features/rdso/presentation/widgets/rdso_library_list_view.dart';

class RdsoLibraryPage extends StatelessWidget {
  const RdsoLibraryPage({super.key});

  static const String routeName = 'more-rdso';
  static const String routePath = '/module/rdso';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RDSO Digital Library')),
      body: const RdsoLibraryListView(),
    );
  }
}
