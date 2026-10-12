import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_reference.dart';

void main() {
  test('parses enclosure, checklist, description, and a duplicate save', () {
    const Map<String, dynamic> enclosure = <String, dynamic>{
      'id': 1,
      'encloserName': 'Blanketing',
      'action': 'Open',
      'rfiCategory': 'WORK',
      'usedInRfiDescription': false,
    };

    final List<RfiEnclosure> one = parseRfiEnclosures(enclosure);
    final List<RfiEnclosure> listed = parseRfiEnclosures(<dynamic>[enclosure]);

    expect(one, hasLength(1));
    expect(listed, hasLength(1));
    expect(one.single.id, 1);
    expect(one.single.encloserName, 'Blanketing');
    expect(one.single.action, 'Open');
    expect(one.single.actionLabel, 'Open');
    expect(one.single.rfiCategory, 'WORK');
    expect(one.single.categoryLabel, 'Work');
    expect(one.single.usedInRfiDescription, isFalse);
    expect(rfiReferenceCategoryLabel('MATERIAL'), 'Material');
    expect(rfiReferenceCategoryLabel('QUALITY/SAFETY'), 'Quality/Safety');
    expect(rfiReferenceCategoryWire('Quality/Safety'), 'Quality/Safety');
    expect(RfiReferenceCategory.quality, 'Quality/Safety');
    expect(RfiReferenceCategory.work, 'WORK');
    expect(RfiReferenceCategory.material, 'MATERIAL');

    final List<RfiChecklistDescription> checklist =
        parseRfiChecklistDescriptions(<String, dynamic>{
          'id': 19,
          'checklistDescription': 'abc testing',
          'canBeDeleted': true,
        });

    expect(checklist, hasLength(1));
    expect(checklist.single.id, 19);
    expect(checklist.single.checklistDescription, 'abc testing');
    expect(checklist.single.canBeDeleted, isTrue);

    final List<RfiReferenceDescription> descriptions =
        parseRfiDescriptions(<String, dynamic>{
          'id': 1,
          'activity': 'Blanketing',
          'rfiDescription': 'Blanketings',
          'enclosureIds': '4,44,34',
          'enclosures': 'Blanketing, Cement Work, Blanketing',
          'rfiCategory': 'WORK',
          'canDelete': false,
        });

    expect(descriptions, hasLength(1));
    expect(descriptions.single.activity, 'Blanketing');
    expect(descriptions.single.rfiDescription, 'Blanketings');
    expect(descriptions.single.enclosureIds, '4,44,34');
    expect(descriptions.single.enclosureIdList, <String>['4', '44', '34']);
    expect(
      descriptions.single.enclosures,
      'Blanketing, Cement Work, Blanketing',
    );
    expect(descriptions.single.categoryLabel, 'Work');
    expect(descriptions.single.canDelete, isFalse);
    expect(rfiReferenceJoinIds(descriptions.single.enclosureIdList), '4,44,34');

    final RfiChecklistSaveResult save = parseRfiChecklistSave(<String, dynamic>{
      'saved': <String>['testing'],
      'duplicateChecklistDescriptions': <String>['test'],
    });

    expect(save.saved, <String>['testing']);
    expect(save.duplicateChecklistDescriptions, <String>['test']);
    expect(save.duplicateChecklistDescriptions, hasLength(1));

    expect(
      ApiConstants.rfiEnclosureListPath,
      '/api/v1/enclouser/enclosure_list',
    );
    expect(ApiConstants.rfiEnclosureSubmitPath, '/api/v1/enclouser/submit');
    expect(
      ApiConstants.rfiEnclosureUpdatePath(1),
      '/api/v1/enclouser/updateEnclosureName/1',
    );
    expect(
      ApiConstants.rfiEnclosureDeletePath(1),
      '/api/v1/enclouser/deleteEncloserName/1',
    );
    expect(
      ApiConstants.rfiChecklistDescriptionsPath(9),
      '/api/v1/enclouser/addChecklistDescriptions/9',
    );
    expect(
      ApiConstants.rfiChecklistUpdatePath(19),
      '/api/v1/enclouser/update/19',
    );
    expect(
      ApiConstants.rfiChecklistDeletePath(19),
      '/api/v1/enclouser/delete/19',
    );
    expect(ApiConstants.rfiDescriptionsPath, '/rfi/get-descriptions');
    expect(
      ApiConstants.rfiDescriptionUpdatePath(1),
      '/rfi/description-update/1',
    );
    expect(
      ApiConstants.rfiDescriptionDeletePath(1),
      '/rfi/delete-rfi-description/1',
    );
    expect(ApiConstants.rfiDescriptionSavePath, '/rfi/description-save');
    expect(ApiConstants.rfiEnclosureNamesPath, '/api/v1/enclouser/names');
    expect(
      rfiReferenceDescriptionPayload(
        rfiCategory: RfiReferenceCategory.material,
        activity: rfiReferenceActivityPayload(
          RfiReferenceCategory.material,
          'N/A',
        ),
        rfiDescription: 'dsd',
        enclosures: rfiReferenceJoinIds(<String>['10', '60']),
      ),
      <String, String>{
        'rfiCategory': 'MATERIAL',
        'activity': '',
        'rfiDescription': 'dsd',
        'enclosures': '10,60',
      },
    );
    expect(
      rfiReferenceActivityPayload(RfiReferenceCategory.quality, 'typed'),
      '',
    );
    expect(
      rfiReferenceActivityPayload(RfiReferenceCategory.work, ' sd '),
      'sd',
    );

    final List<RfiEnclosureNameOption> names = parseRfiEnclosureNames(<dynamic>[
      <String, dynamic>{'id': 10, 'encloserName': 'Cement'},
      <String, dynamic>{'id': 60, 'enclosureName': 'Level Sheet'},
      <String, dynamic>{'id': 4, 'name': 'Safety'},
      'Plain',
    ]);
    expect(names, hasLength(4));
    expect(names[0].id, '10');
    expect(names[0].label, 'Cement');
    expect(names[1].id, '60');
    expect(names[1].label, 'Level Sheet');
    expect(names[2].id, '4');
    expect(names[2].label, 'Safety');
    expect(names[3].id, 'Plain');
    expect(names[3].label, 'Plain');
  });
}
