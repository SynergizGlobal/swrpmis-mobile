import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';

void main() {
  test('detects Contract Detail report menu item', () {
    expect(
      isContractDetailReport(
        formId: '282',
        formName: 'Contract Detail',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isContractDetailReport(
        formId: '999',
        formName: 'List of Contracts',
        webFormUrl: '',
      ),
      isFalse,
    );
  });

  test('parses filter option payloads', () {
    final List<ContractDetailOption> projects = parseContractDetailProjects(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'project_id': 'P01',
          'project_name': 'Bengaluru Railway Projects',
        },
        <String, dynamic>{
          'project_id': 'P09',
          'project_name': 'Hubballi—Chikjajur Doubling Project',
        },
      ],
    );
    expect(projects, hasLength(2));
    expect(projects.first.label, 'Bengaluru Railway Projects');

    final List<ContractDetailOption> contracts = parseContractDetailContracts(
      <String, dynamic>{
        'contract_id': 'P01CN01',
        'contract_name': 'dum',
        'contract_short_name': '4567876',
      },
    );
    expect(contracts.single.id, 'P01CN01');
    expect(contracts.single.label, '4567876');

    final List<ContractDetailOption> contractors =
        parseContractDetailContractors(<String, dynamic>{
          'contractor_id_fk': 'CON0001',
          'contractor_name': 'M/s GIRIRAJ CIVIL DEVELOPERS LIMITED - MUMBAI',
          'contractor_id': 'CON0001',
        });
    expect(contractors.single.id, 'CON0001');

    final List<ContractDetailOption> hods = parseContractDetailHods(
      <String, dynamic>{
        'hod_user_id_fk': 'PMIS_RU_063',
        'designation': 'CE/CN/II/BNC',
        'user_name': 'Mukesh Kumar',
        'user_id': 'PMIS_RU_063',
      },
    );
    expect(hods.single.id, 'CE/CN/II/BNC');
    expect(hods.single.label, contains('Mukesh Kumar'));

    final List<ContractDetailOption> statuses = parseContractDetailStatuses(
      <String, dynamic>{'contract_status_fk': 'Not Awarded'},
    );
    expect(statuses.single.id, 'Not Awarded');
  });
}
