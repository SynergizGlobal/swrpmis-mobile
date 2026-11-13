import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_inspection_flow_provider.dart';

void main() {
  group('inspection dropdown options always contain the selected value', () {
    test('a Work RFI saved with "Nos" no longer crashes Step 2', () {
      final List<String> units = rfiInspectionUnitOptions('Number', 'Nos');
      expect(units.where((String u) => u == 'Nos'), hasLength(1));
    });

    test('units follow the Work RFI form for each type', () {
      expect(rfiInspectionUnitOptions('Area', 'Select U'), <String>[
        'Select U',
        'cm²',
        'm²',
      ]);
      expect(rfiInspectionUnitOptions('Weight', 'MT'), contains('MT'));
      expect(rfiInspectionUnitOptions('Percent', '%'), <String>[
        'Select U',
        '%',
      ]);
    });

    test('an unknown saved unit or type is kept once', () {
      expect(rfiInspectionUnitOptions('Number', 'nos'), contains('nos'));
      expect(
        rfiInspectionUnitOptions(
          'Number',
          'Select U',
        ).where((String u) => u == 'Select U'),
        hasLength(1),
      );
      expect(rfiInspectionTypeOptions('Cubic'), contains('Cubic'));
      expect(
        rfiInspectionTypeOptions('Area').where((String t) => t == 'Area'),
        hasLength(1),
      );
    });

    test('Tests in Site/Lab keeps an unexpected server value', () {
      expect(rfiInspectionTestOptions('NDT'), contains('NDT'));
      expect(rfiInspectionTestOptions('Visual'), hasLength(3));
    });
  });
}
