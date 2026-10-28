import 'package:swr_pmis_mobile/src/features/contractors/domain/contractor_list.dart';

const int contractorShortCodeMaxLength = 5;
const int contractorAddressMaxLength = 200;

final RegExp contractorPanPattern = RegExp(
  r'^[A-Z]{5}[0-9]{4}[A-Z]$',
);

final RegExp contractorTenDigitPattern = RegExp(r'^\d{10}$');

class ContractorFormDraft {
  const ContractorFormDraft({
    this.contractorId = '',
    this.panNumber = '',
    this.specialization = '',
    this.contractorName = '',
    this.contractorShortCode = '',
    this.address = '',
    this.primaryContact = '',
    this.phoneNumber = '',
    this.email = '',
    this.gstNumber = '',
    this.bankName = '',
    this.ifscCode = '',
    this.accountNo = '',
    this.bankAddress = '',
    this.remarks = '',
    this.searchStr,
  });

  factory ContractorFormDraft.fromRow(ContractorRow row) {
    return ContractorFormDraft(
      contractorId: row.contractorId,
      panNumber: row.panNumber,
      specialization: row.specialization,
      contractorName: row.contractorName,
      contractorShortCode: row.contractorShortCode,
      address: row.address,
      primaryContact: row.primaryContact,
      phoneNumber: row.phoneNumber,
      email: row.email,
      gstNumber: row.gstNumber,
      bankName: row.bankName,
      ifscCode: row.ifscCode,
      accountNo: row.accountNo,
      bankAddress: row.bankAddress,
      remarks: row.remarks,
      searchStr: row.searchStr,
    );
  }

  final String contractorId;
  final String panNumber;
  final String specialization;
  final String contractorName;
  final String contractorShortCode;
  final String address;
  final String primaryContact;
  final String phoneNumber;
  final String email;
  final String gstNumber;
  final String bankName;
  final String ifscCode;
  final String accountNo;
  final String bankAddress;
  final String remarks;
  final String? searchStr;

  bool get isEditing => contractorId.trim().isNotEmpty;
}

class ContractorFormValidation {
  const ContractorFormValidation({
    this.panError,
    this.specializationError,
    this.nameError,
    this.shortCodeError,
    this.addressError,
    this.primaryContactError,
    this.phoneError,
    this.emailError,
  });

  final String? panError;
  final String? specializationError;
  final String? nameError;
  final String? shortCodeError;
  final String? addressError;
  final String? primaryContactError;
  final String? phoneError;
  final String? emailError;

  bool get hasErrors =>
      panError != null ||
      specializationError != null ||
      nameError != null ||
      shortCodeError != null ||
      addressError != null ||
      primaryContactError != null ||
      phoneError != null ||
      emailError != null;

  bool get hasBasicErrors =>
      panError != null ||
      specializationError != null ||
      nameError != null ||
      shortCodeError != null ||
      addressError != null;

  bool get hasContactErrors =>
      primaryContactError != null || phoneError != null || emailError != null;
}

ContractorFormValidation validateContractorForm({
  required String panNumber,
  required String specialization,
  required String contractorName,
  required String contractorShortCode,
  required String address,
  required String primaryContact,
  required String phoneNumber,
  required String email,
  bool requireBasic = true,
  bool requireContact = true,
}) {
  String? panError;
  String? specializationError;
  String? nameError;
  String? shortCodeError;
  String? addressError;
  String? primaryContactError;
  String? phoneError;
  String? emailError;

  if (requireBasic) {
    final String pan = panNumber.trim().toUpperCase();
    if (pan.isEmpty) {
      panError = 'PAN Number is required';
    } else if (!contractorPanPattern.hasMatch(pan)) {
      panError = 'Invalid PAN format (e.g., ABCDE1234F)';
    }

    if (specialization.trim().isEmpty) {
      specializationError = 'Specialization is required';
    }

    if (contractorName.trim().isEmpty) {
      nameError = 'Contractor Name is required';
    }

    final String shortCode = contractorShortCode.trim();
    if (shortCode.isEmpty) {
      shortCodeError = 'Contractor Short Code is required';
    } else if (shortCode.length > contractorShortCodeMaxLength) {
      shortCodeError = 'Max $contractorShortCodeMaxLength characters';
    }

    if (address.trim().length > contractorAddressMaxLength) {
      addressError = 'Max $contractorAddressMaxLength characters';
    }
  }

  if (requireContact) {
    final String primary = primaryContact.trim();
    if (primary.isNotEmpty && !contractorTenDigitPattern.hasMatch(primary)) {
      primaryContactError = 'Must be 10 digits';
    }

    final String phone = phoneNumber.trim();
    if (phone.isNotEmpty && !contractorTenDigitPattern.hasMatch(phone)) {
      phoneError = 'Must be 10 digits';
    }

    final String mail = email.trim();
    if (mail.isNotEmpty && !_looksLikeEmail(mail)) {
      emailError = 'Enter a valid email';
    }
  }

  return ContractorFormValidation(
    panError: panError,
    specializationError: specializationError,
    nameError: nameError,
    shortCodeError: shortCodeError,
    addressError: addressError,
    primaryContactError: primaryContactError,
    phoneError: phoneError,
    emailError: emailError,
  );
}

Map<String, dynamic> buildContractorPayload({
  required String contractorName,
  required String contractorShortCode,
  required String panNumber,
  required String specialization,
  required String address,
  required String primaryContact,
  required String phoneNumber,
  required String email,
  required String gstNumber,
  required String bankName,
  required String accountNo,
  required String ifscCode,
  required String bankAddress,
  required String remarks,
  String? searchStr,
  bool includeSearchStr = true,
}) {
  final Map<String, dynamic> body = <String, dynamic>{
    'contractorName': contractorName.trim(),
    'contractorShortCode': contractorShortCode.trim(),
    'panNumber': panNumber.trim().toUpperCase(),
    // Backend field name is misspelled; keep as-is for API compatibility.
    'specilaization': specialization.trim(),
    'address': address.trim(),
    'primaryContact': primaryContact.trim(),
    'phoneNumber': phoneNumber.trim(),
    'email': email.trim(),
    'gstNumber': gstNumber.trim(),
    'bankName': bankName.trim(),
    'accountNo': accountNo.trim(),
    'ifscCode': ifscCode.trim(),
    'bankAddress': bankAddress.trim(),
    'remarks': remarks.trim(),
  };
  if (includeSearchStr) {
    body['searchStr'] = searchStr;
  }
  return body;
}

bool _looksLikeEmail(String value) {
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
}
