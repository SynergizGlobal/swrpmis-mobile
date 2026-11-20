import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';

/// Shell for Reports → Contracts → Insurance Contractual Letters.
///
/// TODO: Wire search API when known. No remote call yet — empty table only.
class InsuranceContractualLettersPage extends StatefulWidget {
  const InsuranceContractualLettersPage({
    super.key,
    this.title = 'List of Contracts Closer to Insurance Expiry Date',
  });

  static const String routeName = 'insurance-contractual-letters';
  static const String routePath = '/reports/insurance-contractual-letters';

  final String title;

  @override
  State<InsuranceContractualLettersPage> createState() =>
      _InsuranceContractualLettersPageState();
}

class _InsuranceContractualLettersPageState
    extends State<InsuranceContractualLettersPage> {
  final TextEditingController _filterController = TextEditingController();

  static const List<String> _columns = <String>[
    'S.No',
    'Contract ID',
    'Contract Short Name',
    'Contractor Name',
    'Insurance Type',
    'Insurance No.',
    'No. of Insurances',
    'Expiry Month',
    'Status',
  ];

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String heading = widget.title.trim().isEmpty
        ? 'List of Contracts Closer to Insurance Expiry Date'
        : widget.title.trim();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/reports');
            }
          },
        ),
        title: Text(heading),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: <Widget>[
          Material(
            color: palette.cardSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              side: BorderSide(color: palette.borderSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      heading,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _filterController,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: palette.fieldFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.cardRadius,
                        ),
                        borderSide: BorderSide(color: palette.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.cardRadius,
                        ),
                        borderSide: BorderSide(color: palette.borderSubtle),
                      ),
                    ),
                    // Client-side only; no rows until search API is wired.
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: palette.cardSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              side: BorderSide(color: palette.borderSubtle),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStatePropertyAll(
                      colors.primary.withValues(alpha: 0.12),
                    ),
                    columns: <DataColumn>[
                      for (final String label in _columns)
                        DataColumn(label: Text(label)),
                    ],
                    rows: const <DataRow>[],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 16,
                  ),
                  child: Text(
                    'No data available in table',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: palette.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
