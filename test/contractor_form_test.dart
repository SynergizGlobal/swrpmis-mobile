import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/forms/form_menu_tree.dart';
import 'package:swr_pmis_mobile/src/features/contractors/domain/contractor_form.dart';
import 'package:swr_pmis_mobile/src/features/contractors/domain/contractor_list.dart';
import 'package:swr_pmis_mobile/src/features/contractors/domain/contractor_parse.dart';
import 'package:swr_pmis_mobile/src/features/contractors/presentation/pages/contractors_page.dart';
import 'package:swr_pmis_mobile/src/features/update_forms/domain/update_form_destination.dart';

void main() {
  test('parses contractor list preserving backend specialization typo', () {
    final List<ContractorRow> rows = parseContractorRows(<Map<String, dynamic>>[
      <String, dynamic>{
        'contractorId': 'CON0021',
        'contractorName': 'MANI Real Estate',
        'specilaization': 'Construction HQ',
        'panNumber': 'ABCDE1234F',
        'contractorShortCode': 'MANI',
        'address': '',
        'primaryContact': '',
        'phoneNumber': '',
        'email': '',
        'gstNumber': '',
        'bankName': '',
        'accountNo': '',
        'ifscCode': '',
        'bankAddress': '',
        'remarks': '',
        'searchStr': null,
      },
    ]);
    expect(rows, hasLength(1));
    expect(rows.single.contractorId, 'CON0021');
    expect(rows.single.specialization, 'Construction HQ');
    expect(rows.single.panNumber, 'ABCDE1234F');
  });

  test('validates PAN and 10-digit primary contact', () {
    final ContractorFormValidation invalid = validateContractorForm(
      panNumber: '123XXX|',
      specialization: 'Construction HQ',
      contractorName: 'Test',
      contractorShortCode: 'TST',
      address: '',
      primaryContact: '1231231',
      phoneNumber: '',
      email: '',
    );
    expect(invalid.panError, 'Invalid PAN format (e.g., ABCDE1234F)');
    expect(invalid.primaryContactError, 'Must be 10 digits');

    final ContractorFormValidation valid = validateContractorForm(
      panNumber: 'abcde1234f',
      specialization: 'Construction HQ',
      contractorName: 'Test',
      contractorShortCode: 'TST',
      address: 'ok',
      primaryContact: '9876543210',
      phoneNumber: '',
      email: 'a@b.com',
    );
    expect(valid.hasErrors, isFalse);
  });

  test('payload keeps specilaization key and uppercases PAN', () {
    final Map<String, dynamic> body = buildContractorPayload(
      contractorName: 'accc',
      contractorShortCode: 'WWE3',
      panNumber: 'abcde1234f',
      specialization: 'Construction HQ',
      address: 'test',
      primaryContact: '1231233333',
      phoneNumber: '1234567890',
      email: 'saltafhussain786@gmail.com',
      gstNumber: '29ABCDE1234F1Z5',
      bankName: 'safsdc',
      accountNo: 'cverf44',
      ifscCode: 'sdv434',
      bankAddress: 'acc',
      remarks: 'qwerty',
      includeSearchStr: false,
    );
    expect(body['panNumber'], 'ABCDE1234F');
    expect(body['specilaization'], 'Construction HQ');
    expect(body.containsKey('specialization'), isFalse);
    expect(body.containsKey('searchStr'), isFalse);
  });

  test('update forms leaf contractor routes to contractors module', () {
    const FormMenuNode leaf = FormMenuNode(
      formId: '32',
      formName: 'Contractor',
      webFormUrl: 'contractor',
      mobileFormUrl: '',
      priority: 2,
      children: <FormMenuNode>[],
    );
    expect(updateFormRouteName(leaf), ContractorsPage.routeName);
  });

  test('search matches across contractor fields', () {
    const ContractorRow row = ContractorRow(
      contractorId: 'CON0022',
      contractorName: 'Reddy Real Estate',
      specialization: 'Construction Site Office',
      address: 'Jubilee Hills',
      primaryContact: '9876543210',
      phoneNumber: '',
      email: '',
      panNumber: 'ABCDE1234G',
      gstNumber: '',
      bankName: '',
      accountNo: '',
      ifscCode: '',
      bankAddress: '',
      remarks: '',
      contractorShortCode: 'REDDY',
    );
    expect(
      contractorRowMatches(row, const ContractorListQuery(search: 'jubilee')),
      isTrue,
    );
    expect(
      contractorRowMatches(row, const ContractorListQuery(search: 'zzz')),
      isFalse,
    );
  });
}
