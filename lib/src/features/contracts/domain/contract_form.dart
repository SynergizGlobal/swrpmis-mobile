class ContractFormOption {
  const ContractFormOption({
    required this.id,
    required this.label,
    this.meta = '',
  });

  final String id;
  final String label;
  final String meta;
}

class ContractFormMaster {
  const ContractFormMaster({
    this.projects = const <ContractFormOption>[],
    this.departments = const <ContractFormOption>[],
    this.hods = const <ContractFormOption>[],
    this.dyHods = const <ContractFormOption>[],
    this.units = const <ContractFormOption>[],
    this.responsiblePeople = const <ContractFormOption>[],
    this.contractors = const <ContractFormOption>[],
    this.contractStatuses = const <ContractFormOption>[],
    this.contractTypes = const <ContractFormOption>[],
    this.workStatuses = const <ContractFormOption>[],
    this.banks = const <ContractFormOption>[],
    this.reviewTypes = const <ContractFormOption>[],
    this.bgTypes = const <ContractFormOption>[],
    this.insuranceTypes = const <ContractFormOption>[],
    this.fileTypes = const <ContractFormOption>[],
    this.executivesByDepartment = const <String, List<ContractFormOption>>{},
  });

  static const ContractFormMaster empty = ContractFormMaster();

  final List<ContractFormOption> projects;
  final List<ContractFormOption> departments;
  final List<ContractFormOption> hods;
  final List<ContractFormOption> dyHods;
  final List<ContractFormOption> units;
  final List<ContractFormOption> responsiblePeople;
  final List<ContractFormOption> contractors;
  final List<ContractFormOption> contractStatuses;
  final List<ContractFormOption> contractTypes;
  final List<ContractFormOption> workStatuses;
  final List<ContractFormOption> banks;
  final List<ContractFormOption> reviewTypes;
  final List<ContractFormOption> bgTypes;
  final List<ContractFormOption> insuranceTypes;
  final List<ContractFormOption> fileTypes;
  final Map<String, List<ContractFormOption>> executivesByDepartment;
}

/// Wizard steps mirror web Add/Update Contract modules.
enum AddContractStep {
  managers,
  executives,
  details,
  closure,
  bankGuarantee,
  insurance,
  milestone,
  keyPersonnel,
  documents,
}

extension AddContractStepX on AddContractStep {
  String get title => switch (this) {
    AddContractStep.managers => 'Contract Managers',
    AddContractStep.executives => 'Executives',
    AddContractStep.details => 'Contract Details',
    AddContractStep.closure => 'Contract Closure',
    AddContractStep.bankGuarantee => 'Bank Guarantee',
    AddContractStep.insurance => 'Insurance',
    AddContractStep.milestone => 'Milestone',
    AddContractStep.keyPersonnel => 'Key Personnel',
    AddContractStep.documents => 'Documents',
  };

  String get shortTitle => switch (this) {
    AddContractStep.managers => 'Managers',
    AddContractStep.executives => 'Executives',
    AddContractStep.details => 'Details',
    AddContractStep.closure => 'Closure',
    AddContractStep.bankGuarantee => 'BG',
    AddContractStep.insurance => 'Insurance',
    AddContractStep.milestone => 'Milestone',
    AddContractStep.keyPersonnel => 'Personnel',
    AddContractStep.documents => 'Docs',
  };

  static const List<AddContractStep> all = AddContractStep.values;
}

DateTime? parseContractFormDate(String? raw) {
  final String text = (raw ?? '').trim();
  if (text.isEmpty) {
    return null;
  }
  final DateTime? iso = DateTime.tryParse(text);
  if (iso != null) {
    return DateTime(iso.year, iso.month, iso.day);
  }
  final List<String> parts = text.split(RegExp(r'[/-]'));
  if (parts.length == 3) {
    final int? a = int.tryParse(parts[0]);
    final int? b = int.tryParse(parts[1]);
    final int? c = int.tryParse(parts[2]);
    if (a != null && b != null && c != null) {
      if (parts[0].length == 4) {
        return DateTime(a, b, c);
      }
      if (parts[2].length == 4) {
        return DateTime(c, b, a);
      }
    }
  }
  return null;
}

String formatContractApiDate(DateTime? date) {
  if (date == null) {
    return '';
  }
  final String y = date.year.toString().padLeft(4, '0');
  final String m = date.month.toString().padLeft(2, '0');
  final String d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String formatContractDisplayDate(DateTime? date) {
  if (date == null) {
    return '';
  }
  final String d = date.day.toString().padLeft(2, '0');
  final String m = date.month.toString().padLeft(2, '0');
  final String y = date.year.toString().padLeft(4, '0');
  return '$d/$m/$y';
}

num? parseContractNumber(String? raw) {
  final String text = (raw ?? '').trim().replaceAll(',', '');
  if (text.isEmpty) {
    return null;
  }
  return num.tryParse(text);
}

const List<ContractFormOption> contractYesNoOptions = <ContractFormOption>[
  ContractFormOption(id: 'Yes', label: 'Yes'),
  ContractFormOption(id: 'No', label: 'No'),
];

const List<ContractFormOption> contractCostUnitOptions = <ContractFormOption>[
  ContractFormOption(id: 'Rupees', label: 'Rupees'),
  ContractFormOption(id: 'Thousand', label: 'Thousand'),
  ContractFormOption(id: 'Lakh', label: 'Lakh'),
  ContractFormOption(id: 'Crore', label: 'Crore'),
];
