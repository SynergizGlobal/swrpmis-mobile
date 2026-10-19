import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_checklist_item.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_access.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_details.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_uploaded_by.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_user_role.dart';

void main() {
  test('inspection-access parses hasAccess and message', () {
    final RfiInspectionAccess access = RfiInspectionAccess.fromJson(
      <String, dynamic>{
        'permissionType': 'START',
        'message': 'Allowed',
        'accessType': 'FULL',
        'hasAccess': true,
      },
    );

    expect(access.hasAccess, isTrue);
    expect(access.message, 'Allowed');
    expect(access.permissionType, 'START');
    expect(access.accessType, 'FULL');
  });

  test('checkUserSignature parses exists from string', () {
    final RfiUserSignature signature = RfiUserSignature.fromJson(
      <String, dynamic>{'exists': 'true'},
    );
    expect(signature.exists, isTrue);

    final RfiUserSignature missing = RfiUserSignature.fromJson(
      <String, dynamic>{'exists': false},
    );
    expect(missing.exists, isFalse);
  });

  test('rfi-details nested payload parses rfi, enclosures, measurements', () {
    final RfiInspectionDetails details = RfiInspectionDetails.fromJson(
      <String, dynamic>{
        'rfi': <String, dynamic>{
          'id': 47,
          'rfi_Id': 'RFI_QA_RUB_45260_BSLAB_BSLAB_CONC_0001',
          'project': '4th Line between Itarsi - Bhopal - Bina',
          'contract': 'New Broad gauge line',
          'structureType': 'Minor Bridge',
          'structure': '25 RCC Box',
          'description': 'TEsting',
          'rfiDescription': 'Formation - Embankment',
          'rfiCategory': 'QUALITY_OR_SAFETY',
          'dateOfInspection': '19/10/2026',
          'timeOfInspection': '10:23 PM',
          'nameOfRepresentative': 'Nihal',
          'chainage': '',
          'conLocation': 'Allagadda Town',
          'inspectionMode': 'ONLINE',
          'testInSiteOrLab': 'VISUAL',
          'conSiteImgs': <String>['a.jpg'],
          'enggSiteImgs': <dynamic>[],
          'conSupDocs': <Map<String, dynamic>>[
            <String, dynamic>{
              'path': '/docs/one.pdf',
              'description': 'Note',
            },
          ],
          'conInspectionId': '56',
        },
        'enclosures': <Map<String, dynamic>>[
          <String, dynamic>{
            'action': 'Upload',
            'encloserName': 'Blanketing',
            'rfiDescription': 'Formation - Embankment',
            'rfiId': 47,
            'enclosureId': 26,
            'rfiDescriptionId': 3,
            'enclosureUploadedFileId': null,
            'enclosureUploadedFile': null,
          },
          <String, dynamic>{
            'action': 'Open,Upload',
            'encloserName': 'Quality',
            'rfiDescription': 'Formation - Embankment',
            'rfiId': '47',
            'enclosureId': '27',
            'rfiDescriptionId': '3',
            'enclosureUploadedFileId': 99,
            'enclosureUploadedFile': '/files/quality.pdf',
          },
        ],
        'measurements': <Map<String, dynamic>>[
          <String, dynamic>{
            'activityName': 'Embankment',
            'measurementType': 'Area',
            'units': 'sqm',
            'length': '10',
            'breadth': '2',
            'height': null,
            'weight': '',
            'noOfItems': '1',
            'totalQty': '20',
          },
        ],
      },
    );

    expect(details.rfi.id, 47);
    expect(details.rfi.rfiId, 'RFI_QA_RUB_45260_BSLAB_BSLAB_CONC_0001');
    expect(details.rfi.location, 'Allagadda Town');
    expect(details.rfi.conInspectionId, 56);
    expect(details.rfi.conSiteImgs, <String>['a.jpg']);
    expect(details.rfi.conSupDocs.single.description, 'Note');
    expect(details.enclosures, hasLength(2));
    expect(details.enclosures.first.enclosureName, 'Blanketing');
    expect(details.enclosures.first.hasUploadAction, isTrue);
    expect(details.enclosures.first.hasOpenAction, isFalse);
    expect(details.enclosures.last.hasOpenAction, isTrue);
    expect(details.enclosures.last.hasUploadedFile, isTrue);
    expect(details.enclosures.last.enclosureId, 27);
    expect(details.measurements.single.totalQty, 20);
    expect(details.measurements.single.measurementType, 'Area');
  });

  test('checklist-items parse statuses and grade defensively', () {
    final List<RfiChecklistItem> items = parseRfiChecklistItems(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'checklistDescId': '250',
          'checklistDescription':
              'Whether approval for competent authority has been obtained?',
          'contractorStatus': 'NO',
          'engineerStatus': '',
          'contractorRemark': 'Testing',
          'aeRemark': '',
          'gradeOfConcrete': '550',
          'enclosureName': 'Quality',
        },
      ],
    );

    expect(items, hasLength(1));
    expect(items.single.checklistDescId, 250);
    expect(items.single.contractorStatus, 'NO');
    expect(items.single.contractorRemarks, 'Testing');
    expect(items.single.gradeOfConcrete, '550');
    expect(items.single.toSaveRowJson()['checklistDescriptionId'], 250);
    expect(items.single.toSaveRowJson()['aeRemark'], '');
  });

  test('uploadedBy mapping matches contractor CON and engineer AE/engg', () {
    expect(
      rfiInspectionUploadedBy(RfiUserRole.contractorRep),
      'CON',
    );
    expect(rfiInspectionUploadedBy(RfiUserRole.engineer), 'AE');
    expect(rfiChecklistUploadedBy(RfiUserRole.contractor), 'CON');
    expect(rfiChecklistUploadedBy(RfiUserRole.dyHodEngineer), 'engg');
  });

  test('api constants cover inspection flow paths', () {
    expect(ApiConstants.rfiInspectionAccessPath, '/inspection-access');
    expect(ApiConstants.checkUserSignaturePath, '/api/checkUserSignature');
    expect(ApiConstants.rfiDetailsByIdPath(47), '/rfi/rfi-details/47');
    expect(ApiConstants.rfiSaveDraftPath, '/rfi/saveDraft');
    expect(
      ApiConstants.rfiUploadSiteImagePath,
      '/rfi/inspection/uploadSiteImage',
    );
    expect(ApiConstants.rfiUploadEnclosurePath, '/rfi/upload');
    expect(ApiConstants.rfiSaveChecklistPath, '/rfi/saveChecklist');
    expect(
      ApiConstants.rfiChecklistItemsPath,
      '/api/v1/enclouser/checklist-items',
    );
    expect(ApiConstants.rfiFinalSubmitPath, '/rfi/finalSubmit');
  });
}
