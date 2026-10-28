class ContractorRow {
  const ContractorRow({
    required this.contractorId,
    required this.contractorName,
    required this.specialization,
    required this.address,
    required this.primaryContact,
    required this.phoneNumber,
    required this.email,
    required this.panNumber,
    required this.gstNumber,
    required this.bankName,
    required this.accountNo,
    required this.ifscCode,
    required this.bankAddress,
    required this.remarks,
    required this.contractorShortCode,
    this.searchStr,
  });

  final String contractorId;
  final String contractorName;

  /// Display / domain name. Serialized to API as `specilaization` (backend typo).
  final String specialization;
  final String address;
  final String primaryContact;
  final String phoneNumber;
  final String email;
  final String panNumber;
  final String gstNumber;
  final String bankName;
  final String accountNo;
  final String ifscCode;
  final String bankAddress;
  final String remarks;
  final String contractorShortCode;
  final String? searchStr;
}

class ContractorListQuery {
  const ContractorListQuery({this.search = ''});

  final String search;

  ContractorListQuery copyWith({String? search}) {
    return ContractorListQuery(search: search ?? this.search);
  }
}

class ContractorListSnapshot {
  const ContractorListSnapshot({this.rows = const <ContractorRow>[]});

  static const ContractorListSnapshot empty = ContractorListSnapshot();

  final List<ContractorRow> rows;
}

/// Headers match web `Contractors_List.xlsx` (including backend typo column).
const List<String> contractorExportHeaders = <String>[
  'contractorId',
  'contractorName',
  'specilaization',
  'address',
  'primaryContact',
  'phoneNumber',
  'email',
  'panNumber',
  'gstNumber',
  'bankName',
  'accountNo',
  'ifscCode',
  'bankAddress',
  'remarks',
  'contractorShortCode',
  'searchStr',
];

List<String> contractorExportCells(ContractorRow row) {
  return <String>[
    row.contractorId,
    row.contractorName,
    row.specialization,
    row.address,
    row.primaryContact,
    row.phoneNumber,
    row.email,
    row.panNumber,
    row.gstNumber,
    row.bankName,
    row.accountNo,
    row.ifscCode,
    row.bankAddress,
    row.remarks,
    row.contractorShortCode,
    row.searchStr ?? '',
  ];
}

bool contractorRowMatches(ContractorRow row, ContractorListQuery query) {
  final String search = query.search.trim().toLowerCase();
  if (search.isEmpty) {
    return true;
  }
  final List<String> haystack = <String>[
    row.contractorId,
    row.contractorName,
    row.specialization,
    row.address,
    row.primaryContact,
    row.phoneNumber,
    row.email,
    row.panNumber,
    row.gstNumber,
    row.bankName,
    row.accountNo,
    row.ifscCode,
    row.bankAddress,
    row.remarks,
    row.contractorShortCode,
  ];
  for (final String value in haystack) {
    if (value.toLowerCase().contains(search)) {
      return true;
    }
  }
  return false;
}
